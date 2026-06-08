SELECT COUNT(*) = 0
FROM src_billing_transactions
WHERE transaction_id IS NULL
  AND transaction_date::timestamp >= '{{ params.t_start or ds }}'::timestamp
  AND transaction_date::timestamp <  '{{ params.t_end or macros.ds_add(ds, 1) }}'::timestamp;