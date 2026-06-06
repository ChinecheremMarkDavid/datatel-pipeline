DROP TABLE IF EXISTS agg_monthly_revenue;

CREATE TABLE agg_monthly_revenue AS
SELECT
    customer_id,
    DATE_TRUNC('month', transaction_date) AS revenue_month,
    SUM(amount) AS monthly_revenue
FROM stg_billing
WHERE customer_id IS NOT NULL
GROUP BY customer_id, DATE_TRUNC('month', transaction_date);