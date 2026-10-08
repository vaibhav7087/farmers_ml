import type { KVNamespace, D1Database, R2Bucket } from '@cloudflare/workers-types';

interface Bindings {
  CACHE_KV: KVNamespace;
  DB: D1Database;
  MODEL_BUCKET: R2Bucket;
  ENVIRONMENT: string;
}

export async function healthCheck(c: any) {
  const checks = {
    timestamp: new Date().toISOString(),
    environment: c.env.ENVIRONMENT,
    kv: false,
    db: false,
    r2: false,
    version: '0.1.0',
  };

  try {
    await c.env.CACHE_KV.put('health:check', 'ok', { expirationTtl: 60 });
    const val = await c.env.CACHE_KV.get('health:check');
    checks.kv = val === 'ok';
  } catch {}

  try {
    await c.env.DB.prepare('SELECT 1').first();
    checks.db = true;
  } catch {}

  try {
    await c.env.MODEL_BUCKET.head('health/check');
    checks.r2 = true;
  } catch {}

  const healthy = checks.kv && checks.db && checks.r2;
  return c.json({ status: healthy ? 'healthy' : 'degraded', checks }, healthy ? 200 : 503);
}