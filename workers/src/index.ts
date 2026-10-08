import { Hono } from 'hono';
import { z } from 'zod';
import { cors } from 'hono/cors';
import { yieldPredictor } from './predictors/yield';
import { pricePredictor } from './predictors/price';
import { healthCheck } from './utils/health';
import { cacheGet, cacheSet } from './utils/cache';

type Bindings = {
  MODEL_BUCKET: R2Bucket;
  CACHE_KV: KVNamespace;
  DB: D1Database;
  ENVIRONMENT: string;
};

const app = new Hono<{ Bindings: Bindings }>();

app.use('*', cors({
  origin: ['https://kisaan-ml.pages.dev', 'http://localhost:3000', 'https://*.onrender.com'],
  allowMethods: ['GET', 'POST', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

app.get('/health', (c) => healthCheck(c));

const yieldQuerySchema = z.object({
  district: z.string().min(1),
  crop: z.string().min(1),
  season: z.enum(['kharif', 'rabi', 'summer']).optional(),
  sowing_week: z.coerce.number().int().min(1).max(52).optional(),
  use_satellite: z.coerce.boolean().optional(),
});

app.get('/api/v1/predict/yield', async (c) => {
  const query = yieldQuerySchema.safeParse(c.req.query());
  if (!query.success) {
    return c.json({ error: 'Invalid query', details: query.error.flatten() }, 400);
  }

  const cacheKey = `yield:${query.data.district}:${query.data.crop}:${query.data.season || 'all'}:${query.data.sowing_week || 'auto'}:${query.data.use_satellite || false}`;
  const cached = await cacheGet(c.env.CACHE_KV, cacheKey);
  if (cached) {
    return c.json({ ...cached, cached: true });
  }

  try {
    const result = await yieldPredictor.predict(c.env, query.data);
    await cacheSet(c.env.CACHE_KV, cacheKey, result, 3600);
    return c.json({ ...result, cached: false });
  } catch (error) {
    console.error('Yield prediction error:', error);
    return c.json({ error: 'Prediction failed', message: error instanceof Error ? error.message : 'Unknown error' }, 500);
  }
});

const priceQuerySchema = z.object({
  mandi: z.string().min(1),
  crop: z.string().min(1),
  variety: z.string().optional(),
  horizon_days: z.coerce.number().int().min(1).max(30).default(14),
  include_policy: z.coerce.boolean().default(true),
});

app.get('/api/v1/predict/price', async (c) => {
  const query = priceQuerySchema.safeParse(c.req.query());
  if (!query.success) {
    return c.json({ error: 'Invalid query', details: query.error.flatten() }, 400);
  }

  const cacheKey = `price:${query.data.mandi}:${query.data.crop}:${query.data.variety || 'all'}:${query.data.horizon_days}:${query.data.include_policy}`;
  const cached = await cacheGet(c.env.CACHE_KV, cacheKey);
  if (cached) {
    return c.json({ ...cached, cached: true });
  }

  try {
    const result = await pricePredictor.predict(c.env, query.data);
    await cacheSet(c.env.CACHE_KV, cacheKey, result, 1800);
    return c.json({ ...result, cached: false });
  } catch (error) {
    console.error('Price prediction error:', error);
    return c.json({ error: 'Prediction failed', message: error instanceof Error ? error.message : 'Unknown error' }, 500);
  }
});

const advisorySchema = z.object({
  district: z.string().min(1),
  crop: z.string().min(1),
  mandi: z.string().min(1),
  variety: z.string().optional(),
  sowing_week: z.coerce.number().int().min(1).max(52).optional(),
});

app.post('/api/v1/advisory', async (c) => {
  const body = await c.req.json();
  const parsed = advisorySchema.safeParse(body);
  if (!parsed.success) {
    return c.json({ error: 'Invalid body', details: parsed.error.flatten() }, 400);
  }

  const [yieldResult, priceResult] = await Promise.all([
    yieldPredictor.predict(c.env, {
      district: parsed.data.district,
      crop: parsed.data.crop,
      sowing_week: parsed.data.sowing_week,
      use_satellite: true,
    }),
    pricePredictor.predict(c.env, {
      mandi: parsed.data.mandi,
      crop: parsed.data.crop,
      variety: parsed.data.variety,
      horizon_days: 14,
      include_policy: true,
    }),
  ]);

  const advisory = generateAdvisory(yieldResult, priceResult, parsed.data);
  return c.json(advisory);
});

app.get('/api/v1/districts', async (c) => {
  const cached = await cacheGet(c.env.CACHE_KV, 'districts:list');
  if (cached) return c.json(cached);

  const { results } = await c.env.DB.prepare(
    `SELECT DISTINCT district, state FROM soil_health WHERE district IS NOT NULL ORDER BY state, district`
  ).all();

  const districts = results.map((r: any) => ({ district: r.district, state: r.state }));
  await cacheSet(c.env.CACHE_KV, 'districts:list', districts, 86400);
  return c.json({ districts });
});

app.get('/api/v1/mandis', async (c) => {
  const state = c.req.query('state');
  const query = state
    ? c.env.DB.prepare(`SELECT DISTINCT mandi, state, crop FROM mandi_prices WHERE state = ? ORDER BY mandi`).bind(state)
    : c.env.DB.prepare(`SELECT DISTINCT mandi, state, crop FROM mandi_prices ORDER BY state, mandi`);

  const { results } = await query.all();
  return c.json({ mandis: results });
});

app.get('/api/v1/crops', async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT DISTINCT crop FROM mandi_prices UNION SELECT DISTINCT crop FROM soil_health ORDER BY crop`
  ).all();
  return c.json({ crops: results.map((r: any) => r.crop) });
});

function generateAdvisory(yieldResult: any, priceResult: any, input: any) {
  const yieldKgPerHa = yieldResult.predicted_yield_kg_per_ha;
  const pricePerQuintal = priceResult.predicted_price_per_quintal;
  const grossRevenue = (yieldKgPerHa / 100) * pricePerQuintal;
  const inputCost = estimateInputCost(input.crop, yieldKgPerHa);
  const netProfit = grossRevenue - inputCost;

  return {
    district: input.district,
    crop: input.crop,
    mandi: input.mandi,
    predictions: {
      yield: { value: yieldKgPerHa, unit: 'kg/ha', confidence: yieldResult.confidence },
      price: { value: pricePerQuintal, unit: 'INR/quintal', confidence: priceResult.confidence },
    },
    economics: {
      gross_revenue_inr_per_ha: Math.round(grossRevenue),
      estimated_input_cost_inr_per_ha: inputCost,
      estimated_net_profit_inr_per_ha: Math.round(netProfit),
    },
    recommendations: generateRecommendations(yieldResult, priceResult, input),
    generated_at: new Date().toISOString(),
  };
}

function estimateInputCost(crop: string, yieldKg: number): number {
  const baseCosts: Record<string, number> = {
    cotton: 35000,
    soybean: 25000,
    maize: 20000,
    wheat: 22000,
    rice: 30000,
    tur: 18000,
  };
  return baseCosts[crop] || 25000;
}

function generateRecommendations(yieldResult: any, priceResult: any, input: any): string[] {
  const recs: string[] = [];
  if (yieldResult.confidence < 0.6) recs.push('Low yield confidence — consider soil test before major investment');
  if (priceResult.confidence < 0.6) recs.push('Price forecast uncertain — monitor mandi arrivals weekly');
  if (yieldResult.predicted_yield_kg_per_ha > 2500) recs.push('High yield expected — ensure storage/logistics ready');
  if (priceResult.predicted_price_per_quintal > priceResult.current_price * 1.1) recs.push('Price upside expected — consider holding 2-3 weeks');
  if (priceResult.policy_events?.length) recs.push(`Policy alert: ${priceResult.policy_events[0]}`);
  return recs.length ? recs : ['Proceed with standard plan — monitor weekly'];
}

export default app;