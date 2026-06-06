DROP TABLE IF EXISTS agg_session_distribution;

CREATE TABLE agg_session_distribution AS
SELECT
    customer_id,
    COUNT(*) FILTER (WHERE bucket = 'short')  AS short_sessions,
    COUNT(*) FILTER (WHERE bucket = 'medium') AS medium_sessions,
    COUNT(*) FILTER (WHERE bucket = 'long')   AS long_sessions
FROM session_buckets
WHERE customer_id IS NOT NULL
GROUP BY customer_id;