-- Most valuable customers
SELECT customer_id, customer_name, total_revenue, total_transactions, arpu
FROM `PROJECT.datatel_dw.dw_user_analytics`
ORDER BY total_revenue DESC
LIMIT 20;

-- Churn risk, excluding brand-new accounts
SELECT customer_id, customer_name, total_sessions, total_revenue
FROM `PROJECT.datatel_dw.dw_user_analytics`
WHERE total_sessions < 5
  AND total_revenue < 1000
  AND customer_since < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);

-- Revenue vs usage mismatch (heavy users paying little)
SELECT customer_id, customer_name, total_data_used_mb, total_revenue,
       SAFE_DIVIDE(total_revenue, total_data_used_mb) AS revenue_per_mb
FROM `PROJECT.datatel_dw.dw_user_analytics`
WHERE total_data_used_mb > 0
ORDER BY revenue_per_mb ASC
LIMIT 20;