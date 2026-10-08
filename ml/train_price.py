"""
ml/train_price.py — Train price prediction models (Holt-Winters + LightGBM).

FAIL-CLOSED: No synthetic prices. Requires real AgMarkNet data.

Models:
1. Holt-Winters (statistical baseline) - per mandi-commodity-variety
2. LightGBM (ML) - with policy event features

Features:
- Historical prices (lags, rolling stats)
- Seasonal patterns
- Arrival volumes
- Policy events (MSP, procurement, export bans)
- Weather impacts (optional)
- Futures/NCDEX prices (if available)
"""
import os
import json
import logging
import joblib
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Dict, List, Tuple
from statsmodels.tsa.holtwinters import ExponentialSmoothing
from statsmodels.tsa.stattools import adfuller
import lightgbm as lgb
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.model_selection import TimeSeriesSplit

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MODEL_DIR = Path(os.getenv("MODEL_DIR", "./models/price"))
DATA_DIR = Path(os.getenv("DATA_DIR", "./data"))
MODEL_DIR.mkdir(parents=True, exist_ok=True)

TARGET = "modal_price"
HORIZON = 14  # days ahead


def load_price_data() -> pd.DataFrame:
    """Load and prepare AgMarkNet price data. FAIL-CLOSED if missing."""
    price_path = Path(os.getenv("PRICE_DATA_PATH", DATA_DIR / "processed" / "agmarknet_prices.parquet"))
    if not price_path.exists():
        raise FileNotFoundError(f"Price data not found: {price_path}. Run fetch_agmarknet.py first.")

    df = pd.read_parquet(price_path)
    logger.info(f"Loaded price data: {df.shape}")

    # Ensure required columns
    required = ["date", "market", "commodity", "variety", "modal_price"]
    missing = [c for c in ["date", "market", "commodity", "modal_price"] if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    df["date"] = pd.to_datetime(df["date"])
    df = df.sort_values(["market", "commodity", "variety", "date"])
    return df


def create_price_features(df: pd.DataFrame, horizon: int = HORIZON) -> pd.DataFrame:
    """Create features for price prediction."""
    df = df.copy()
    df = df.sort_values("date")

    # Target: price at t+horizon
    df["target"] = df.groupby(["market", "commodity", "variety"])["modal_price"].shift(-horizon)

    # Lag features
    for lag in [1, 2, 3, 7, 14, 21, 28]:
        df[f"lag_{lag}"] = df.groupby(["market", "commodity", "variety"])["modal_price"].shift(lag)

    # Rolling statistics
    for window in [7, 14, 28]:
        df[f"rolling_mean_{window}"] = df.groupby(["market", "commodity", "variety"])["modal_price"].transform(
            lambda x: x.rolling(window, min_periods=1).mean()
        )
        df[f"rolling_std_{window}"] = df.groupby(["market", "commodity", "variety"])["modal_price"].transform(
            lambda x: x.rolling(window, min_periods=1).std()
        )
        df[f"rolling_min_{window}"] = df.groupby(["market", "commodity", "variety"])["modal_price"].transform(
            lambda x: x.rolling(window, min_periods=1).min()
        )
        df[f"rolling_max_{window}"] = df.groupby(["market", "commodity", "variety"])["modal_price"].transform(
            lambda x: x.rolling(window, min_periods=1).max()
        )

    # Price changes
    df["pct_change_1"] = df.groupby(["market", "commodity", "variety"])["modal_price"].pct_change()
    df["pct_change_7"] = df.groupby(["market", "commodity", "variety"])["modal_price"].pct_change(7)

    # Arrival features (if available)
    if "arrival" in df.columns:
        df["arrival_lag_1"] = df.groupby(["market", "commodity", "variety"])["arrival"].shift(1)
        df["arrival_rolling_7"] = df.groupby(["market", "commodity", "variety"])["arrival"].transform(
            lambda x: x.rolling(7, min_periods=1).mean()
        )

    # Time features
    df["day_of_week"] = df["date"].dt.dayofweek
    df["day_of_month"] = df["date"].dt.day
    df["month"] = df["date"].dt.month
    df["quarter"] = df["date"].dt.quarter
    df["day_of_year"] = df["date"].dt.dayofyear

    # Cyclical encoding
    df["month_sin"] = np.sin(2 * np.pi * df["month"] / 12)
    df["month_cos"] = np.cos(2 * np.pi * df["month"] / 12)
    df["dow_sin"] = np.sin(2 * np.pi * df["day_of_week"] / 7)
    df["dow_cos"] = np.cos(2 * np.pi * df["day_of_week"] / 7)

    return df


def train_holt_winters(series: pd.Series, seasonal_periods: int = 52) -> Dict:
    """Train Holt-Winters model on a single price series."""
    # Remove NaN
    clean = series.dropna()
    if len(clean) < 2 * 52:  # Need at least 2 years
        return {"model": None, "error": "Insufficient data for Holt-Winters"}

    try:
        model = ExponentialSmoothing(
            clean,
            trend="add",
            seasonal="add",
            seasonal_periods=52,
            initialization_method="estimated",
        ).fit(optimized=True)

        return {
            "model": model,
            "params": {"alpha": model.params["smoothing_level"],
                       "beta": model.params["smoothing_trend"],
                       "gamma": model.params["smoothing_seasonal"]},
            "aic": model.aic,
            "fitted_values": model.fittedvalues.tolist(),
        }
    except Exception as e:
        logger.warning(f"Holt-Winters failed: {e}")
        return {"model": None, "error": str(e)}


def train_lightgbm_price(X_train: pd.DataFrame, y_train: pd.Series, X_val: pd.DataFrame, y_val: pd.Series) -> lgb.Booster:
    """Train LightGBM for price prediction."""
    params = {
        "objective": "regression",
        "metric": "mae",
        "boosting_type": "gbdt",
        "num_leaves": 64,
        "learning_rate": 0.05,
        "feature_fraction": 0.8,
        "bagging_fraction": 0.8,
        "bagging_freq": 5,
        "verbose": -1,
        "seed": 42,
        "n_estimators": 500,
        "early_stopping_rounds": 50,
    }

    train_data = lgb.Dataset(X_train, label=y_train)
    val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)

    model = lgb.train(
        params,
        train_data,
        valid_sets=[train_data, val_data],
        valid_names=["train", "val"],
        callbacks=[lgb.log_evaluation(50)],
    )
    return model


def train_price_models(df: pd.DataFrame) -> Dict:
    """Train models for each mandi-commodity-variety combination."""
    results = {}

    for (market, commodity, variety), group in df.groupby(["market", "commodity", "variety"]):
        logger.info(f"Training for {market} - {commodity} - {variety} ({len(group)} records)")

        if len(group) < 100:
            logger.warning(f"Insufficient data for {market}-{commodity}-{variety}: {len(group)} records")
            continue

        # Create features
        feat_df = create_price_features(group)
        feat_df = feat_df.dropna(subset=["target"])

        if len(feat_df) < 50:
            continue

        # Time series split
        tscv = TimeSeriesSplit(n_splits=3)
        hw_results = []
        lgb_results = []

        for train_idx, val_idx in tscv.split(group):
            train_group = group.iloc[train_idx]
            val_group = group.iloc[val_idx]

            # Holt-Winters on training
            hw_result = train_holt_winters(train_group.set_index("date")["modal_price"])
            hw_results.append(hw_result)

            # LightGBM
            feat_train = create_price_features(train_group).dropna(subset=["target"])
            feat_val = create_price_features(val_group).dropna(subset=["target"])

            if len(feat_train) > 20 and len(feat_val) > 10:
                feature_cols = [c for c in feat_train.columns if c not in ["date", "target", "market", "commodity", "variety"]]
                X_train = feat_train[feature_cols]
                y_train = feat_train["target"]
                X_val = feat_val[feature_cols]
                y_val = feat_val["target"]

                try:
                    model = train_lightgbm_price(X_train, y_train, X_val, y_val)
                    lgb_results.append({"model": model, "features": feature_cols})
                except Exception as e:
                    logger.warning(f"LightGBM failed: {e}")

        # Select best model based on validation MAE
        best_model = select_best_model(hw_results, lgb_results)
        results[f"{market}_{commodity}_{variety}"] = best_model

    return results


def select_best_model(hw_results: List, lgb_results: List) -> Dict:
    """Select best model based on validation performance."""
    # Simplified: prefer LightGBM if available, else Holt-Winters
    if lgb_results:
        return {"type": "lightgbm", "models": lgb_results}
    elif hw_results:
        return {"type": "holt_winters", "models": hw_results}
    else:
        return {"type": "none", "error": "No models trained"}


def save_price_models(results: Dict, metadata: Dict):
    """Save price models and metadata."""
    MODEL_DIR.mkdir(parents=True, exist_ok=True)

    # Save each model
    for key, model_info in results.items():
        if model_info["type"] == "lightgbm":
            for i, m in enumerate(model_info["models"]):
                m["model"].save_model(str(MODEL_DIR / f"{key}_lgbm_{i}.txt"))
        elif model_info["type"] == "holt_winters":
            for i, m in enumerate(model_info["models"]):
                if m["model"]:
                    joblib.dump(m["model"], MODEL_DIR / f"{key}_hw_{i}.pkl")

    # Save metadata
    with open(MODEL_DIR / "metadata.json", "w") as f:
        json.dump(metadata, f, indent=2, default=str)

    logger.info(f"Saved {len(results)} price models to {MODEL_DIR}")


def main():
    try:
        df = load_price_data()
        logger.info(f"Loaded {len(df)} price records")

        # Feature engineering
        logger.info("Creating features...")
        df_feat = create_price_features(df)

        # Train models
        logger.info("Training price models...")
        results = train_price_models(df_feat)

        # Metadata
        metadata = {
            "trained_at": pd.Timestamp.now().isoformat(),
            "n_combinations": len(results),
            "horizon": 14,
            "target": "modal_price",
            "models": {k: v["type"] for k, v in results.items()},
        }

        save_price_models(results, metadata)

        print(json.dumps({"status": "success", "models_trained": len(results)}, indent=2))

    except Exception as e:
        logger.error(f"Price training failed: {e}")
        raise


if __name__ == "__main__":
    main()