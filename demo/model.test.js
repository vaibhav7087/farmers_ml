import { test } from 'node:test';
import assert from 'node:assert/strict';
import { hectares, revenue, seedFarmer, analyzeField, compareCrops, exampleForecast } from './model.js';
const input = { crop: 'cotton', area: 2, unit: 'ha', lat: 20.39, lon: 78.13, sowing: '2027-06-15', baseline: 2200, water: 0, price: 6200, cost: 100000 };
test('crop comparison responds to water, season, land area and demo location',()=>{
 const field={...seedFarmer().fields[0],waterMm:0};
 const dry=compareCrops(field),wet=compareCrops(field,{water:200});
 assert.equal(dry[0].crop,'maize');assert.equal(wet[0].crop,'cotton');
 const twice=compareCrops({...field,area:field.area*2});
 for(const r of dry){const t=twice.find(t=>t.crop===r.crop);assert.equal(t.totalKg,r.totalKg*2);assert.equal(t.net,r.net*2);}
 assert.ok(compareCrops(field,{sowing:'2027-11-15',water:500}).find(r=>r.crop==='wheat').factor>dry.find(r=>r.crop==='wheat').factor);
 assert.notDeepEqual(exampleForecast(field),exampleForecast({...field,lon:78.23}));
 assert.throws(()=>compareCrops(field,{water:-1}),/negative/);
});
test('land area scales output and revenue; acre conversion is exact', () => {
  assert.ok(Math.abs(hectares(1, 'acre') - 0.40468564224) < 1e-10);
  const one = analyzeField({ ...input, area: 1 }), two = analyzeField(input);
  assert.equal(two.totalKg, one.totalKg * 2);
  assert.equal(two.gross, one.gross * 2);
  assert.equal(two.lowKg, two.totalKg * .75);
});
test('sale calculator uses quintal prices consistently for every quantity unit', () => {
  assert.equal(revenue(1000, 'kg', 2400, 1000).gross, 24000);
  assert.equal(revenue(10, 'quintal', 2400).gross, revenue(1, 'tonne', 2400).gross);
  assert.equal(revenue(0, 'kg', 0, 100).net, -100);
  assert.throws(() => revenue(-1, 'kg', 100));
});
test('planner rejects missing or invalid coordinates, area and crop', () => {
  for (const patch of [{ area: -1 }, { lat: 100 }, { lon: 190 }, { lat: '' }, { crop: 'bad' }, { baseline: 0 }, { water: -5 }]) assert.throws(() => analyzeField({ ...input, ...patch }));
  assert.doesNotThrow(() => analyzeField({ ...input, lat: 0, lon: 0 }));
});
test('dry sample season reduces the scenario, irrigation cannot exceed reference yield', () => {
  const dry = analyzeField({ ...input, sowing: '2027-11-15' });
  const irrigated = analyzeField({ ...input, sowing: '2027-11-15', water: 1000 });
  assert.ok(dry.waterGap > 0);
  assert.ok(irrigated.totalKg > dry.totalKg);
  assert.ok(irrigated.factor <= 1);
});
test('demo profiles are independent copies and all records are marked as samples', () => {
  const a = seedFarmer(), b = seedFarmer(); a.fields[0].name = 'Changed';
  assert.equal(b.fields[0].name, 'North field');
  assert.ok(b.harvests.every(h => h.sample));
  assert.equal(analyzeField(input).historical.source, 'Seeded historical weather example');
});
