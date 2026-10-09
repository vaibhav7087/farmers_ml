# Render deployment

The repository is cloned at D:\farmers_ml. The current master branch includes deployment fixes and the dashboard update.

## Quick deployment

Create a Render Blueprint using https://github.com/vaibhav7087/farmers_ml.
Select branch master and Blueprint Path render.yaml.
This provisions a free Node web service and a free Key Value instance in Singapore.
It does not provision Postgres or request Cloudflare credentials: the current Render code does not use them.
Once Render marks the service Live, open its public URL and /health.

Alternatively create Key Value first (Free, Singapore, eviction policy noeviction), then a Web Service:
- Repository: https://github.com/vaibhav7087/farmers_ml
- Branch: master
- Root Directory: render-service
- Runtime: Node
- Build Command: npm ci --include=dev && npm run build
- Start Command: npm start
- Instance Type: Free
- Environment: NODE_ENV=production, NODE_VERSION=22.22.0, REDIS_URL=<internal Key Value URL>
- Health Check Path: /health

## Current project limitations

The public website serves the English farmer workspace in demo/. See demo/README.md for credentials, features and frontend demo scope.
The Flutter application remains available in app/ as source code.
Dashboard scenarios, alerts and chart values are samples, not live predictions.
The Render backend contains placeholder training data, simulated inference and fixed satellite indices.
Successful health checks demonstrate server/queue availability, not ML correctness.

## Local validation

cd D:\farmers_ml\render-service
npm ci
npm run typecheck
npm test

To run locally, set REDIS_URL to a local Redis URL, then npm start.


## Dashboard website

Website: https://kisaan-ml-app.onrender.com
Backend: https://kisaan-ml-render.onrender.com
Both Render services track master. The static site uses root directory demo, build command node --check dashboard.js and publish directory .
Future pushes to master automatically update the deployed dashboard.
Local clone: D:\farmers_ml
Local dashboard: node app/serve-local.cjs demo (http://localhost:3000)
Flutter SDK: D:\farmers_ml\.tools\flutter\bin\flutter.bat

