"""
data/fetch_agmarknet.py — Fetch AgMarkNet mandi price data.

FAIL-CLOSED: No synthetic prices. Download fails = hard error.

AgMarkNet (agmarknet.gov.in) provides daily mandi-wise prices for agricultural commodities.
Data can be accessed via:
1. Direct CSV downloads from https://agmarknet.gov.in/PriceAndArrival.aspx
2. API endpoints (limited)
3. data.gov.in catalog (historical datasets)

This module handles:
- Downloading daily price CSV files
- Parsing and standardizing mandi/commodity/variety names
- Building time series per mandi-commodity-variety
"""
import os
import logging
import requests
import pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional, List
import io
import re

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

AGMARKNET_BASE = "https://agmarknet.gov.in"
DATA_DIR = Path(os.getenv("AGMARKNET_DATA_DIR", "./data/agmarknet"))
DATA_DIR.mkdir(parents=True, exist_ok=True)

COMMODITY_MAP = {
    "cotton": "Cotton",
    "soybean": "Soybean",
    "maize": "Maize",
    "wheat": "Wheat",
    "rice": "Rice (Paddy)",
    "tur": "Tur/Arhar",
    "gram": "Gram",
    "groundnut": "Groundnut",
    "sunflower": "Sunflower",
}

MAHARASHTRA_MANDIS = [
    "Yavatmal", "Amravati", "Akola", "Wardha", "Nagpur",
    "Chandrapur", "Gadchiroli", "Bhandara", "Gondia",
    "Akola", "Washim", "Buldhana",
]


def build_download_url(commodity: str, state: str = "Maharashtra", date: str = None) -> str:
    """Build AgMarkNet CSV download URL."""
    date = date or datetime.now().strftime("%d-%b-%Y")
    commodity_encoded = requests.utils.quote(commodity)
    return f"{AGMARKNET_BASE}/SearchCmmMkt.aspx?Tx_Commodity={commodity_encoded}&Tx_State={state}&Tx_District=0&Tx_Market=0&DateFrom={date}&DateTo={date}&Fr_Date={date}&To_Date={date}&Tx_Trend=0&Tx_CommodityHead={commodity}&Tx_StateHead={state}&Tx_DistrictHead=--Select--&Tx_MarketHead=--Select--"


def fetch_daily_prices(date: str = None, state: str = "Maharashtra") -> pd.DataFrame:
    """Fetch daily prices for all commodities in a state."""
    date = date or datetime.now().strftime("%d-%b-%Y")
    all_dfs = []

    for commodity_key, commodity_name in COMMODITY_MAP.items():
        url = build_download_url(commodity_name, state, date)
        logger.info(f"Fetching {commodity_name} prices for {date}")

        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()

            # AgMarkNet returns HTML table, need to parse
            df = parse_agmarknet_html(response.text, commodity_key)
            if not df.empty:
                df["commodity"] = commodity_key
                df["date"] = pd.to_datetime(date, format="%d-%b-%Y")
                all_dfs.append(df)
                logger.info(f"Fetched {len(df)} records for {commodity_key}")

        except Exception as e:
            logger.error(f"Failed to fetch {commodity_key} for {date}: {e}")

    if not all_dfs:
        raise RuntimeError(f"No price data fetched for {date}")

    return pd.concat(all_dfs, ignore_index=True)


def parse_agmarknet_html(html: str, commodity: str) -> pd.DataFrame:
    """Parse AgMarkNet HTML table to DataFrame."""
    tables = pd.read_html(html)
    if not tables:
        return pd.DataFrame()

    # Find the price table (usually the largest one)
    price_table = max(tables, key=len)

    # Standardize column names
    price_table.columns = [clean_col_name(c) for c in price_table.columns]

    # Expected columns: state, district, market, commodity, variety, grade, min_price, max_price, modal_price, arrival
    col_map = {
        "state": ["state", "state_name"],
        "district": ["district", "district_name"],
        "market": ["market", "market_name", "mandi", "mandi_name"],
        "commodity": ["commodity", "commodity_name"],
        "variety": ["variety", "variety_name"],
        "grade": ["grade", "grade_name"],
        "min_price": ["min_price", "minimum_price", "min"],
        "max_price": ["max_price", "maximum_price", "max"],
        "modal_price": ["modal_price", "modal", "price"],
        "arrival": ["arrival", "arrivals", "quantity"],
    }

    df = price_table.copy()
    df.columns = [standardize_col(c, col_map) for c in df.columns]

    # Keep only relevant columns
    keep_cols = ["state", "district", "market", "commodity", "variety", "grade", "min_price", "max_price", "modal_price", "arrival"]
    df = df[[c for c in keep_cols if c in df.columns]]

    # Convert price columns to numeric
    for col in ["min_price", "max_price", "modal_price", "arrival"]:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    return df.dropna(subset=["modal_price"])


def clean_col_name(col: str) -> str:
    """Clean column name to lowercase snake_case."""
    col = str(col).strip().lower()
    col = re.sub(r"[^\w]+", "_", col)
    col = col.strip("_")
    return col


def standardize_col(col: str, col_map: dict) -> str:
    """Map column to standard name."""
    col_lower = col.lower()
    for standard, variants in col_map.items():
        if col_lower in [v.lower() for v in variants]:
            return standard
    return col


def fetch_historical_data(
    start_date: str,
    end_date: str,
    commodities: list = None,
    state: str = "Maharashtra",
) -> pd.DataFrame:
    """Fetch price data for a date range."""
    commodities = commodities or list(COMMODITY_MAP.keys())
    start = pd.to_datetime(start_date)
    end = pd.to_datetime(end_date)
    all_dfs = []

    current = start
    while current <= end:
        date_str = current.strftime("%d-%b-%Y")
        try:
            df = fetch_daily_prices(date_str, state)
            if not df.empty:
                df["commodity"] = df["commodity"].astype(str)
                all_dfs.append(df)
        except Exception as e:
            logger.error(f"Failed to fetch for {date_str}: {e}")

        current += timedelta(days=1)

    if not all_dfs:
        raise RuntimeError(f"No data fetched for range {start_date} to {end_date}")

    return pd.concat(all_dfs, ignore_index=True)


def fetch_mandi_timeseries(
    commodity: str,
    mandi: str,
    state: str = "Maharashtra",
    start_date: str = None,
    end_date: str = None,
    variety: str = None,
) -> pd.DataFrame:
    """Fetch time series for specific mandi-commodity-variety."""
    df = fetch_historical_data(start_date, end_date, [commodity], state)
    df = df[(df["market"].str.lower() == mandi.lower()) & (df["commodity"] == commodity)]

    if variety:
        df = df[df["variety"].str.lower() == variety.lower()]

    return df.sort_values("date")


def save_to_parquet(df: pd.DataFrame, output_path: Path):
    """Save DataFrame to Parquet."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(output_path, index=False)
    logger.info(f"Saved {len(df)} records to {output_path}")


def load_from_parquet(path: Path) -> pd.DataFrame:
    """Load DataFrame from Parquet."""
    return pd.read_parquet(path)


def build_mandi_master(data_dir: Path) -> pd.DataFrame:
    """Build master list of mandis from downloaded data."""
    parquet_files = list(data_dir.glob("*.parquet"))
    if not parquet_files:
        return pd.DataFrame()

    dfs = [pd.read_parquet(f) for f in parquet_files]
    combined = pd.concat(dfs, ignore_index=True)

    master = combined[["state", "district", "market", "commodity"]].drop_duplicates()
    master = master.sort_values(["state", "district", "market", "commodity"])
    return master


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Fetch AgMarkNet mandi prices")
    parser.add_argument("--start-date", help="Start date YYYY-MM-DD")
    parser.add_argument("--end-date", help="End date YYYY-MM-DD")
    parser.add_argument("--commodity", help="Single commodity to fetch")
    parser.add_argument("--mandi", help="Specific mandi to filter")
    parser.add_argument("--state", default="Maharashtra", help="State name")
    parser.add_argument("--output", help="Output Parquet file")

    args = parser.parse_args()

    try:
        if args.start_date and args.end_date:
            df = fetch_historical_data(
                start_date=args.start_date,
                end_date=args.end_date,
                commodities=[args.commodity] if args.commodity else None,
                state=args.state,
            )
        else:
            # Single day
            df = fetch_daily_prices(state=args.state)
            if args.commodity:
                df = df[df["commodity"] == args.commodity]
            if args.mandi:
                df = df[df["market"].str.lower() == args.mandi.lower()]

        if args.output:
            output_path = Path(args.output)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            df.to_parquet(output_path, index=False)
            logger.info(f"Saved {len(df)} records to {args.output}")
        else:
            print(f"Fetched {len(df)} records")
            print(df.head())
    except Exception as e:
        logger.error(f"AgMarkNet fetch failed: {e}")
        raise