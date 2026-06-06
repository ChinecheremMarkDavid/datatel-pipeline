DROP TABLE IF EXISTS src_customers;
CREATE TABLE src_customers (
    customer_id BIGINT,
    name        TEXT,
    email       TEXT,
    country     TEXT,
    created_at  TEXT
);

DROP TABLE IF EXISTS src_billing_transactions;
CREATE TABLE src_billing_transactions (
    transaction_id   BIGINT,
    customer_id      BIGINT,
    amount           NUMERIC,
    currency         TEXT,
    transaction_date TEXT
);

DROP TABLE IF EXISTS src_network_sessions;
CREATE TABLE src_network_sessions (
    session_id   BIGINT,
    customer_id  BIGINT,
    start_time   TEXT,
    end_time     TEXT,
    data_used_mb NUMERIC
);