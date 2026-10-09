# Kisaan frontend demo

Live website: https://kisaan-ml-app.onrender.com/

## Presenting the project

Use **Try the demo farm**, or sign in with **farmer@kisaan.demo / FarmDemo26**.
The English dashboard includes farmer profiles, field management, harvest records,
advice history, weather examples, crop guides, saved yield scenarios and revenue calculations.
Create a separate demo profile to demonstrate an empty farm and add your own fictional records.

The planner accepts hectares or acres, coordinates, crop, sowing date, irrigation,
reference yield, sale price and cultivation cost. Results show condition fit,
production, a sensitivity range, illustrative harvest date, care suggestions and revenue.
Coordinates are recorded but do not fetch real weather in this phase.

## Scope

This is the frontend presentation phase requested by the project owner.
All seeded farms, histories, weather and prices are fictional. Yield is a transparent
rule-based scenario, not trained ML inference. Crop temperature bands and durations
are demo assumptions. Seasonal water ranges link to the general FAO guide.
Do not present example figures as measured data or guarantees.

Sign-in is a demo flow with a shared public password, not secure authentication.
Profiles and records use browser localStorage; sessionStorage tracks the signed-in profile.
Use fictional details. No server account or password is created.
Backend authentication, durable storage, historical weather and validated models are future work.

## Run locally

The full repository is saved at D:\farmers_ml.
From the repo: node app/serve-local.cjs
Open http://127.0.0.1:3000 (this server serves demo/).

## Validation and deployment

From demo/: npm test
Five Node tests cover area scaling, unit conversion, invalid planner inputs,
climate/water scenario constraints and isolation of seeded profile data.
Browser checks cover demo login, creating an isolated profile, persistent fields,
harvest recording, saved scenarios, revenue conversion and mobile navigation.

Render serves demo/ from master. The Blueprint uses npm test as the build command
and publishes the directory as a static website. No frontend dependencies are required.
