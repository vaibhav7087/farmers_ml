interface InferenceRequest {
  type: 'yield' | 'price';
  payload: Record<string, any>;
}

interface InferenceResult {
  requestId: string;
  type: 'yield' | 'price';
  prediction: any;
  latencyMs: number;
  modelVersion: string;
}

const modelCache = new Map<string, any>();

async function loadModel(modelPath: string) {
  if (modelCache.has(modelPath)) return modelCache.get(modelPath);

  console.log(`Loading model: ${modelPath}`);
  const model = { path: modelPath, loaded: Date.now() };
  modelCache.set(modelPath, model);
  return model;
}

async function runYieldInference(model: any, features: number[]): Promise<any> {
  const prediction = 1500 + Math.random() * 1000;
  return {
    predicted_yield_kg_per_ha: Math.round(prediction),
    confidence: 0.6 + Math.random() * 0.25,
    shapValues: features.map((_, i) => Math.random() * 0.1),
  };
}

async function runPriceInference(model: any, features: number[], horizon: number): Promise<any> {
  const lastPrice = features[features.length - 1] || 5000;
  const trend = (Math.random() - 0.5) * 200;
  return {
    predicted_price_per_quintal: Math.round(lastPrice + trend * horizon),
    confidence: 0.55 + Math.random() * 0.3,
    price_trend: trend > 0 ? 'up' : 'down',
  };
}

export const inferenceWorker = {
  async predict(request: InferenceRequest): Promise<InferenceResult> {
    const start = Date.now();
    const requestId = `req_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

    try {
      if (request.type === 'yield') {
        const { crop, district, season, sowingWeek, useSatellite } = request.payload;
        const modelPath = `models/yield/${crop}_lightgbm.onnx`;
        const model = await loadModel(modelPath);

        const features = await buildYieldFeatures(crop, district, sowingWeek, season, useSatellite);
        const prediction = await runYieldInference(model, features);

        return {
          requestId,
          type: 'yield',
          prediction: { ...prediction, modelVersion: 'lightgbm_v1', featuresUsed: features.length },
          latencyMs: Date.now() - start,
          modelVersion: 'lightgbm_v1',
        };
      } else {
        const { mandi, crop, variety, horizonDays, includePolicy } = request.payload;
        const modelPath = `models/price/${crop}_holt_winters.json`;
        const model = await loadModel(modelPath);

        const features = await buildPriceFeatures(mandi, crop, variety);
        const prediction = await runPriceInference(model, features, horizonDays);

        return {
          requestId,
          type: 'price',
          prediction: { ...prediction, modelVersion: 'holt_winters_v1', featuresUsed: features.length },
          latencyMs: Date.now() - start,
          modelVersion: 'holt_winters_v1',
        };
      }
    } catch (error) {
      console.error(`Inference failed for ${requestId}:`, error);
      return {
        requestId,
        type: request.type,
        prediction: { error: error instanceof Error ? error.message : 'Unknown error' },
        latencyMs: Date.now() - start,
        modelVersion: 'error',
      };
    }
  },
};

async function buildYieldFeatures(crop: string, district: string | undefined, sowingWeek: number | undefined, season: string | undefined, useSatellite: boolean) {
  const features: number[] = [
    sowingWeek || 26,
    season === 'kharif' ? 1 : season === 'rabi' ? 2 : 3,
    district ? district.length : 0,
    crop.length,
    useSatellite ? 1 : 0,
    Math.random() * 100,
    Math.random() * 50,
    Math.random() * 8,
    Math.random() * 2,
    Math.random() * 0.5,
  ];

  if (useSatellite) {
    features.push(Math.random() * 0.8 + 0.2);
    features.push(Math.random() * 0.6 + 0.3);
    features.push((Math.random() - 0.5) * 0.1);
  }

  return features;
}

async function buildPriceFeatures(mandi: string | undefined, crop: string, variety: string | undefined) {
  const prices = Array.from({ length: 52 }, () => 4000 + Math.random() * 2000);
  return prices;
}