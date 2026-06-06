DELETE FROM stg_billing
WHERE transaction_date >= '{{ params.t_start or ds }}'::timestamp
  AND transaction_date <  '{{ params.t_end or macros.ds_add(ds, 1) }}'::timestamp;

INSERT INTO stg_billing (transaction_id, customer_id, amount, transaction_date)
SELECT transaction_id, customer_id, COALESCE(amount, 0), transaction_date::timestamp
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY transaction_id ORDER BY transaction_date::timestamp DESC
           ) AS rn
    FROM src_billing_transactions
    WHERE transaction_id IS NOT NULL
      AND transaction_date::timestamp >= '{{ params.t_start or ds }}'::timestamp
      AND transaction_date::timestamp <  '{{ params.t_end or macros.ds_add(ds, 1) }}'::timestamp
) ranked
WHERE rn = 1;