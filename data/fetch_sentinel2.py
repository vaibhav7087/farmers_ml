"""
data/fetch_sentinel2.py — Fetch Sentinel-2 data from Planetary Computer STAC API.

FAIL-CLOSED: Missing credentials or API failure = hard error with instructions.

Requires: planetary-computer Python package, pystac-client, odc-stac, rasterio.
Output: Writes GeoTIFF/COG to local cache or R2 bucket.
"""
import os
import json
import logging
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional

import pystac_client
import planetary_computer
import odc.stac
import xarray as xr

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

STAC_API = "https://planetarycomputer.microsoft.com/api/stac/v1"
COLLECTION = "sentinel-2-l2a"
CACHE_DIR = Path(os.getenv("SENTINEL2_CACHE_DIR", "./data/cache/sentinel2"))
CACHE_DIR.mkdir(parents=True, exist_ok=True)

BANDS = ["B02", "B03", "B04", "B08", "B11", "SCL", "B05", "B06", "B07", "B8A"]


def get_district_bbox(district: str, state: str = "Maharashtra") -> list:
    """Get bounding box for district. In production, load from GeoJSON."""
    bboxes = {
        "yavatmal": [77.5, 19.5, 79.5, 21.0],
        "amravati": [77.0, 20.0, 78.5, 21.5],
        "akola": [76.5, 20.0, 77.5, 21.0],
        "wardha": [78.0, 20.0, 79.5, 21.0],
        "nagpur": [78.5, 20.5, 80.0, 22.0],
    }
    key = district.lower()
    if key not in bboxes:
        raise ValueError(f"Unknown district: {district}. Add bbox to bboxes dict.")
    return bboxes[key]


def search_scenes(
    bbox: list,
    start_date: str,
    end_date: str,
    max_cloud_cover: int = 30,
    limit: int = 20,
) -> list:
    """Search STAC API for Sentinel-2 scenes."""
    catalog = pystac_client.Client.open(STAC_API, modifier=planetary_computer.sign_inplace)
    search = catalog.search(
        collections=[COLLECTION],
        bbox=bbox,
        datetime=f"{start_date}/{end_date}",
        query={"eo:cloud_cover": {"lt": max_cloud_cover}},
        limit=limit,
    )
    items = list(search.items())
    logger.info(f"Found {len(items)} scenes for bbox={bbox}, dates={start_date} to {end_date}")
    if not items:
        raise RuntimeError(f"No Sentinel-2 scenes found for bbox={bbox}, dates={start_date}/{end_date}")
    return items


def load_scene_data(items: list, bands: list = None, resolution: int = 10) -> xr.Dataset:
    """Load selected bands from STAC items into xarray Dataset."""
    bands = bands or BANDS
    ds = odc.stac.load(
        items,
        bands=bands,
        resolution=resolution,
        groupby="solar_day",
        chunks={"x": 2048, "y": 2048},
    )
    return ds


def compute_indices(ds: xr.Dataset) -> xr.Dataset:
    """Compute NDVI, EVI, SAVI, NDWI from bands."""
    red = ds["B04"].astype("float32")
    nir = ds["B08"].astype("float32")
    blue = ds["B02"].astype("float32")
    swir = ds["B11"].astype("float32")
    green = ds["B03"].astype("float32")

    # NDVI
    ndvi = (nir - red) / (nir + red + 1e-10)
    ndvi = ndvi.where((ndvi >= -1) & (ndvi <= 1))
    ndvi.attrs = {"long_name": "NDVI", "units": "1"}

    # EVI
    evi = 2.5 * (nir - red) / (nir + 6 * red - 7.5 * blue + 1 + 1e-10)
    evi = evi.where((evi >= -1) & (evi <= 1))
    evi.attrs = {"long_name": "EVI", "units": "1"}

    # SAVI (L=0.5)
    savi = 1.5 * (nir - red) / (nir + red + 0.5 + 1e-10)
    savi.attrs = {"long_name": "SAVI", "units": "1"}

    # NDWI
    ndwi = (green - nir) / (green + nir + 1e-10)
    ndwi.attrs = {"long_name": "NDWI", "units": "1"}

    return xr.Dataset({
        "ndvi": ndvi,
        "evi": evi,
        "savi": savi,
        "ndwi": ndwi,
    })


def compute_cloud_mask(ds: xr.Dataset) -> xr.DataArray:
    """Compute cloud mask from SCL band."""
    scl = ds["SCL"]
    # Cloud classes: 3 (cloud shadow), 8 (cloud medium prob), 9 (cloud high prob), 10 (thin cirrus)
    cloud_classes = [3, 8, 9, 10]
    cloud_mask = scl.isin(cloud_classes)
    return cloud_mask


def process_district(
    district: str,
    state: str = "Maharashtra",
    start_date: str = None,
    end_date: str = None,
    output_dir: Path = None,
) -> dict:
    """Full pipeline: search, load, compute indices, save."""
    output_dir = output_dir or CACHE_DIR / district
    output_dir.mkdir(parents=True, exist_ok=True)

    start_date = start_date or (datetime.now() - timedelta(days=60)).strftime("%Y-%m-%d")
    end_date = end_date or datetime.now().strftime("%Y-%m-%d")

    bbox = get_district_bbox(district, state)
    items = search_scenes(bbox, start_date, end_date)

    ds = load_scene_data(items)
    indices = compute_indices(ds)
    cloud_mask = compute_cloud_mask(ds)

    # Add cloud mask to indices
    indices["cloud_mask"] = cloud_mask

    # Compute temporal composites (median over time, ignoring clouds)
    def cloud_free_median(da):
        return da.where(~cloud_mask).median(dim="time", skipna=True)

    composites = xr.Dataset({var: cloud_free_median(indices[var]) for var in indices.data_vars if var != "cloud_mask"})
    composites["cloud_fraction"] = cloud_mask.mean(dim="time")

    # Save to NetCDF
    output_path = output_dir / f"{district}_{start_date}_{end_date}_indices.nc"
    composites.to_netcdf(output_path)
    logger.info(f"Saved indices to {output_path}")

    # Also save as GeoTIFF for each index
    for var in composites.data_vars:
        if var != "cloud_fraction":
            tif_path = output_dir / f"{district}_{var}.tif"
            composites[var].rio.to_raster(tif_path, compress="LZW")
            logger.info(f"Saved {var} to {tif_path}")

    return {
        "district": district,
        "start_date": start_date,
        "end_date": end_date,
        "scenes_processed": len(items),
        "output_path": str(output_path),
        "indices": list(composites.data_vars),
    }


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Fetch and process Sentinel-2 data for district")
    parser.add_argument("--district", required=True, help="District name (e.g., yavatmal)")
    parser.add_argument("--state", default="Maharashtra", help="State name")
    parser.add_argument("--start-date", help="Start date YYYY-MM-DD (default: 60 days ago)")
    parser.add_argument("--end-date", help="End date YYYY-MM-DD (default: today)")
    parser.add_argument("--output-dir", help="Output directory")

    args = parser.parse_args()

    try:
        result = process_district(
            district=args.district,
            state=args.state,
            start_date=args.start_date,
            end_date=args.end_date,
            output_dir=Path(args.output_dir) if args.output_dir else None,
        )
        print(json.dumps(result, indent=2))
    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        raise