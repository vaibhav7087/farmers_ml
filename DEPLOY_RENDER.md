# Render deployment

The repository is cloned at D:\farmers_ml. Deployment fixes are on codex/render-deployment.

## Quick deployment

Create a Render Blueprint using https://github.com/vaibhav7087/farmers_ml.
Select branch codex/render-deployment and Blueprint Path render.yaml.
This provisions a free Node web service and a free Key Value instance in Singapore.
It does not provision Postgres or request Cloudflare credentials: the current Render code does not use them.
Once Render marks the service Live, open its public URL and /health.

Alternatively create Key Value first (Free, Singapore, eviction policy noeviction), then a Web Service:
- Repository: https://github.com/vaibhav7087/farmers_ml
- Branch: codex/render-deployment
- Root Directory: render-service
- Runtime: Node
- Build Command: npm ci --include=dev && npm run build
- Start Command: npm start
- Instance Type: Free
- Environment: NODE_ENV=production, NODE_VERSION=22.22.0, REDIS_URL=<internal Key Value URL>
- Health Check Path: /health

## Current project limitations

This deploys the Render backend API, not the Flutter frontend or Cloudflare Workers.
The frontend still requires its own build/deployment and API integration.
The backend contains placeholder training data, simulated inference and fixed satellite indices.
Successful health checks demonstrate server/queue availability, not ML correctness.
Free services have hosting and persistence limits. Do not rely on free Redis for durable job storage.
Public-repository deployments without the GitHub integration do not automatically deploy new commits.
For automatic deployment, configure Render's GitHub integration for this repository; repository-owner approval may be needed.

## Local validation

cd D:\farmers_ml\render-service
npm ci
npm run typecheck
npm test

To run locally, set REDIS_URL to a local Redis URL, then npm start.


## Farmer app website

The Blueprint also publishes the Flutter app as a free static website. It uses Flutter 3.27.4 and the backend API at https://kisaan-ml-render.onrender.com/api/v1.
Local Flutter SDK: D:\farmers_ml\.tools\flutter\bin\flutter.bat
Build locally from app: ..\.tools\flutter\bin\flutter.bat build web --release
The mobile app's existing demo login and sample chart/market values remain demonstration features. Real advisory is unavailable until models and training data are integrated.
