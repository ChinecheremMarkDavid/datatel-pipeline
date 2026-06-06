DELETE FROM stg_sessions
WHERE start_time >= '{{ params.t_start or ds }}'::timestamp
  AND start_time <  '{{ params.t_end or macros.ds_add(ds, 1) }}'::timestamp;

INSERT INTO stg_sessions
    (session_id, customer_id, start_time, end_time, data_used_mb, session_date, session_duration_sec)
SELECT
    session_id, customer_id,
    start_time::timestamp, end_time::timestamp,
    COALESCE(data_used_mb, 0),
    start_time::timestamp::date,
    CASE WHEN end_time::timestamp > start_time::timestamp
         THEN EXTRACT(EPOCH FROM (end_time::timestamp - start_time::timestamp))::int
         ELSE 0 END
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY session_id ORDER BY start_time::timestamp DESC
           ) AS rn
    FROM src_network_sessions
    WHERE session_id IS NOT NULL
      AND start_time::timestamp >= '{{ params.t_start or ds }}'::timestamp
      AND start_time::timestamp <  '{{ params.t_end or macros.ds_add(ds, 1) }}'::timestamp
) ranked
WHERE rn = 1;