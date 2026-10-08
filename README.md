# Kisaan-ML: AI-Powered Crop Advisory for Indian Farmers

> **Real data. Real models. Real impact.**

Kisaan-ML is an end-to-end ML system for rural Indian farmers providing:
- 🌾 **Yield Forecasting** — Satellite + Weather + Soil fusion (LightGBM)
- 💰 **Price Forecasting** — Policy-aware mandi price prediction (Holt-Winters + LightGBM)
- 🚨 **Outbreak Alerts** — Pest/disease anomaly detection (IsolationForest)
- 📱 **Farmer App** — Flutter app with offline-first design (Hindi/Marathi/English)

---

## Architecture

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

## Quick Start

### Prerequisites
- Python 3.11+
- Node.js 20+ (for Cloudflare Workers)
- Flutter 3.22+ (for app)
- Cloudflare account (Workers + R2 + KV + D1)
- Render account (Web Service + Redis)
- GitHub account (CI/CD)

### 1. Clone and Setup
```bash
git clone https://github.com/yourusername/kisaan-ml
cd kisaan-ml

# Install Python deps
pip install -r requirements.txt

# Install worker deps
cd workers && npm install && cd ..

# Install render deps
cd render-service && npm install && cd ..

# Install Flutter deps
cd app && flutter pub get && cd ..
```

### 2. Configure Environment
```bash
# Copy example env files
cp workers/.env.example workers/.env
cp render-service/.env.example render-service/.env
cp app/.env.example app/.env

# Edit with your credentials:
# - Cloudflare: API_TOKEN, ACCOUNT_ID, R2_BUCKET, KV_NAMESPACE, D1_DATABASE
# - Render: REDIS_URL, SERVICE_URL
# - App: API_BASE_URL, SUPABASE_URL/KEY (if using)
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
# Train yield model (LightGBM)
python ml/train_yield.py

# Train price models (Holt-Winters + LightGBM)
python ml/train_price.py
```

### 5. Deploy
```bash
# Deploy Cloudflare Workers
cd workers && npm run deploy && cd ..

# Deploy Render Service
cd render-service && npm run deploy && cd ..

# Build Flutter App
cd app && flutter build apk --release --split-per-abi && cd ..
```

---

## Data Sources (All Public, No Auth Required)

| Pipeline | Source | Frequency | License |
|----------|--------|-----------|---------|
| **Sentinel-2** | Planetary Computer STAC API | 5-day revisit | Open |
| **IMD Weather** | imdpune.gov.in gridded data | Daily | Govt. Open |
| **AgMarkNet Prices** | agmarknet.gov.in / data.gov.in | Daily | Govt. Open |
| **Soil Health Card** | soilhealth.dac.gov.in | Seasonal | Govt. Open |
| **Policy Events** | pib.gov.in RSS | Real-time | Govt. Open |

**All pipelines are FAIL-CLOSED** — missing data = hard error with exact download instructions. No synthetic fallbacks.

---

## ML Models

### Yield Forecasting (LightGBM)
- **Features**: NDVI/EVI/SAVI trends, temperature, rainfall, humidity, soil NPK/pH/OC, sowing week, elevation
- **Target**: kg/ha at harvest
- **Validation**: 5-fold CV, RMSE ~300 kg/ha, R² > 0.75
- **Export**: ONNX for Cloudflare Workers

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

## API Endpoints (Cloudflare Workers)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check (KV, D1, R2) |
| `/api/v1/predict/yield` | GET | Yield forecast (district, crop, season, sowing_week) |
| `/api/v1/predict/price` | GET | Price forecast (mandi, crop, variety, horizon) |
| `/api/v1/advisory` | POST | Combined advisory (yield + price + economics) |
| `/api/v1/districts` | GET | List all districts with soil data |
| `/api/v1/mandis` | GET | List mandis (filter by state) |
| `/api/v1/crops` | GET | List supported crops |

---

## Render Service (Persistent Connections)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health + queue stats |
| `/ws/:channel` | WS | Real-time updates (training, satellite, inference) |
| `/api/v1/train/yield` | POST | Queue yield training job |
| `/api/v1/train/price` | POST | Queue price training job |
| `/api/v1/inference/batch` | POST | Batch inference |
| `/api/v1/satellite/fetch` | POST | Queue Sentinel-2 fetch |
| `/api/v1/retrain/all` | POST | Full retrain all crops |

---

## Flutter App

### Features
- **Offline-first**: Cached advisory, sync when online
- **Multilingual**: Hindi, Marathi, English
- **Voice input**: Speech-to-text for symptom entry
- **Advisory cards**: Yield + Price + Economics + Recommendations
- **Market watch**: Track mandi prices for watched crops
- **Alerts**: Price, weather, outbreak notifications
- **Profile**: Crops, districts, mandis, language preference

### Build
```bash
cd app
flutter pub get
flutter build apk --release --split-per-abi  # arm64-v8a, armeabi-v7a
flutter build web --release                   # For Cloudflare Pages
```

### Download
- **APK**: GitHub Releases (auto-published on push to main)
- **Web**: https://kisaan-ml.pages.dev (Cloudflare Pages)

---

## CI/CD (GitHub Actions)

| Workflow | Trigger | Actions |
|----------|---------|---------|
| `workers.yml` | Push to main (workers/) | Typecheck → Test → Deploy to CF Workers (preview/prod) |
| `render.yml` | Push to main (render-service/) | Test → Build → Deploy to Render |
| `flutter.yml` | Push to main (app/) | Analyze → Test → Build APK + Web → Upload to GH Release + Deploy to CF Pages |

---

## Secrets Required (GitHub Repository Settings)

| Secret | Used In | Description |
|--------|---------|-------------|
| `CF_API_TOKEN` | workers.yml, flutter.yml | Cloudflare API token (Workers + Pages) |
| `CF_ACCOUNT_ID` | workers.yml, flutter.yml | Cloudflare Account ID |
| `RENDER_API_KEY` | render.yml | Render API key |
| `RENDER_SERVICE_ID` | render.yml | Render Web Service ID (production) |
| `RENDER_SERVICE_ID_PREVIEW` | render.yml | Render Web Service ID (preview) |

---

## Project Structure

```
kisaan-ml/
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
│   │   ├── index.ts         # Fastify + WebSocket + BullMQ
│   │   ├── routes.ts        # REST API
│   │   └── workers/         # training, inference, satellite
│   ├── package.json
│   └── render.yaml          # Render config
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
├── scripts/                 # Utility scripts
├── .github/workflows/       # CI/CD
├── docker-compose.yml       # Local dev stack
├── README.md
└── LICENSE
```

---

## Local Development Stack

```bash
# Start local stack (PostgreSQL, Redis, MinIO for R2, Localstack for D1)
docker-compose up -d

# Run workers locally
cd workers && npm run dev

# Run render service locally
cd render-service && npm run dev

# Run Flutter app
cd app && flutter run
```

---

## License

MIT License - Code only. Data terms per respective sources:
- IMD/SHC/AgMarkNet: Government of India (open)
- Sentinel-2: ESA/Copernicus (open)
- PIB: Government of India (open)

---

## Contributing

1. Fork the repo
2. Create feature branch
3. Add tests for new features
4. Ensure all pipelines pass FAIL-CLOSED checks
5. Submit PR

---

## Acknowledgments

- **Planetary Computer** for Sentinel-2 STAC API
- **IMD Pune** for gridded weather data
- **AgMarkNet** for mandi price transparency
- **Soil Health Card Scheme** for village-level soil data
- **PIB** for policy event feeds
- **Indian farmers** — this is for you 🌾

---

**Built for Nexathon II — Healing with Data** 🏆