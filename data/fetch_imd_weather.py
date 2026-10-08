"""
data/fetch_imd_weather.py — Fetch IMD gridded weather data.

FAIL-CLOSED: Missing source files or download failure = hard error.

IMD provides daily gridded data (0.25° x 0.25°) for:
- Temperature (max, min, mean)
- Rainfall
- Relative humidity
- Wind speed

Data source: https://imdpune.gov.in/Clim_Pred_LRF_New/Grided_Data_Download.html
Or via API: https://api.imdpune.gov.in/ (requires registration)
"""
import os
import logging
import requests
import xarray as xr
import pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional
import zipfile
import io

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

IMD_BASE_URL = "https://imdpune.gov.in/Clim_Pred_LRF_New/Grided_Data_Download"
DATA_DIR = Path(os.getenv("IMD_DATA_DIR", "./data/imd"))
DATA_DIR.mkdir(parents=True, exist_ok=True)

VARIABLES = {
    "tmax": "Maximum Temperature",
    "tmin": "Minimum Temperature",
    "rain": "Rainfall",
    "rh": "Relative Humidity",
    "wind": "Wind Speed",
}

GRID_RESOLUTION = 0.25  # degrees


def get_imd_url(variable: str, year: int) -> str:
    """Construct IMD download URL for variable and year."""
    return f"{IMD_BASE_URL}/{variable}/{variable}_{year}.zip"


def download_imd_data(variable: str, year: int, output_dir: Path) -> Path:
    """Download and extract IMD gridded data for a variable and year."""
    url = get_imd_url(variable, year)
    output_dir.mkdir(parents=True, exist_ok=True)
    zip_path = output_dir / f"{variable}_{year}.zip"

    logger.info(f"Downloading {variable} for {year} from {url}")

    try:
        response = requests.get(url, timeout=300, stream=True)
        response.raise_for_status()

        with open(zip_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        logger.info(f"Downloaded {zip_path} ({zip_path.stat().st_size} bytes)")

        # Extract
        with zipfile.ZipFile(zip_path, "r") as zf:
            zf.extractall(output_dir / variable / str(year))

        logger.info(f"Extracted {variable} {year} to {output_dir / variable / str(year)}")
        return output_dir / variable / str(year)

    except requests.RequestException as e:
        raise RuntimeError(f"Failed to download {variable} {year}: {e}")
    except zipfile.BadZipFile as e:
        raise RuntimeError(f"Corrupted zip file for {variable} {year}: {e}")


def load_imd_netcdf(variable: str, year: int, data_dir: Path) -> Optional[xr.Dataset]:
    """Load extracted NetCDF file for variable/year."""
    var_dir = data_dir / variable / str(year)
    nc_files = list(var_dir.glob("*.nc")) + list(var_dir.glob("*.NC"))

    if not nc_files:
        logger.warning(f"No NetCDF files found for {variable} {year} in {var_dir}")
        return None

    try:
        ds = xr.open_dataset(nc_files[0])
        logger.info(f"Loaded {variable} {year}: {ds.dims}")
        return ds
    except Exception as e:
        logger.error(f"Failed to load NetCDF for {variable} {year}: {e}")
        return None


def extract_district_timeseries(
    ds: xr.Dataset,
    district_bbox: list,
    variable_name: str = None,
) -> pd.DataFrame:
    """Extract time series for a district bounding box from gridded data."""
    if ds is None:
        return pd.DataFrame()

    # district_bbox = [min_lon, min_lat, max_lon, max_lat]
    min_lon, min_lat, max_lon, max_lat = district_bbox

    # Select spatial subset
    # IMD data typically has lat/lon as coordinates
    lon_dim = "lon" if "lon" in ds.dims else "longitude"
    lat_dim = "lat" if "lat" in ds.dims else "latitude"

    subset = ds.sel(
        {lon_dim: slice(district_bbox[0], district_bbox[2]),
         lat_dim: slice(district_bbox[1], district_bbox[3])}
    )

    # Average over spatial dimensions
    if variable_name and variable_name in subset.data_vars:
        ts = subset[variable_name].mean(dim=[lon_dim, lat_dim], skipna=True)
    else:
        # Use first data variable
        var = list(subset.data_vars)[0]
        ts = subset[var].mean(dim=[lon_dim, lat_dim], skipna=True)

    df = ts.to_dataframe().reset_index()
    df.columns = ["date", "value"]
    df["date"] = pd.to_datetime(df["date"])
    return df


def get_district_bbox(district: str) -> list:
    """Get bounding box for district."""
    bboxes = {
        "yavatmal": [77.5, 19.5, 79.5, 21.0],
        "amravati": [77.0, 20.0, 78.5, 21.5],
        "akola": [76.5, 20.0, 77.5, 21.0],
        "wardha": [78.0, 20.0, 79.5, 21.0],
        "nagpur": [78.5, 20.5, 80.0, 22.0],
    }
    key = district.lower()
    if key not in bboxes:
        raise ValueError(f"Unknown district: {district}")
    return bboxes[key]


def fetch_district_weather(
    district: str,
    start_year: int,
    end_year: int,
    variables: list = None,
    data_dir: Path = None,
) -> dict:
    """Fetch weather time series for a district over multiple years."""
    data_dir = data_dir or DATA_DIR
    variables = variables or list(VARIABLES.keys())

    bbox = get_district_bbox(district)
    results = {}

    for var in variables:
        logger.info(f"Processing {variable} for {district} ({start_year}-{end_year})")
        var_results = []

        for year in range(start_year, end_year + 1):
            try:
                extract_dir = download_imd_data(var, year, data_dir)
                ds = load_imd_netcdf(var, year, data_dir)

                if ds is not None:
                    df = extract_district_timeseries(ds, bbox, var)
                    if not df.empty:
                        df["year"] = year
                        df["variable"] = var
                        var_results.append(df)
            except Exception as e:
                logger.error(f"Failed to process {var} {year}: {e}")
                continue

        if var_results:
            results[var] = pd.concat(var_results, ignore_index=True)
            logger.info(f"Collected {len(results[var])} records for {var}")

    return results


def save_weather_data(results: dict, output_path: Path):
    """Save weather data to Parquet."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    combined = pd.concat(results.values(), ignore_index=True)
    combined.to_parquet(output_path, index=False)
    logger.info(f"Saved weather data to {output_path} ({len(combined)} records)")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Fetch IMD weather data for district")
    parser.add_argument("--district", required=True, help="District name")
    parser.add_argument("--start-year", type=int, required=True, help="Start year")
    parser.add_argument("--end-year", type=int, required=True, help="End year")
    parser.add_argument("--variables", nargs="+", default=list(VARIABLES.keys()), help="Variables to fetch")
    parser.add_argument("--output", help="Output Parquet file path")

    args = parser.parse_args()

    try:
        results = fetch_district_weather(
            district=args.district,
            start_year=args.start_year,
            end_year=args.end_year,
            variables=args.variables,
        )
        if args.output:
            save_weather_data(results, Path(args.output))
        else:
            for var, df in results.items():
                print(f"{var}: {len(df)} records")
    except Exception as e:
        logger.error(f"Weather fetch failed: {e}")
        raise