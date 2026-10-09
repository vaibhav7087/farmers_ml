const { test } = require('node:test');
const assert = require('node:assert/strict');
const Fastify = require('fastify');
const { registerRoutes } = require('../dist/routes');

test('training routes validate input and preserve the job type', async () => {
  const server = Fastify();
  const calls = [];
  const queue = { add: async (name, data) => { calls.push({ name, data }); return { id: '42' }; } };
  registerRoutes(server, { trainingQueue: queue, inferenceQueue: queue, satelliteQueue: queue });
  try {
    const invalid = await server.inject({ method: 'POST', url: '/api/v1/train/yield', payload: {} });
    assert.equal(invalid.statusCode, 400);
    assert.equal(calls.length, 0);
    const yieldJob = await server.inject({ method: 'POST', url: '/api/v1/train/yield', payload: { crop: 'cotton' } });
    assert.equal(yieldJob.statusCode, 200);
    assert.equal(yieldJob.json().jobId, '42');
    assert.equal(calls[0].name, 'train-yield');
    assert.equal(calls[0].data.modelType, 'lightgbm');
    const priceJob = await server.inject({ method: 'POST', url: '/api/v1/train/price', payload: { crop: 'cotton' } });
    assert.equal(priceJob.statusCode, 200);
    assert.equal(calls[1].name, 'train-price');
    assert.equal(calls[1].data.modelType, 'holt_winters');
  } finally { await server.close(); }
});

test('batch inference rejects empty batches and queues valid requests', async () => {
  const server = Fastify();
  const calls = [];
  const queue = { add: async (name, data) => { calls.push({ name, data }); return { id: '7' }; } };
  registerRoutes(server, { trainingQueue: queue, inferenceQueue: queue, satelliteQueue: queue });
  try {
    const invalid = await server.inject({ method: 'POST', url: '/api/v1/inference/batch', payload: { requests: [] } });
    assert.equal(invalid.statusCode, 400);
    const valid = await server.inject({ method: 'POST', url: '/api/v1/inference/batch', payload: { requests: [{ type: 'yield', payload: { crop: 'cotton' } }] } });
    assert.equal(valid.statusCode, 200);
    assert.equal(valid.json().count, 1);
    assert.equal(calls[0].name, 'batch-inference');
  } finally { await server.close(); }
});
