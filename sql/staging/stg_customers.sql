DROP TABLE IF EXISTS stg_customers;

CREATE TABLE stg_customers AS
SELECT
    customer_id,
    INITCAP(name) AS name,
    LOWER(email) AS email,
    COALESCE(country, 'Nigeria') AS country,
    created_at::timestamp AS created_at
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at::timestamp DESC) AS rn
    FROM src_customers
    WHERE customer_id IS NOT NULL
) d
WHERE rn = 1;