"""
ml/train_yield.py — Train yield prediction model (LightGBM).

FAIL-CLOSED: No synthetic data. Requires real satellite + weather + soil data.

Features:
- Satellite: NDVI, EVI, SAVI, NDVI trend (from Sentinel-2)
- Weather: Temperature, rainfall, humidity (from IMD)
- Soil: NPK, pH, OC (from SHC)
- Management: Crop, variety, sowing week, irrigation
- Static: District, soil type, elevation

Output: LightGBM model (ONNX) + feature importance + metrics
"""
import os
import json
import logging
import joblib
import lightgbm as lgb
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Dict, List, Tuple
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.preprocessing import StandardScaler
import shap

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MODEL_DIR = Path(os.getenv("MODEL_DIR", "./models/yield"))
DATA_DIR = Path(os.getenv("DATA_DIR", "./data"))
MODEL_DIR.mkdir(parents=True, exist_ok=True)

TARGET = "yield_kg_per_ha"
CATEGORICAL_FEATURES = ["crop", "district", "season", "variety", "soil_type"]
NUMERIC_FEATURES = [
    "ndvi_mean", "evi_mean", "savi_mean", "ndvi_trend",
    "temp_avg", "rainfall_total", "humidity_avg",
    "soil_n", "soil_p", "soil_k", "soil_ph", "soil_oc",
    "sowing_week", "elevation",
]
ALL_FEATURES = CATEGORICAL_FEATURES + NUMERIC_FEATURES

LGB_PARAMS = {
    "objective": "regression",
    "metric": "rmse",
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


def load_training_data() -> pd.DataFrame:
    """Load and merge all feature sources. FAIL-CLOSED if any missing."""
    logger.info("Loading training data...")

    # 1. Satellite indices
    sat_path = DATA_DIR / "processed" / "satellite_indices.parquet"
    if not sat_path.exists():
        raise FileNotFoundError(f"Satellite indices not found: {sat_path}. Run fetch_sentinel2.py first.")
    sat_df = pd.read_parquet(sat_path)
    logger.info(f"Loaded satellite data: {sat_df.shape}")

    # 2. Weather
    weather_path = DATA_DIR / "processed" / "weather.parquet"
    if not weather_path.exists():
        raise FileNotFoundError(f"Weather data not found: {weather_path}. Run fetch_imd_weather.py first.")
    weather_df = pd.read_parquet(weather_path)
    logger.info(f"Loaded weather data: {weather_df.shape}")

    # 3. Soil
    soil_path = DATA_DIR / "processed" / "soil_district.parquet"
    if not soil_path.exists():
        raise FileNotFoundError(f"Soil data not found: {soil_path}. Run fetch_shc.py first.")
    soil_df = pd.read_parquet(soil_path)
    logger.info(f"Loaded soil data: {soil_df.shape}")

    # 4. Yield labels (from Crop Cutting Experiments or district-level stats)
    yield_path = DATA_DIR / "raw" / "crop_yield_cces.parquet"
    if not yield_path.exists():
        raise FileNotFoundError(f"Yield labels not found: {yield_path}. Need CCE data.")
    yield_df = pd.read_parquet(yield_path)
    logger.info(f"Loaded yield labels: {yield_df.shape}")

    # Merge all
    df = yield_df.copy()
    for feat_df, keys in [
        (sat_df, ["district", "crop", "year", "week"]),
        (weather_df, ["district", "year", "week"]),
        (soil_df, ["district", "year"]),
    ]:
        df = df.merge(feat_df, on=keys, how="left")

    # Check for missing features
    missing = [f for f in NUMERIC_FEATURES if f not in df.columns]
    if missing:
        raise ValueError(f"Missing numeric features after merge: {missing}")

    # Fill remaining NaN with median
    for col in NUMERIC_FEATURES:
        if df[col].isna().any():
            df[col] = df[col].fillna(df[col].median())

    logger.info(f"Final training data: {df.shape}")
    return df


def prepare_features(df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray, List[str]]:
    """Prepare feature matrix and target."""
    # Encode categoricals
    for cat in CATEGORICAL_FEATURES:
        if cat in df.columns:
            df[cat] = df[cat].astype("category").cat.codes

    feature_cols = CATEGORICAL_FEATURES + NUMERIC_FEATURES
    X = df[feature_cols].values
    y = df[TARGET].values
    return X, y, feature_cols


def train_model(X: np.ndarray, y: np.ndarray, feature_cols: List[str]) -> lgb.Booster:
    """Train LightGBM with cross-validation."""
    X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)

    train_data = lgb.Dataset(X_train, label=y_train, feature_name=feature_cols, categorical_feature=CATEGORICAL_FEATURES)
    val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)

    model = lgb.train(
        LGB_PARAMS,
        train_data,
        valid_sets=[train_data, val_data],
        valid_names=["train", "val"],
        callbacks=[lgb.log_evaluation(50)],
    )

    # Evaluate
    y_pred = model.predict(X_val, num_iteration=model.best_iteration)
    rmse = np.sqrt(mean_squared_error(y_val, y_pred))
    mae = mean_absolute_error(y_val, y_pred)
    r2 = r2_score(y_val, y_pred)
    logger.info(f"Validation RMSE: {rmse:.2f}, MAE: {mae:.2f}, R2: {r2:.4f}")

    # Cross-validation
    cv_scores = cross_val_score(
        lgb.LGBMRegressor(**LGB_PARAMS), X, y, cv=5, scoring="neg_root_mean_squared_error", n_jobs=-1
    )
    logger.info(f"CV RMSE: {-cv_scores.mean():.2f} (+/- {cv_scores.std()*2:.2f})")

    return model


def compute_shap_importance(model: lgb.Booster, X: np.ndarray, feature_cols: List[str]) -> Dict:
    """Compute SHAP values for feature importance."""
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X[:1000])  # Sample for speed

    importance = {}
    for i, col in enumerate(feature_cols):
        importance[col] = float(np.abs(shap_values[:, i]).mean())

    return dict(sorted(importance.items(), key=lambda x: x[1], reverse=True))


def save_model(model: lgb.Booster, feature_cols: List[str], importance: Dict, metrics: Dict):
    """Save model, metadata, and SHAP importance."""
    # Save LightGBM native format
    model.save_model(str(MODEL_DIR / "yield_lightgbm.txt"))

    # Convert to ONNX for Cloudflare Workers
    try:
        import onnxmltools
        from onnxmltools.convert.lightgbm import convert_lightgbm
        from skl2onnx.common.data_types import FloatTensorType

        initial_type = [("float_input", FloatTensorType([None, len(ALL_FEATURES)]))]
        onnx_model = convert_lightgbm(model, initial_types=initial_type, target_opset=12)
        with open(MODEL_DIR / "yield_lightgbm.onnx", "wb") as f:
            f.write(onnx_model.SerializeToString())
        logger.info("Saved ONNX model")
    except Exception as e:
        logger.warning(f"ONNX conversion failed: {e}")

    # Save feature columns and metadata
    metadata = {
        "feature_columns": feature_cols,
        "categorical_features": CATEGORICAL_FEATURES,
        "numeric_features": NUMERIC_FEATURES,
        "target": TARGET,
        "importance": importance,
        "metrics": metrics,
        "model_type": "lightgbm",
        "trained_at": pd.Timestamp.now().isoformat(),
    }
    with open(MODEL_DIR / "metadata.json", "w") as f:
        json.dump(metadata, f, indent=2)

    logger.info(f"Saved model and metadata to {MODEL_DIR}")


def main():
    try:
        df = load_training_data()
        X, y, feature_cols = prepare_features(df)
        model = train_model(X, y, feature_cols)
        importance = compute_shap_importance(model, X, feature_cols)

        # Final metrics
        X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)
        y_pred = model.predict(X_val, num_iteration=model.best_iteration)
        metrics = {
            "rmse": float(np.sqrt(mean_squared_error(y_val, y_pred))),
            "mae": float(mean_absolute_error(y_val, y_pred)),
            "r2": float(r2_score(y_val, y_pred)),
            "train_samples": len(X_train),
            "val_samples": len(X_val),
        }

        save_model(model, feature_cols, importance, metrics)

        print(json.dumps({
            "status": "success",
            "metrics": metrics,
            "top_features": dict(list(importance.items())[:10]),
        }, indent=2))

    except Exception as e:
        logger.error(f"Training failed: {e}")
        raise


if __name__ == "__main__":
    main()