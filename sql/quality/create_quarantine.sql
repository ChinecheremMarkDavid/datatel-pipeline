CREATE TABLE IF NOT EXISTS quarantine (
    row_data    jsonb,
    source      text,
    detected_at timestamptz DEFAULT now()
);