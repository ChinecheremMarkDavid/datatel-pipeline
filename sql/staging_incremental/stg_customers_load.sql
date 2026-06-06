TRUNCATE stg_customers;

INSERT INTO stg_customers (customer_id, name, email, country, created_at)
SELECT customer_id, INITCAP(name), LOWER(email), COALESCE(country, 'Nigeria'), created_at::timestamp
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at::timestamp DESC) AS rn
    FROM src_customers
    WHERE customer_id IS NOT NULL
) d
WHERE rn = 1;