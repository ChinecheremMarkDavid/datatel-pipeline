DROP TABLE IF EXISTS agg_user_revenue;

CREATE TABLE agg_user_revenue AS
SELECT
    customer_id,
    SUM(amount) AS total_revenue,
    COUNT(*) AS total_transactions
FROM stg_billing
WHERE customer_id IS NOT NULL
GROUP BY customer_id;