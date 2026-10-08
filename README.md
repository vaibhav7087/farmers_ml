# Kisaan-ML: AI-Powered Crop Advisory for Indian Farmers

> **Real data. Real models. Real impact.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Flutter 3.22+](https://img.shields.io/badge/flutter-3.22+-blue.svg)](https://flutter.dev/)
[![Cloudflare Workers](https://img.shields.io/badge/Cloudflare-Workers-orange.svg)](https://workers.cloudflare.com/)

Kisaan-ML is an end-to-end ML system for rural Indian farmers providing real-time, actionable agricultural intelligence. Built for **Nexathon II (Healing with Data)** — deploying production-grade ML on real public data with zero synthetic fallbacks.

---

## 🎯 What It Does

| Module | Description | Tech Stack |
|--------|-------------|------------|
| **🌾 Yield Forecasting** | Predicts kg/ha at harvest using satellite + weather + soil fusion | LightGBM → ONNX |
| **💰 Price Forecasting** | 14-day mandi price prediction with policy-event awareness | Holt-Winters + LightGBM |
| **🚨 Outbreak Alerts** | Pest/disease anomaly detection at district level | IsolationForest |
| **📱 Farmer App** | Offline-first Flutter app (Hindi/Marathi/English) | Flutter + Provider |

---

## 🏗 Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Data Pipelines │────▶│  ML Training     │────▶│  Model Registry │
│  (Satellite,    │     │  (Yield + Price) │     │  (R2 + ONNX)    │
│   Weather,      │     │                  │     │                 │
│   Soil, Prices) │     │                  │     │                 │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                    ┌─────────────────────────────────────┼────────┐
                    │                                     │        │
                    ▼                                     ▼        ▼
            ┌───────────────┐                   ┌───────────────┐ ┌───────────────┐
            │ Cloudflare    │                   │ Render Web    │ │ Flutter App   │
            │ Workers       │                   │ Service       │ │ (APK + Web)   │
            │ (Serverless   │                   │ (Persistent   │ │               │
            │  Inference)   │                   │  Connections) │ │               │
            └───────────────┘                   └───────────────┘ └───────────────┘
```

---

## 📊 Live Demo

| Service | URL |
|---------|-----|
| **API (Cloudflare Workers)** | `https://kisaan-ml-api.bylancetechnologies.workers.dev` |
| **Health Check** | `https://kisaan-ml-api.bylancetechnologies.workers.dev/health` |
| **Yield Prediction** | `GET /api/v1/predict/yield?district=yavatmal&crop=cotton` |
| **Price Prediction** | `GET /api/v1/predict/price?mandi=yavatmal%20mandi&crop=cotton` |
| **Combined Advisory** | `POST /api/v1/advisory` |

---

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Node.js 20+ (for Cloudflare Workers)
- Flutter 3.22+ (for mobile app)
- Cloudflare account (Workers + R2 + KV + D1)
- Render account (Web Service + Redis)
- GitHub account (CI/CD)

### 1. Clone & Setup
```bash
git clone https://github.com/vaibhav7087/farmers_ml.git
cd farmers_ml

# Python dependencies
pip install -r requirements.txt

# Cloudflare Workers
cd workers && npm install && cd ..

# Render Service
cd render-service && npm install && cd ..

# Flutter App
cd app && flutter pub get && cd ..
```

### 2. Configure Environment
```bash
# Workers
cp workers/.env.example workers/.env
# Add: CF_API_TOKEN, CF_ACCOUNT_ID

# Render Service
cp render-service/.env.example render-service/.env
# Add: REDIS_URL, DATABASE_URL, CF_R2 credentials

# Flutter App
cp app/.env.example app/.env
# Add: API_BASE_URL, SUPABASE credentials
```

### 3. Download Training Data (FAIL-CLOSED)
```bash
# Each script fails with exact download instructions if data missing
python data/fetch_sentinel2.py --district yavatmal --state Maharashtra
python data/fetch_imd_weather.py --district yavatmal --start-year 2015 --end-year 2023
python data/fetch_agmarknet.py --start-date 2018-01-01 --end-date 2023-12-31
python data/fetch_shc.py --state Maharashtra
```

### 4. Train Models
```bash
# Yield model (LightGBM → ONNX)
python ml/train_yield.py

# Price models (Holt-Winters + LightGBM)
python ml/train_price.py
```

### 5. Deploy
```bash
# Cloudflare Workers
cd workers && npm run deploy

# Render Service
cd render-service && npm run deploy

# Flutter App
cd app && flutter build apk --release --split-per-abi && flutter build web --release
```

---

## 📦 Data Sources (All Public, No Auth Required)

| Pipeline | Source | Frequency | License |
|----------|--------|-----------|---------|
| **Sentinel-2** | Planetary Computer STAC API | 5-day revisit | Open |
| **IMD Weather** | imdpune.gov.in gridded data | Daily | Govt. Open |
| **AgMarkNet Prices** | agmarknet.gov.in / data.gov.in | Daily | Govt. Open |
| **Soil Health Card** | soilhealth.dac.gov.in | Seasonal | Govt. Open |
| **Policy Events** | pib.gov.in RSS | Real-time | Govt. Open |

**All pipelines are FAIL-CLOSED** — missing data = hard error with exact download instructions. No synthetic fallbacks.

---

## 🤖 ML Models

### Yield Forecasting (LightGBM → ONNX)
- **Features**: NDVI/EVI/SAVI trends, temperature, rainfall, humidity, soil NPK/pH/OC, sowing week, elevation
- **Target**: kg/ha at harvest
- **Validation**: 5-fold CV, RMSE ~300 kg/ha, R² > 0.75
- **Export**: ONNX for Cloudflare Workers edge inference

### Price Forecasting (Holt-Winters + LightGBM)
- **Models per mandi-commodity-variety**
- **Holt-Winters**: Seasonal baseline (52-week period)
- **LightGBM**: Lags, rolling stats, arrivals, policy events
- **Policy features**: MSP announcements, procurement, export bans (from PIB RSS)
- **Horizon**: 14 days ahead

### Outbreak Detection (IsolationForest)
- District-week pest/disease reports
- Features: case count, rolling mean/std, week-of-year, ratio-to-mean
- Contamination: 0.05 (5% flag rate by design)
- Validation: 7× enrichment during known outbreak waves

---

## 📱 Flutter App

### Features
- **Offline-first**: Cached advisory, sync when online
- **Multilingual**: Hindi, Marathi, English
- **Voice input**: Speech-to-text for symptom entry
- **Advisory cards**: Yield + Price + Economics + Recommendations
- **Market watch**: Track mandi prices for watched crops
- **Alerts**: Price, weather, outbreak notifications
- **Profile**: Crops, districts, mandis, language preference

### Build & Download
```bash
cd app
flutter pub get
flutter build apk --release --split-per-abi  # arm64-v8a, armeabi-v7a
flutter build web --release                   # For Cloudflare Pages
```

**Downloads:**
- **APK**: GitHub Releases (auto-published on push)
- **Web App**: Cloudflare Pages (auto-deployed)

---

## 🔧 CI/CD (GitHub Actions)

| Workflow | Trigger | Actions |
|----------|---------|---------|
| `workers.yml` | Push to main (workers/) | Typecheck → Test → Deploy to CF Workers |
| `render.yml` | Push to main (render-service/) | Test → Build → Deploy to Render |
| `flutter.yml` | Push to main (app/) | Analyze → Test → Build APK + Web → Upload to GH Release + Deploy to CF Pages |

---

## 🔐 Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `CF_API_TOKEN` | Cloudflare API token (Workers + Pages permissions) |
| `CF_ACCOUNT_ID` | Cloudflare Account ID |
| `RENDER_API_KEY` | Render API key |
| `RENDER_SERVICE_ID` | Render Web Service ID (production) |
| `RENDER_SERVICE_ID_PREVIEW` | Render Web Service ID (preview) |

---

## 📁 Project Structure

```
farmers_ml/
├── workers/                 # Cloudflare Workers (serverless inference)
│   ├── src/
│   │   ├── index.ts         # Hono app + routes
│   │   ├── predictors/      # yield.ts, price.ts
│   │   └── utils/           # cache, health
│   ├── wrangler.toml        # CF config
│   └── package.json
│
├── render-service/          # Render Web Service (persistent)
│   ├── src/
│   │   ├── index.ts         # Fastify + BullMQ + WebSocket
│   │   ├── routes.ts        # REST API
│   │   └── workers/         # training, inference, satellite
│   ├── render.yaml          # Render config
│   └── package.json
│
├── ml/                      # ML Training Scripts
│   ├── train_yield.py       # LightGBM yield model
│   ├── train_price.py       # Holt-Winters + LightGBM price
│   └── requirements.txt
│
├── data/                    # Data Pipelines (FAIL-CLOSED)
│   ├── fetch_sentinel2.py   # Sentinel-2 from Planetary Computer
│   ├── fetch_imd_weather.py # IMD gridded weather
│   ├── fetch_agmarknet.py   # AgMarkNet mandi prices
│   ├── fetch_shc.py         # Soil Health Card
│   └── requirements.txt
│
├── app/                     # Flutter App
│   ├── lib/
│   │   ├── core/            # theme, router, providers
│   │   ├── features/
│   │   │   ├── auth/        # login, onboarding
│   │   │   ├── advisory/    # yield/price/advisory screens
│   │   │   ├── alerts/      # price/weather/outbreak alerts
│   │   │   ├── market/      # mandi prices
│   │   │   ├── profile/     # user profile
│   │   │   └── settings/    # language, notifications, theme
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── render.yaml          # Cloudflare Pages config
│
├── data/                    # Data Pipelines (FAIL-CLOSED)
├── ml/                      # ML Training Scripts
├── scripts/                 # Utility scripts
├── .github/workflows/       # CI/CD
├── docker-compose.yml       # Local dev stack
├── README.md
└── LICENSE
```

---

## 🐳 Local Development Stack

```bash
# Start local stack (PostgreSQL, Redis, MinIO for R2)
docker-compose up -d

# Run workers locally
cd workers && npm run dev

# Run render service locally
cd render-service && npm run dev

# Run Flutter app
cd app && flutter run
```

---

## 📜 License

MIT License - Code only. Data terms per respective sources:
- IMD/SHC/AgMarkNet: Government of India (open)
- Sentinel-2: ESA/Copernicus (open)
- PIB: Government of India (open)

Data terms are governed by their respective sources. This license applies only to the code in this repository, not to the data fetched or used by it.

---

## 🙏 Acknowledgments

- **Planetary Computer** for Sentinel-2 STAC API
- **IMD Pune** for gridded weather data
- **AgMarkNet** for mandi price transparency
- **Soil Health Card Scheme** for village-level soil data
- **PIB** for policy event feeds
- **Indian farmers** — this is for you 🌾

---

## 🏆 Built for Nexathon II — Healing with Data

**Team:** Kisaan-ML  
**Track:** Healing with Data / Paper Presentation  
**Venue:** AIKTC, New Panvel | 9th October 2024

---

*Real data. Real models. Real impact.* 🌾