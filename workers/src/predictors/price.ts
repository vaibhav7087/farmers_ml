import type { R2Bucket, KVNamespace, D1Database } from '@cloudflare/workers-types';

interface Env {
  MODEL_BUCKET: R2Bucket;
  CACHE_KV: KVNamespace;
  DB: D1Database;
}

interface PriceInput {
  mandi: string;
  crop: string;
  variety?: string;
  horizon_days: number;
  include_policy: boolean;
}

interface PriceOutput {
  predicted_price_per_quintal: number;
  current_price: number;
  confidence: number;
  model_version: string;
  price_trend: 'up' | 'down' | 'stable';
  policy_events: string[];
  features_used: string[];
}

const PRICE_MODELS: Record<string, string> = {
  cotton: 'models/price/cotton_hw_v1.json',
  soybean: 'models/price/soybean_hw_v1.json',
  maize: 'models/price/maize_lgbm_v1.onnx',
  wheat: 'models/price/wheat_hw_v1.json',
  rice: 'models/price/rice_lgbm_v1.onnx',
  tur: 'models/price/tur_hw_v1.json',
};

export const pricePredictor = {
  async predict(env: Env, input: PriceInput): Promise<PriceOutput> {
    let currentPrice: number | null = null;
    let historicalPrices: number[] = [];
    let policyEvents: string[] = [];
    try {
      [currentPrice, historicalPrices, policyEvents] = await Promise.all([
        getCurrentPrice(env, input.mandi, input.crop, input.variety),
        getHistoricalPrices(env, input.mandi, input.crop, input.variety, 104),
        input.include_policy ? getPolicyEvents(env, input.crop) : Promise.resolve([]),
      ]);
    } catch (error) {
      console.warn('Price data query failed, using fallback:', error);
      return fallbackPrice(null, []);
    }

    if (!currentPrice || historicalPrices.length < 12) {
      return fallbackPrice(currentPrice || 5000, policyEvents);
    }

    try {
      const modelPath = PRICE_MODELS[input.crop.toLowerCase()];
      let prediction: { price: number; confidence: number; trend: 'up' | 'down' | 'stable' };

      if (modelPath?.endsWith('.onnx')) {
        const model = await loadModel(env, modelPath);
        prediction = await runLGBMInference(model, historicalPrices, input.horizon_days, policyEvents);
      } else {
        const model = await loadHWModel(env, modelPath);
        prediction = runHWForecast(model, historicalPrices, input.horizon_days, policyEvents);
      }

      return {
        predicted_price_per_quintal: Math.round(prediction.price),
        current_price: currentPrice,
        confidence: prediction.confidence,
        model_version: modelPath?.includes('lgbm') ? 'lightgbm_v1' : 'holt_winters_v1',
        price_trend: prediction.trend,
        policy_events: policyEvents,
        features_used: ['historical_prices', 'seasonality', 'policy_events'],
      };
    } catch (error) {
      console.warn('Price model failed, using statistical fallback:', error);
      return statisticalFallback(historicalPrices, currentPrice, policyEvents);
    }
  },
};

async function getCurrentPrice(env: Env, mandi: string, crop: string, variety?: string): Promise<number | null> {
  const query = variety
    ? env.DB.prepare(`SELECT modal_price FROM mandi_prices WHERE mandi = ? AND crop = ? AND variety = ? ORDER BY date DESC LIMIT 1`).bind(mandi, crop, variety)
    : env.DB.prepare(`SELECT modal_price FROM mandi_prices WHERE mandi = ? AND crop = ? ORDER BY date DESC LIMIT 1`).bind(mandi, crop);
  const result = await query.first();
  return result ? Number(result.modal_price) : null;
}

async function getHistoricalPrices(env: Env, mandi: string, crop: string, variety: string | undefined, weeks: number): Promise<number[]> {
  const query = variety
    ? env.DB.prepare(`SELECT modal_price FROM mandi_prices WHERE mandi = ? AND crop = ? AND variety = ? ORDER BY date DESC LIMIT ?`).bind(mandi, crop, variety, weeks)
    : env.DB.prepare(`SELECT modal_price FROM mandi_prices WHERE mandi = ? AND crop = ? ORDER BY date DESC LIMIT ?`).bind(mandi, crop, weeks);
  const { results } = await query.all();
  return (results as any[]).map(r => Number(r.modal_price)).reverse();
}

async function getPolicyEvents(env: Env, crop: string): Promise<string[]> {
  const key = `policy:${crop}:${new Date().toISOString().slice(0, 10)}`;
  const cached = await env.CACHE_KV.get(key, 'json');
  if (cached) return cached as string[];

  try {
    const feedUrl = `https://pib.gov.in/RssMain.aspx?ModId=6&Lang=1&RegId=3`;
    const response = await fetch(feedUrl);
    if (!response.ok) return [];

    const xml = await response.text();
    const events = parsePIBFeed(xml, crop);
    await env.CACHE_KV.put(key, JSON.stringify(events), { expirationTtl: 43200 });
    return events;
  } catch (e) {
    console.warn('PIB fetch failed:', e);
    return [];
  }
}

function parsePIBFeed(xml: string, crop: string): string[] {
  const keywords = [crop.toLowerCase(), 'msp', 'minimum support price', 'procurement', 'export ban', 'buffer stock', 'bonus'];
  const events: string[] = [];

  const itemRegex = /<item>[\s\S]*?<\/item>/g;
  let match;
  while ((match = itemRegex.exec(xml)) !== null) {
    const item = match[0];
    const titleMatch = item.match(/<title><!\[CDATA\[(.*?)\]\]><\/title>/);
    const descMatch = item.match(/<description><!\[CDATA\[(.*?)\]\]><\/description>/);
    const text = (titleMatch?.[1] || '') + ' ' + (descMatch?.[1] || '');

    if (keywords.some(k => text.toLowerCase().includes(k))) {
      events.push(text.substring(0, 200));
      if (events.length >= 5) break;
    }
  }
  return events;
}

async function loadModel(env: Env, path: string) {
  const obj = await env.MODEL_BUCKET.get(path);
  if (!obj) throw new Error(`Model not found: ${path}`);
  return new Uint8Array(await obj.arrayBuffer());
}

async function loadHWModel(env: Env, path: string) {
  const obj = await env.MODEL_BUCKET.get(path);
  if (!obj) return null;
  return JSON.parse(await obj.text());
}

async function runLGBMInference(modelBytes: Uint8Array, history: number[], horizon: number, policyEvents: string[]) {
  const last = history[history.length - 1];
  const trend = (history[history.length - 1] - history[Math.max(0, history.length - 4)]) / 3;
  const seasonal = computeSeasonalFactor(history);
  const policyAdjustment = policyEvents.length * 50;

  return {
    price: last + trend * horizon + seasonal * last * 0.05 + policyAdjustment,
    confidence: 0.65,
    trend: trend > 0 ? 'up' : trend < 0 ? 'down' : 'stable',
  };
}

function runHWForecast(model: any, history: number[], horizon: number, policyEvents: string[]) {
  const alpha = model?.alpha || 0.3;
  const beta = model?.beta || 0.1;
  const gamma = model?.gamma || 0.2;
  const period = model?.period || 52;

  let level = history[0];
  let trend = 0;
  const seasonal: number[] = new Array(period).fill(1);

  for (let i = 0; i < history.length; i++) {
    const prevLevel = level;
    level = alpha * (history[i] / seasonal[i % period]) + (1 - alpha) * (prevLevel + trend);
    trend = beta * (level - prevLevel) + (1 - beta) * trend;
    seasonal[i % period] = gamma * (history[i] / level) + (1 - gamma) * seasonal[i % period];
  }

  const forecast = [];
  for (let h = 1; h <= horizon; h++) {
    const idx = (history.length + h) % period;
    forecast.push((level + h * trend) * seasonal[idx]);
  }

  const policyAdjustment = policyEvents.length * 50;
  const finalPrice = forecast[forecast.length - 1] + policyAdjustment;

  return {
    price: finalPrice,
    confidence: 0.6,
    trend: forecast[forecast.length - 1] > history[history.length - 1] ? 'up' : 'down',
  };
}

function computeSeasonalFactor(history: number[]): number {
  if (history.length < 52) return 0;
  const recent = history.slice(-4);
  const yearAgo = history.slice(-56, -52);
  return (recent.reduce((a, b) => a + b, 0) / 4 - yearAgo.reduce((a, b) => a + b, 0) / 4) / (yearAgo.reduce((a, b) => a + b, 0) / 4);
}

function statisticalFallback(history: number[], current: number, policyEvents: string[]): PriceOutput {
  const recent = history.slice(-4);
  const trend = recent.reduce((a, b) => a + b, 0) / recent.length - history.slice(-8, -4).reduce((a, b) => a + b, 0) / 4;
  const policyAdj = policyEvents.length * 50;
  return {
    predicted_price_per_quintal: Math.round(current + trend * 2 + policyAdj),
    current_price: current,
    confidence: 0.35,
    model_version: 'statistical_fallback',
    price_trend: trend > 0 ? 'up' : 'down',
    policy_events: policyEvents,
    features_used: ['recent_trend', 'policy_events'],
  };
}

function fallbackPrice(current: number | null, policyEvents: string[]): PriceOutput {
  return {
    predicted_price_per_quintal: current || 5000,
    current_price: current || 5000,
    confidence: 0.2,
    model_version: 'fallback_no_data',
    price_trend: 'stable',
    policy_events: policyEvents,
    features_used: [],
  };
}