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
  if (!process.env.REDIS_URL) throw new Error('REDIS_URL is required. Connect a Render Key Value instance.');
  const fastify = Fastify({ logger: { level: process.env.LOG_LEVEL || 'info' } });
  const connections: IORedis[] = [];
  const connect = (worker = false) => {
    const redis = new IORedis(process.env.REDIS_URL!, {
      maxRetriesPerRequest: worker ? null : 3,
      retryStrategy: times => Math.min(times * 100, 3000),
    });
    redis.on('error', err => fastify.log.error({ err }, 'Redis connection error'));
    connections.push(redis);
    return redis;
  };
  const redis = connect();
  // BullMQ owns a separately resolved ioredis dependency. Pass connection options
  // rather than an instance to keep its TypeScript types compatible.
  const redisUrl = new URL(process.env.REDIS_URL);
  const workerConnection = {
    host: redisUrl.hostname,
    port: Number(redisUrl.port || 6379),
    username: redisUrl.username ? decodeURIComponent(redisUrl.username) : undefined,
    password: redisUrl.password ? decodeURIComponent(redisUrl.password) : undefined,
    db: Number(redisUrl.pathname.slice(1) || 0),
    tls: redisUrl.protocol === 'rediss:' ? {} : undefined,
    maxRetriesPerRequest: null,
  };
  const workers = [
    new Worker('training', async job => {
      if (job.name === 'train-yield') return trainingWorker.trainYield(job.data);
      if (job.name === 'train-price') return trainingWorker.trainPrice(job.data);
      throw new Error(`Unknown training job: ${job.name}`);
    }, { connection: workerConnection }),
    new Worker('inference', async job => Promise.all(
      job.data.requests.map((request: any) => inferenceWorker.predict(request))
    ), { connection: workerConnection }),
    new Worker('satellite', async job => satelliteWorker.fetchAndProcess(
      job.data.district, job.data.crop, job.data.startDate, job.data.endDate
    ), { connection: workerConnection }),
  ];
  workers.forEach(worker => worker.on('error', err => fastify.log.error({ err }, 'Queue worker error')));
  const queues = {
    trainingQueue: new Queue('training', { connection: { ...workerConnection, maxRetriesPerRequest: 3 } }),
    inferenceQueue: new Queue('inference', { connection: { ...workerConnection, maxRetriesPerRequest: 3 } }),
    satelliteQueue: new Queue('satellite', { connection: { ...workerConnection, maxRetriesPerRequest: 3 } }),
  };
  await fastify.register(cors, {
    origin: ['https://kisaan-ml.pages.dev', 'http://localhost:3000', /^https:\/\/[a-z0-9-]+\.onrender\.com$/],
    credentials: true,
  });
  await fastify.register(websocket);
  registerRoutes(fastify, queues);
  fastify.get('/', async () => ({
    service: 'Kisaan-ML Render API',
    health: '/health',
    queueStats: '/api/v1/queues/stats',
    notice: 'Backend service only. ML training, prediction and satellite processing contain placeholders.',
  }));
  fastify.get('/health', async (_request, reply) => {
    try {
      await redis.ping();
      const [training, inference, satellite] = await Promise.all(
        Object.values(queues).map(queue => queue.getJobCounts())
      );
      return { status: 'healthy', timestamp: new Date().toISOString(), queues: { training, inference, satellite } };
    } catch (err) {
      fastify.log.error({ err }, 'Health check failed');
      return reply.status(503).send({ status: 'unhealthy', error: 'Redis unavailable' });
    }
  });
  await fastify.listen({ port: Number(process.env.PORT || 8080), host: process.env.HOST || '0.0.0.0' });
  let stopping = false;
  const shutdown = async () => {
    if (stopping) return;
    stopping = true;
    await fastify.close();
    await Promise.all(workers.map(worker => worker.close()));
    await Promise.all(Object.values(queues).map(queue => queue.close()));
    await Promise.all(connections.map(connection => connection.quit()));
  };
  process.on('SIGTERM', () => shutdown().catch(err => { fastify.log.error(err); process.exit(1); }));
  process.on('SIGINT', () => shutdown().catch(err => { fastify.log.error(err); process.exit(1); }));
}
main().catch(err => { console.error('Failed to start server:', err); process.exit(1); });
