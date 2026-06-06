CREATE TABLE IF NOT EXISTS stg_sessions (
    session_id           BIGINT,
    customer_id          BIGINT,
    start_time           TIMESTAMP,
    end_time             TIMESTAMP,
    data_used_mb         NUMERIC,
    session_date         DATE,
    session_duration_sec INT
);