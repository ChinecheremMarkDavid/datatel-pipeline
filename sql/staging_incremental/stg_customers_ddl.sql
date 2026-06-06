CREATE TABLE IF NOT EXISTS stg_customers (
    customer_id BIGINT,
    name        TEXT,
    email       TEXT,
    country     TEXT,
    created_at  TIMESTAMP
);