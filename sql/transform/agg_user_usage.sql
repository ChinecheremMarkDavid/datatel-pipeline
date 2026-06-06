DROP TABLE IF EXISTS agg_user_usage;

CREATE TABLE agg_user_usage AS
SELECT
    customer_id,
    SUM(data_used_mb) AS total_data_used_mb,
    AVG(session_duration_sec) AS avg_session_duration_sec,
    COUNT(*) AS total_sessions
FROM stg_sessions
WHERE customer_id IS NOT NULL
GROUP BY customer_id;