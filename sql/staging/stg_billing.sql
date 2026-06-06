DROP TABLE IF EXISTS stg_billing;

CREATE TABLE stg_billing AS
SELECT
    transaction_id,
    customer_id,
    COALESCE(amount, 0) AS amount,
    transaction_date::timestamp AS transaction_date
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY transaction_id
               ORDER BY transaction_date::timestamp DESC
           ) AS rn
    FROM src_billing_transactions
    WHERE transaction_id IS NOT NULL
) ranked
WHERE rn = 1;