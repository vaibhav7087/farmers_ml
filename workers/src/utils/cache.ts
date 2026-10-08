import type { KVNamespace } from '@cloudflare/workers-types';

export async function cacheGet(kv: KVNamespace, key: string): Promise<any | null> {
  try {
    const value = await kv.get(key, 'json');
    return value;
  } catch {
    return null;
  }
}

export async function cacheSet(kv: KVNamespace, key: string, value: any, ttlSeconds: number): Promise<void> {
  try {
    await kv.put(key, JSON.stringify(value), { expirationTtl: ttlSeconds });
  } catch (e) {
    console.warn('Cache set failed:', e);
  }
}

export async function cacheDelete(kv: KVNamespace, key: string): Promise<void> {
  try {
    await kv.delete(key);
  } catch (e) {
    console.warn('Cache delete failed:', e);
  }
}

export function cacheKey(prefix: string, ...parts: (string | number)[]): string {
  return `${prefix}:${parts.join(':')}`;
}