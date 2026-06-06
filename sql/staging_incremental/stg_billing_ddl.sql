CREATE TABLE IF NOT EXISTS stg_billing (
    transaction_id   BIGINT,
    customer_id      BIGINT,
    amount           NUMERIC,
    transaction_date TIMESTAMP
);