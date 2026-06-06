DROP TABLE IF EXISTS session_buckets;

CREATE TABLE session_buckets AS
SELECT
    session_id,
    customer_id,
    CASE
        WHEN session_duration_sec < 60 THEN 'short'
        WHEN session_duration_sec < 300 THEN 'medium'
        ELSE 'long'
    END AS bucket
FROM stg_sessions;