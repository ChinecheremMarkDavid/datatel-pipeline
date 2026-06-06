DROP TABLE IF EXISTS stg_sessions;

CREATE TABLE stg_sessions AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY start_time::timestamp DESC) AS rn
    FROM src_network_sessions
    WHERE session_id IS NOT NULL
),
typed AS (
    SELECT
        session_id,
        customer_id,
        start_time::timestamp AS start_time,
        end_time::timestamp   AS end_time,
        COALESCE(data_used_mb, 0) AS data_used_mb,
        start_time::timestamp::date AS session_date
    FROM deduped
    WHERE rn = 1
)
SELECT
    session_id, customer_id, start_time, end_time, data_used_mb, session_date,
    CASE WHEN end_time > start_time
         THEN EXTRACT(EPOCH FROM (end_time - start_time))::int
         ELSE 0 END AS session_duration_sec
FROM typed;