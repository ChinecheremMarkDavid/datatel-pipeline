DROP TABLE IF EXISTS dw_user_analytics;

CREATE TABLE dw_user_analytics AS
SELECT
    c.customer_id::text AS customer_id,
    c.name              AS customer_name,
    c.email,
    c.country,
    c.created_at::timestamptz AS customer_since,
    COALESCE(r.total_revenue, 0)::float8        AS total_revenue,
    COALESCE(r.total_transactions, 0)::int      AS total_transactions,
    COALESCE(u.total_data_used_mb, 0)::float8   AS total_data_used_mb,
    COALESCE(u.avg_session_duration_sec, 0)::float8 AS avg_session_duration_sec,
    COALESCE(u.total_sessions, 0)::int          AS total_sessions,
    COALESCE(a.arpu, 0)::float8                 AS arpu,
    COALESCE(d.short_sessions, 0)::int          AS short_sessions,
    COALESCE(d.medium_sessions, 0)::int         AS medium_sessions,
    COALESCE(d.long_sessions, 0)::int           AS long_sessions,
    CASE
        WHEN COALESCE(u.total_sessions, 0) = 0 THEN 0
        ELSE COALESCE(u.total_data_used_mb, 0) / u.total_sessions
    END::float8 AS avg_data_per_session_mb
FROM stg_customers c
LEFT JOIN agg_user_revenue r        ON c.customer_id = r.customer_id
LEFT JOIN agg_user_usage u          ON c.customer_id = u.customer_id
LEFT JOIN agg_arpu a                ON c.customer_id = a.customer_id
LEFT JOIN agg_session_distribution d ON c.customer_id = d.customer_id;