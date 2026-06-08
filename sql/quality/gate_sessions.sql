SELECT COUNT(*) = 0
FROM src_network_sessions
WHERE session_id IS NULL
  AND start_time::timestamp >= '{{ params.t_start or ds }}'::timestamp
  AND start_time::timestamp <  '{{ params.t_end or macros.ds_add(ds, 1) }}'::timestamp;