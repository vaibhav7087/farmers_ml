"""
data/fetch_shc.py — Fetch Soil Health Card (SHC) data.

FAIL-CLOSED: No synthetic soil data. Missing source = hard error.

Soil Health Card scheme provides village-level soil test results:
- NPK (Nitrogen, Phosphorus, Potassium)
- pH, EC (Electrical Conductivity)
- Organic Carbon
- Micronutrients (Zn, Fe, Cu, Mn, B, S)

Data sources:
1. soilhealth.dac.gov.in - State-wise CSV downloads
2. data.gov.in - SHC datasets
3. API endpoints (limited)

This module handles downloading, parsing, and aggregating to district/village level.
"""
import os
import logging
import requests
import pandas as pd
from pathlib import Path
from typing import Optional, Dict, List
import io

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

SHC_BASE_URL = "https://soilhealth.dac.gov.in"
DATA_DIR = Path(os.getenv("SHC_DATA_DIR", "./data/shc"))
DATA_DIR.mkdir(parents=True, exist_ok=True)

STATES = [
    "Maharashtra", "Karnataka", "Andhra Pradesh", "Telangana", "Tamil Nadu",
    "Gujarat", "Rajasthan", "Madhya Pradesh", "Uttar Pradesh", "Bihar",
    "Punjab", "Haryana", "West Bengal", "Odisha", "Chhattisgarh",
    "Jharkhand", "Kerala", "Assam", "Himachal Pradesh", "Uttarakhand",
]


def get_shc_state_url(state: str) -> str:
    """Get SHC download URL for a state."""
    state_slug = state.lower().replace(" ", "-")
    return f"{SHC_BASE_URL}/StateWiseData/{state_slug}.csv"


def fetch_state_shc(state: str, output_dir: Path) -> Path:
    """Download SHC CSV for a state."""
    url = get_shc_state_url(state)
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{state.lower().replace(' ', '_')}_shc.csv"

    logger.info(f"Downloading SHC data for {state} from {url}")

    try:
        response = requests.get(url, timeout=120)
        response.raise_for_status()

        with open(output_path, "wb") as f:
            f.write(response.content)

        logger.info(f"Saved {state} SHC to {output_path} ({output_path.stat().st_size} bytes)")
        return output_path

    except requests.RequestException as e:
        raise RuntimeError(f"Failed to download SHC for {state}: {e}")


def parse_shc_csv(file_path: Path) -> pd.DataFrame:
    """Parse SHC CSV with flexible column handling."""
    try:
        df = pd.read_csv(file_path, encoding="utf-8", low_memory=False)
    except UnicodeDecodeError:
        df = pd.read_csv(file_path, encoding="latin-1", low_memory=False)

    logger.info(f"Loaded SHC CSV: {df.shape}, columns: {list(df.columns)}")

    # Standardize column names
    df.columns = [clean_shc_col(c) for c in df.columns]

    # Expected columns mapping
    col_mapping = {
        "state": ["state", "state_name"],
        "district": ["district", "district_name", "dist_name"],
        "block": ["block", "block_name", "taluka", "tehsil"],
        "village": ["village", "village_name", "gram_panchayat"],
        "year": ["year", "survey_year", "financial_year"],
        "season": ["season", "crop_season", "kharif_rabi"],
        "ph": ["ph", "ph_value", "soil_ph"],
        "ec": ["ec", "electrical_conductivity", "ec_dsm"],
        "oc": ["oc", "organic_carbon", "organic_c"],
        "n": ["n", "nitrogen", "available_n", "avail_n"],
        "p": ["p", "phosphorus", "available_p", "avail_p", "p2o5"],
        "k": ["k", "potassium", "available_k", "avail_k", "k2o"],
        "s": ["s", "sulphur", "sulfur", "available_s"],
        "zn": ["zn", "zinc", "available_zn"],
        "fe": ["fe", "iron", "available_fe"],
        "cu": ["cu", "copper", "available_cu"],
        "mn": ["mn", "manganese", "available_mn"],
        "b": ["b", "boron", "available_b"],
    }

    # Rename columns
    rename_map = {}
    for standard, variants in col_mapping.items():
        for col in df.columns:
            col_lower = col.lower().strip()
            if any(v.lower() == col_lower for v in variants):
                rename_map[col] = standard
                break

    df = df.rename(columns=rename_map)

    # Ensure numeric columns
    numeric_cols = ["ph", "ec", "oc", "n", "p", "k", "s", "zn", "fe", "cu", "mn", "b"]
    for col in numeric_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    return df


def clean_shc_col(col: str) -> str:
    """Clean SHC column name."""
    col = str(col).strip().lower()
    col = re.sub(r"[^\w]+", "_", col)
    return col.strip("_")


def aggregate_to_district(df: pd.DataFrame) -> pd.DataFrame:
    """Aggregate village-level SHC to district level."""
    group_cols = ["state", "district", "year"]
    available = [c for c in ["ph", "ec", "oc", "n", "p", "k", "s", "zn", "fe", "cu", "mn", "b"] if c in df.columns]

    if not available:
        logger.warning("No numeric soil parameters found for aggregation")
        return pd.DataFrame()

    agg = df.groupby(group_cols)[available].agg(["mean", "median", "std", "count"]).reset_index()
    agg.columns = ["_".join(col).strip("_") for col in agg.columns.values]
    return agg


def aggregate_to_block(df: pd.DataFrame) -> pd.DataFrame:
    """Aggregate village-level SHC to block level."""
    group_cols = ["state", "district", "block", "year"]
    available = [c for c in ["ph", "ec", "oc", "n", "p", "k", "s", "zn", "fe", "cu", "mn", "b"] if c in df.columns]

    agg = df.groupby(group_cols)[available].agg(["mean", "median", "count"]).reset_index()
    agg.columns = ["_".join(col).strip("_") for col in agg.columns.values]
    return agg


def fetch_state_shc_data(state: str, output_dir: Path) -> pd.DataFrame:
    """Fetch and parse SHC data for a state."""
    csv_path = fetch_state_shc(state, output_dir)
    df = parse_shc_csv(csv_path)
    df["state"] = state
    return df


def fetch_multiple_states(states: list, output_dir: Path) -> pd.DataFrame:
    """Fetch and combine SHC data for multiple states."""
    all_dfs = []
    for state in states:
        try:
            df = fetch_state_shc_data(state, output_dir)
            all_dfs.append(df)
            logger.info(f"Loaded {state}: {len(df)} records")
        except Exception as e:
            logger.error(f"Failed to fetch {state}: {e}")
            continue

    if not all_dfs:
        raise RuntimeError("No SHC data fetched for any state")

    combined = pd.concat(all_dfs, ignore_index=True)
    return combined


def save_shc_data(df: pd.DataFrame, output_path: Path):
    """Save SHC data to Parquet."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(output_path, index=False)
    logger.info(f"Saved SHC data to {output_path} ({len(df)} records)")


def load_shc_parquet(path: Path) -> pd.DataFrame:
    """Load SHC data from Parquet."""
    return pd.read_parquet(path)


def get_district_soil_profile(df: pd.DataFrame, district: str, state: str = None) -> Dict:
    """Get aggregated soil profile for a district."""
    filter_cols = ["district"]
    if state:
        filter_cols.append("state")

    mask = df[filter_cols[0]].str.lower() == district.lower()
    if state and "state" in df.columns:
        mask = mask & (df["state"].str.lower() == state.lower())

    district_df = df[mask]
    if district_df.empty:
        return {}

    numeric_cols = [c for c in ["ph", "ec", "oc", "n", "p", "k", "s", "zn", "fe", "cu", "mn", "b"] if c in district_df.columns]
    profile = {}
    for col in numeric_cols:
        vals = district_df[col].dropna()
        if len(vals) > 0:
            profile[col] = {
                "mean": float(vals.mean()),
                "median": float(vals.median()),
                "std": float(vals.std()),
                "min": float(vals.min()),
                "max": float(vals.max()),
                "count": int(vals.count()),
            }
    profile["sample_count"] = len(district_df)
    return profile


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Fetch Soil Health Card data")
    parser.add_argument("--state", help="State name (or 'all' for all states)")
    parser.add_argument("--output", help="Output Parquet file path")
    parser.add_argument("--states", nargs="+", help="List of states to fetch")

    args = parser.parse_args()

    output_dir = Path(args.output).parent if args.output else DATA_DIR

    try:
        if args.state == "all":
            states = STATES
        elif args.states:
            states = args.states
        elif args.state:
            states = [args.state]
        else:
            states = ["Maharashtra"]

        df = fetch_multiple_states(states, output_dir)

        if args.output:
            output_path = Path(args.output)
            save_shc_data(df, output_path)
        else:
            print(f"Loaded {len(df)} SHC records from {len(states)} states")
            print(df.head())

    except Exception as e:
        logger.error(f"SHC fetch failed: {e}")
        raise