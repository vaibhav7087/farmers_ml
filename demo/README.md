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

## Land, weather, earnings and buyers

Add or edit a field, then select **Add my land info using Google Maps**.
This opens an original illustrative map demo, not live Google Maps.
Enter a center location, tap corners or trace with a mouse/finger, finish the
outline, review hectares/acres/perimeter, then apply and save the field.
Boundary vertices and precise demo area are stored with the browser profile.
Editing area or center manually detaches the old boundary to avoid mismatched records.
Keyboard drawing: focus the map, use arrows to move the cursor, Enter to add corners.
A Google Maps link opens the entered center externally; drawing stays in this app.

Fields also save irrigation availability and water source.
Weather includes location-selected fictional weather profiles, seeded seasonal
history, a ranked crop comparison and **Next year & harvest** with a monthly
annual scenario, planting-window comparison and yield/revenue examples.
Year selection chooses a dummy annual rainfall scenario, not a long-range forecast.
Crop comparison uses three fixed fictional seasonal profiles, a sowing-season
factor, temperature/water factors and sample yield/cost/price assumptions.
Soil, source reliability, varieties and pests are not modeled.

Revenue has **Sale calculator**, **Estimated yield & revenue**, and **Find a buyer**.
Estimated revenue includes yield, gross income, per-land cost breakdowns,
net margin, margin percentage, break-even price and sensitivity scenarios.
Five fictional buyer listings can be filtered by crop/district and shortlisted.
No buyer is contacted, and no actual transaction is made.

Ten automated model/geometry tests pass. Browser validation covers persistent
boundary save/reopen, mobile area transfer, crop comparison, cost arithmetic,
buyer filtering/shortlisting and annual planting-window controls.

## Future live Google Maps prerequisites

Create a Google Cloud project, enable billing and the Maps JavaScript API,
then create an API key restricted to this API and the site's authorized referrers.
Use custom polygon/freehand input over Maps, and the geometry library for area.
The old DrawingManager library is unavailable in current versions; do not use it.
No key or paid service is configured by this demo.

## Saved-land views

Estimated yield & revenue automatically lists every field in the signed-in
farmer's saved records, with land names, locations, crops, yield, gross revenue,
costs, profit and combined farm totals. Expand a land card for its assumptions
and cost breakdown. There is no field selector or calculation form in this view.
Changes to My fields automatically feed the next revenue view.

Best crops for this land presents saved lands as selectable cards. Choosing a
card opens that land's crop rankings and synchronizes the weather location.
Each card shows its saved name, location, area, crop and water source.
