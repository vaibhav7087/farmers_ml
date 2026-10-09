export const CROPS = {
  cotton: { name: 'Cotton', emoji: '🌿', season: 'Kharif', days: 180, temp: [21, 32], water: [700, 1300], baseline: 2200, price: 6200, color: '#789a57', care: 'Watch crop moisture and drainage during flowering. Scout regularly for bollworm activity.' },
  soybean: { name: 'Soybean', emoji: '🌱', season: 'Kharif', days: 140, temp: [20, 30], water: [450, 700], baseline: 1800, price: 4500, color: '#b1b973', care: 'Avoid standing water, check nodulation and keep weeds under control early in the season.' },
  maize: { name: 'Maize', emoji: '🌽', season: 'Kharif', days: 125, temp: [18, 30], water: [500, 800], baseline: 4500, price: 2200, color: '#d5b15c', care: 'Keep water available around tasseling and silking. Use a soil test to plan nutrient applications.' },
  wheat: { name: 'Wheat', emoji: '🌾', season: 'Rabi', days: 135, temp: [12, 25], water: [450, 650], baseline: 3500, price: 2400, color: '#d3a66b', care: 'Choose a locally suitable sowing window and variety. Monitor irrigation and heat around grain filling.' }
};
export const DEMO_LOGIN = { email: 'farmer@kisaan.demo', password: 'FarmDemo26' };
export function seedFarmer(id = 'ramesh') {
  return {
    id, name: 'Ramesh Patil', email: DEMO_LOGIN.email, village: 'Yavatmal, Maharashtra', experience: 12,
    fields: [
      { id: 'north', name: 'North field', area: 2.4, crop: 'cotton', location: 'Yavatmal, Maharashtra', lat: 20.3899, lon: 78.1307, soil: 'Black cotton soil', irrigation: 'Drip irrigation', sowing: '2026-06-18', status: 'Boll development' },
      { id: 'river', name: 'Riverside plot', area: 1.6, crop: 'soybean', location: 'Yavatmal, Maharashtra', lat: 20.405, lon: 78.145, soil: 'Loam', irrigation: 'Rainfed', sowing: '2026-06-25', status: 'Harvest ready' },
      { id: 'east', name: 'East field', area: 1.2, crop: 'wheat', location: 'Yavatmal, Maharashtra', lat: 20.375, lon: 78.119, soil: 'Clay loam', irrigation: 'Sprinkler', sowing: '2026-11-15', status: 'Preparing next season' }
    ],
    harvests: [
      { id: 'h1', field: 'north', crop: 'cotton', season: 'Kharif 2025', date: '2025-11-20', kg: 5280, area: 2.4, price: 6200, cost: 142000, note: 'Sample: improved drainage and soil-tested nutrition.', sample: true },
      { id: 'h2', field: 'river', crop: 'soybean', season: 'Kharif 2025', date: '2025-10-12', kg: 2880, area: 1.6, price: 4500, cost: 58000, note: 'Sample: early weed management and crop rotation.', sample: true },
      { id: 'h3', field: 'east', crop: 'wheat', season: 'Rabi 2025', date: '2025-03-22', kg: 4200, area: 1.2, price: 2400, cost: 42000, note: 'Sample: irrigation checks during grain filling.', sample: true },
      { id: 'h4', field: 'north', crop: 'cotton', season: 'Kharif 2024', date: '2024-11-18', kg: 4704, area: 2.4, price: 6000, cost: 136000, note: 'Sample: irregular irrigation before flowering.', sample: true }
    ],
    advice: [
      { id: 'a1', date: '2025-06-12', crop: 'cotton', title: 'Start with a soil test', text: 'Plan nutrient use around the soil test and the crop stage, rather than repeating last season’s application.', action: 'Soil-tested nutrition plan recorded', outcome: 'Sample yield rose from 1,960 to 2,200 kg/ha', state: 'Applied' },
      { id: 'a2', date: '2025-07-08', crop: 'soybean', title: 'Keep drainage channels clear', text: 'Check for standing water after rain and keep drainage outlets clear.', action: 'Drainage inspection recorded', outcome: 'Sample season completed with 2,880 kg harvested', state: 'Applied' },
      { id: 'a3', date: '2026-09-24', crop: 'cotton', title: 'Watch moisture at boll development', text: 'Inspect soil moisture before irrigating; use local crop guidance to decide timing.', action: 'Schedule a field check this week', outcome: 'No outcome recorded yet', state: 'To review' }
    ], plans: []
  };
}
export function emptyFarmer({ name, email, village }) {
  return { id: crypto.randomUUID(), name, email, village, experience: 0, fields: [], harvests: [], advice: [], plans: [] };
}
export function hectares(area, unit = 'ha') {
  const n = Number(area);
  if (!Number.isFinite(n) || n <= 0 || n > 100000) throw new Error('Enter a land area greater than zero and no more than 100,000.');
  if (!['ha', 'acre'].includes(unit)) throw new Error('Choose hectares or acres.');
  return unit === 'acre' ? n * 0.40468564224 : n;
}
export function revenue(quantity, unit, price, cost = 0) {
  const n = Number(quantity), p = Number(price), c = Number(cost);
  if (![n, p, c].every(v => Number.isFinite(v) && v >= 0)) throw new Error('Quantity, price and cost must be zero or greater.');
  const factors = { kg: 1, quintal: 100, tonne: 1000 };
  if (!Object.hasOwn(factors, unit)) throw new Error('Choose a valid quantity unit.');
  const kg = n * factors[unit], gross = kg / 100 * p;
  return { kg, quintals: kg / 100, gross, net: gross - c };
}
export function exampleClimate(crop, month = 6) {
  if (!CROPS[crop]) throw new Error('Choose a crop.');
  // Seeded demo inputs; these are never represented as fetched weather.
  const winter = [11, 12, 1, 2].includes(Number(month));
  const seasons = [
    { year: 2023, rain: winter ? 88 : 792, temp: winter ? 20.8 : 28.1 },
    { year: 2024, rain: winter ? 72 : 864, temp: winter ? 21.6 : 27.6 },
    { year: 2025, rain: winter ? 104 : 831, temp: winter ? 20.4 : 28.4 }
  ];
  return { source: 'Seeded historical weather example', seasons, rain: seasons.reduce((s, y) => s + y.rain, 0) / 3, temp: seasons.reduce((s, y) => s + y.temp, 0) / 3 };
}
export function analyzeField(input) {
  const crop = CROPS[input.crop];
  if (!crop) throw new Error('Choose a crop.');
  const lat = Number(input.lat), lon = Number(input.lon);
  if (String(input.lat).trim() === '' || String(input.lon).trim() === '' || !Number.isFinite(lat) || !Number.isFinite(lon) || Math.abs(lat) > 90 || Math.abs(lon) > 180) throw new Error('Enter valid latitude (−90 to 90) and longitude (−180 to 180).');
  const area = hectares(input.area, input.unit);
  const baseline = Number(input.baseline), water = Number(input.water), price = Number(input.price), cost = Number(input.cost);
  if (!Number.isFinite(baseline) || baseline <= 0 || ![water, price, cost].every(v => Number.isFinite(v) && v >= 0)) throw new Error('Reference yield must be positive. Irrigation, price and cost cannot be negative.');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(input.sowing || '') || Number.isNaN(Date.parse(input.sowing))) throw new Error('Choose a valid sowing date.');
  const historical = exampleClimate(input.crop, Number(input.sowing.slice(5, 7)));
  const tempDistance = Math.max(crop.temp[0] - historical.temp, historical.temp - crop.temp[1], 0);
  const temperatureFactor = Math.max(0.55, 1 - tempDistance * 0.05);
  const waterFactor = Math.min(1, Math.max(0.3, (historical.rain + water) / crop.water[0]));
  const factor = Math.min(temperatureFactor, waterFactor);
  const perHa = baseline * factor, totalKg = perHa * area;
  const lowKg = totalKg * 0.75, highKg = totalKg * 1.25;
  const harvestDate = new Date(input.sowing + 'T12:00:00Z'); harvestDate.setUTCDate(harvestDate.getUTCDate() + crop.days);
  const waterGap = Math.max(0, crop.water[0] - historical.rain - water);
  const fit = tempDistance > 0 ? 'Review temperature fit' : waterFactor < 1 ? 'Needs an irrigation plan' : 'Compatible in this demo';
  const steps = [
    waterGap > 0 ? `This sample season leaves a ${Math.round(waterGap)} mm gap below the lower water guide. Confirm water availability before choosing this crop.` : 'Sample rainfall plus planned irrigation reaches the lower seasonal water guide. Check distribution and drainage as well as the total.',
    tempDistance > 0 ? 'The sample seasonal temperature falls outside the illustrative crop band. Review the sowing window and locally suitable varieties.' : 'The sample average temperature fits the illustrative crop band. Heatwaves and crop-stage temperatures still need separate checks.',
    crop.care,
    'Confirm soil fertility, pests, variety, irrigation and local field records before making a planting decision.'
  ];
  return { ...input, areaHa: area, cropName: crop.name, historical, temperatureFactor, waterFactor, factor, perHa, totalKg, lowKg, highKg, gross: totalKg / 100 * price, net: totalKg / 100 * price - cost, lowRevenue: lowKg / 100 * price, highRevenue: highKg / 100 * price, waterGap, fit, steps, harvestDate: harvestDate.toISOString().slice(0, 10), createdAt: new Date().toISOString(), sample: true };
}
export function exampleForecast() {
  const pattern = [ { low: 22, high: 31, rain: 2, icon: '☀' }, { low: 23, high: 30, rain: 8, icon: '☁' }, { low: 22, high: 29, rain: 14, icon: '☂' }, { low: 21, high: 29, rain: 4, icon: '☁' }, { low: 22, high: 31, rain: 0, icon: '☀' }, { low: 23, high: 32, rain: 0, icon: '☀' }, { low: 22, high: 30, rain: 6, icon: '☁' } ];
  return pattern.map((d, i) => { const date = new Date(); date.setDate(date.getDate() + i); return { ...d, date: date.toISOString().slice(0, 10), label: i === 0 ? 'Today' : date.toLocaleDateString('en-IN', { weekday: 'short' }) }; });
}
