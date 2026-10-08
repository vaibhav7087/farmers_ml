-- Kisaan-ML Database Initialization
-- Run on PostgreSQL startup

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Districts table
CREATE TABLE IF NOT EXISTS districts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    min_lon DOUBLE PRECISION,
    min_lat DOUBLE PRECISION,
    max_lon DOUBLE PRECISION,
    max_lat DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_districts_state ON districts(state);
CREATE INDEX IF NOT EXISTS idx_districts_name ON districts(name);

-- Mandis table
CREATE TABLE IF NOT EXISTS mandis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    district_id UUID REFERENCES districts(id),
    state VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mandis_district ON mandis(district_id);
CREATE INDEX IF NOT EXISTS idx_mandis_state ON mandis(state);

-- Soil Health Card data (district-level aggregates)
CREATE TABLE IF NOT EXISTS soil_health (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    block VARCHAR(100),
    village VARCHAR(200),
    year INTEGER NOT NULL,
    season VARCHAR(20), -- kharif, rabi, summer
    ph DOUBLE PRECISION,
    ec DOUBLE PRECISION,
    oc DOUBLE PRECISION,
    n DOUBLE PRECISION,      -- Nitrogen (kg/ha)
    p DOUBLE PRECISION,      -- Phosphorus (kg/ha)
    k DOUBLE PRECISION,      -- Potassium (kg/ha)
    s DOUBLE PRECISION,      -- Sulphur
    zn DOUBLE PRECISION,     -- Zinc
    fe DOUBLE PRECISION,     -- Iron
    cu DOUBLE PRECISION,     -- Copper
    mn DOUBLE PRECISION,     -- Manganese
    b DOUBLE PRECISION,      -- Boron
    sample_count INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_soil_district_year ON soil_health(district, year);
CREATE INDEX IF NOT EXISTS idx_soil_state ON soil_health(state);

-- Weather history (from IMD gridded data)
CREATE TABLE IF NOT EXISTS weather_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    district VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    week INTEGER NOT NULL,
    year INTEGER NOT NULL,
    temp_avg DOUBLE PRECISION,
    temp_max DOUBLE PRECISION,
    temp_min DOUBLE PRECISION,
    rainfall DOUBLE PRECISION,
    humidity_avg DOUBLE PRECISION,
    wind_speed DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weather_district_date ON weather_history(district, date);
CREATE INDEX IF NOT EXISTS idx_weather_year_week ON weather_history(year, week);

-- Mandi prices (from AgMarkNet)
CREATE TABLE IF NOT EXISTS mandi_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    market VARCHAR(200) NOT NULL,
    commodity VARCHAR(100) NOT NULL,
    variety VARCHAR(100),
    grade VARCHAR(50),
    date DATE NOT NULL,
    min_price DOUBLE PRECISION,
    max_price DOUBLE PRECISION,
    modal_price DOUBLE PRECISION NOT NULL,
    arrival DOUBLE PRECISION,  -- quintals
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mandi_prices_lookup ON mandi_prices(market, commodity, variety, date);
CREATE INDEX IF NOT EXISTS idx_mandi_prices_date ON mandi_prices(date);

-- Policy events (from PIB RSS)
CREATE TABLE IF NOT EXISTS policy_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    commodity VARCHAR(100),
    event_type VARCHAR(50), -- msp, procurement, export_ban, import_duty, buffer_stock
    impact_direction VARCHAR(20), -- positive, negative, neutral
    impact_magnitude DOUBLE PRECISION, -- estimated price impact in INR/quintal
    source_url TEXT,
    published_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_policy_commodity_date ON policy_events(commodity, published_at);
CREATE INDEX IF NOT EXISTS idx_policy_published ON policy_events(published_at);

-- Model metadata
CREATE TABLE IF NOT EXISTS model_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(100) NOT NULL,
    model_type VARCHAR(50) NOT NULL, -- lightgbm, holt_winters, isolation_forest
    target VARCHAR(100) NOT NULL,
    features JSONB NOT NULL,
    hyperparameters JSONB,
    metrics JSONB,
    training_samples INTEGER,
    validation_metrics JSONB,
    model_path TEXT, -- R2 path
    onnx_path TEXT,  -- R2 path
    status VARCHAR(20) DEFAULT 'trained', -- trained, deployed, deprecated
    trained_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deployed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_model_name ON model_metadata(model_name);

-- Satellite indices cache
CREATE TABLE IF NOT EXISTS satellite_indices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    district VARCHAR(100) NOT NULL,
    crop VARCHAR(100),
    date DATE NOT NULL,
    week INTEGER NOT NULL,
    year INTEGER NOT NULL,
    ndvi_mean DOUBLE PRECISION,
    evi_mean DOUBLE PRECISION,
    savi_mean DOUBLE PRECISION,
    ndwi_mean DOUBLE PRECISION,
    ndvi_trend DOUBLE PRECISION,
    cloud_fraction DOUBLE PRECISION,
    scenes_count INTEGER,
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sat_district_date ON satellite_indices(district, date);
CREATE INDEX IF NOT EXISTS idx_sat_crop ON satellite_indices(crop);

-- Advisory cache (for fast reads)
CREATE TABLE IF NOT EXISTS advisory_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    district VARCHAR(100) NOT NULL,
    crop VARCHAR(100) NOT NULL,
    mandi VARCHAR(200) NOT NULL,
    variety VARCHAR(100),
    sowing_week INTEGER,
    payload JSONB NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_advisory_lookup ON advisory_cache(district, crop, mandi, expires_at);

-- Users (for Flutter app)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100),
    district VARCHAR(100),
    state VARCHAR(100),
    language VARCHAR(10) DEFAULT 'hi',
    crops JSONB DEFAULT '[]',
    watched_mandis JSONB DEFAULT '[]',
    watched_crops JSONB DEFAULT '[]',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    dark_mode BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- Insert sample district boundaries (Maharashtra)
INSERT INTO districts (name, state, min_lon, min_lat, max_lon, max_lat) VALUES
('Yavatmal', 'Maharashtra', 77.5, 19.5, 79.5, 21.0),
('Amravati', 'Maharashtra', 77.0, 20.0, 78.5, 21.5),
('Akola', 'Maharashtra', 76.5, 20.0, 77.5, 21.0),
('Wardha', 'Maharashtra', 78.0, 20.0, 79.5, 21.0),
('Nagpur', 'Maharashtra', 78.5, 20.5, 80.0, 22.0)
ON CONFLICT DO NOTHING;

-- Insert sample mandis
INSERT INTO mandis (name, district_id, state, latitude, longitude) VALUES
('Yavatmal Mandi', (SELECT id FROM districts WHERE name = 'Yavatmal'), 'Maharashtra', 20.39, 78.13),
('Amravati Mandi', (SELECT id FROM districts WHERE name = 'Amravati'), 'Maharashtra', 20.93, 77.75),
('Akola Mandi', (SELECT id FROM districts WHERE name = 'Akola'), 'Maharashtra', 20.70, 77.01),
('Wardha Mandi', (SELECT id FROM districts WHERE name = 'Wardha'), 'Maharashtra', 20.75, 78.60),
('Nagpur Mandi', (SELECT id FROM districts WHERE name = 'Nagpur'), 'Maharashtra', 21.15, 79.09)
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kisaan;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO kisaan;