DROP TABLE IF EXISTS agg_arpu;

CREATE TABLE agg_arpu AS
SELECT
    customer_id,
    SUM(amount) AS total_revenue,
    COUNT(DISTINCT DATE_TRUNC('month', transaction_date)) AS active_months,
    SUM(amount) / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', transaction_date)), 0) AS arpu
FROM stg_billing
WHERE customer_id IS NOT NULL
GROUP BY customer_id;