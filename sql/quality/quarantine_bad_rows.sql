TRUNCATE quarantine;

INSERT INTO quarantine (row_data, source)
SELECT to_jsonb(b), 'src_billing_transactions'
FROM (
    SELECT *, COUNT(*) OVER (PARTITION BY transaction_id) AS dup_count
    FROM src_billing_transactions
) b
WHERE transaction_id IS NULL OR customer_id IS NULL OR dup_count > 1;

INSERT INTO quarantine (row_data, source)
SELECT to_jsonb(s), 'src_network_sessions'
FROM (
    SELECT *, COUNT(*) OVER (PARTITION BY session_id) AS dup_count
    FROM src_network_sessions
) s
WHERE session_id IS NULL OR customer_id IS NULL OR dup_count > 1;