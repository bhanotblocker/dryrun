-- Silver: enrich sales with customer country, partition by day.
CREATE OR REPLACE TABLE retail.silver.sales_enriched
USING DELTA
PARTITIONED BY (order_date)
AS
SELECT
  s.order_id,
  s.customer_id,
  c.name        AS customer_name,
  c.country,
  s.sku,
  s.qty,
  s.unit_price,
  s.revenue,
  s.order_ts,
  CAST(s.order_ts AS DATE) AS order_date
FROM retail.bronze.sales s
LEFT JOIN retail.bronze.customers c
  ON s.customer_id = c.customer_id;
