import { FastifyInstance } from 'fastify';
import { Queue } from 'bullmq';
import { z } from 'zod';

interface Queues {
  trainingQueue: Queue;
  inferenceQueue: Queue;
  satelliteQueue: Queue;
}

export function registerRoutes(fastify: FastifyInstance, queues: Queues) {
  const { trainingQueue, inferenceQueue, satelliteQueue } = queues;

  // The Flutter app uses these endpoints, but no real advisory models have
  // been integrated into this backend. Report that explicitly.
  const modelUnavailable = async (_req: any, reply: any) => reply.status(503).send({
    error: 'Models not configured',
    message: 'Real crop advisory is unavailable until trained models and data are integrated. This deployment is a demo.',
  });
  fastify.post('/api/v1/advisory', modelUnavailable);
  fastify.get('/api/v1/predict/yield', modelUnavailable);
  fastify.get('/api/v1/predict/price', modelUnavailable);

  fastify.post('/api/v1/train/yield', async (req, reply) => {
    const schema = z.object({
      crop: z.string().min(1),
      district: z.string().optional(),
      season: z.enum(['kharif', 'rabi', 'summer']).optional(),
      modelType: z.enum(['lightgbm', 'xgboost', 'catboost']).default('lightgbm'),
      forceRetrain: z.boolean().default(false),
    });

    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid body', details: parsed.error.flatten() });
    }

    const job = await trainingQueue.add('train-yield', parsed.data, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 5000 },
      removeOnComplete: 50,
      removeOnFail: 20,
    });

    return { jobId: job.id, status: 'queued', message: `Training job queued for ${parsed.data.crop}` };
  });

  fastify.post('/api/v1/train/price', async (req, reply) => {
    const schema = z.object({
      crop: z.string().min(1),
      mandi: z.string().optional(),
      variety: z.string().optional(),
      modelType: z.enum(['holt_winters', 'lightgbm', 'prophet']).default('holt_winters'),
      forceRetrain: z.boolean().default(false),
    });

    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid body', details: parsed.error.flatten() });
    }

    const job = await trainingQueue.add('train-price', parsed.data, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 5000 },
      removeOnComplete: 50,
      removeOnFail: 20,
    });

    return { jobId: job.id, status: 'queued', message: `Price training job queued for ${parsed.data.crop}` };
  });

  fastify.get('/api/v1/train/status/:jobId', async (req, reply) => {
    const { jobId } = req.params as { jobId: string };
    const job = await trainingQueue.getJob(jobId);
    if (!job) {
      return reply.status(404).send({ error: 'Job not found' });
    }
    const state = await job.getState();
    const progress = job.progress;
    return { jobId, state, progress };
  });

  fastify.post('/api/v1/inference/batch', async (req, reply) => {
    const schema = z.object({
      requests: z.array(z.object({
        type: z.enum(['yield', 'price']),
        payload: z.record(z.any()),
      })).min(1).max(100),
    });

    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid body', details: parsed.error.flatten() });
    }

    const job = await queues.inferenceQueue.add('batch-inference', { requests: parsed.data.requests }, {
      attempts: 2,
      removeOnComplete: 100,
      removeOnFail: 50,
    });

    return { jobId: job.id, status: 'queued', count: parsed.data.requests.length };
  });

  fastify.post('/api/v1/satellite/fetch', async (req, reply) => {
    const schema = z.object({
      district: z.string().min(1),
      crop: z.string().min(1),
      startDate: z.string().datetime().optional(),
      endDate: z.string().datetime().optional(),
    });

    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid body', details: parsed.error.flatten() });
    }

    const job = await satelliteQueue.add('fetch-satellite', parsed.data, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 10000 },
      removeOnComplete: 20,
      removeOnFail: 10,
    });

    return { jobId: job.id, status: 'queued', message: `Satellite fetch queued for ${parsed.data.district}` };
  });

  fastify.get('/api/v1/queues/stats', async () => {
    const [trainingCounts, inferenceCounts, satelliteCounts] = await Promise.all([
      queues.trainingQueue.getJobCounts(),
      queues.inferenceQueue.getJobCounts(),
      queues.satelliteQueue.getJobCounts(),
    ]);
    return { training: trainingCounts, inference: inferenceCounts, satellite: satelliteCounts };
  });

  fastify.post('/api/v1/retrain/all', async () => {
    const crops = ['cotton', 'soybean', 'maize', 'wheat', 'rice', 'tur'];
    const jobs = await Promise.all(
      crops.map(crop => trainingQueue.add('train-yield', { crop, modelType: 'lightgbm', forceRetrain: true }))
    );
    return { message: 'Full retrain queued for all crops', jobIds: jobs.map(j => j.id) };
  });
}
