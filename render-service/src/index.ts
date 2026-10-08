import { Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';
import { trainingWorker } from './workers/training';
import { inferenceWorker } from './workers/inference';
import { satelliteWorker } from './workers/satellite';
import { registerRoutes } from './routes';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import websocket from '@fastify/websocket';

async function main() {
  // Create workers first
  const redisForWorkers = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', {
    maxRetriesPerRequest: 3,
    retryStrategy: (times) => Math.min(times * 100, 3000),
  });

  // Training workers
  new Worker('training', async (job) => {
    const data = job.data as { crop: string; district?: string; season?: 'kharif' | 'rabi' | 'summer'; modelType?: 'lightgbm' | 'xgboost' | 'catboost'; forceRetrain: boolean };
    const { crop, district, season, modelType } = data;

    try {
      const result = await trainingWorker.trainYield({ crop, district, season, modelType, forceRetrain: true });
      return result;
    } catch (error) {
      throw error;
    }
  }, { connection: new IORedis(process.env.REDIS_URL || 'redis://localhost:6379') });

  new Worker('training', async (job) => {
    const data = job.data as { crop: string; mandi?: string; variety?: string; modelType?: 'holt_winters' | 'lightgbm' | 'prophet'; forceRetrain: boolean };
    const { crop, mandi, variety, modelType } = data;

    try {
      const result = await trainingWorker.trainPrice({ crop, mandi, variety, modelType, forceRetrain: true });
      return result;
    } catch (error) {
      throw error;
    }
  }, { connection: new IORedis(process.env.REDIS_URL || 'redis://localhost:6379') });

  // Inference worker
  new Worker('inference', async (job) => {
    const data = job.data as { requests: Array<{ type: 'yield' | 'price'; payload: Record<string, unknown> }> };
    const { requests } = data;
    const results = await Promise.all(
      requests.map(req => inferenceWorker.predict(req))
    );
    return results;
  }, { connection: new IORedis(process.env.REDIS_URL || 'redis://localhost:6379') });

  // Satellite worker
  new Worker('satellite', async (job) => {
    const data = job.data as { district: string; crop: string; startDate?: string; endDate?: string };
    const { district, crop, startDate, endDate } = data;

    try {
      const result = await satelliteWorker.fetchAndProcess(district, crop, startDate, endDate);
      return result;
    } catch (error) {
      throw error;
    }
  }, { connection: new IORedis(process.env.REDIS_URL || 'redis://localhost:6379') });

  // Fastify server
  const fastify = Fastify({
    logger: { level: 'info' },
  });

  const redis = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', {
    maxRetriesPerRequest: 3,
    retryStrategy: (times) => Math.min(times * 100, 3000),
  });

  const trainingJobQueue = new Queue('training', { connection: redis });
  const inferenceJobQueue = new Queue('inference', { connection: redis });
  const satelliteJobQueue = new Queue('satellite', { connection: redis });

  await fastify.register(cors, {
    origin: ['https://kisaan-ml.pages.dev', 'http://localhost:3000', 'https://*.onrender.com'],
    credentials: true,
  });

  await fastify.register(websocket);

  registerRoutes(fastify, {
    trainingQueue: trainingJobQueue,
    inferenceQueue: inferenceJobQueue,
    satelliteQueue: satelliteJobQueue,
  });

  fastify.get('/health', async () => ({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    queues: {
      training: await trainingJobQueue.getJobCounts(),
      inference: await inferenceJobQueue.getJobCounts(),
      satellite: await satelliteJobQueue.getJobCounts(),
    },
  }));

  const PORT = parseInt(process.env.PORT || '8080', 10);
  const HOST = process.env.HOST || '0.0.0.0';

  try {
    await fastify.listen({ port: PORT, host: HOST });
    console.log(`Render service listening on ${HOST}:${PORT}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }

  process.on('SIGTERM', async () => {
    await fastify.close();
    await redis.quit();
    process.exit(0);
  });
}

main().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});