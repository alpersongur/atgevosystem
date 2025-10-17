-- Production Orders Enriched View
CREATE OR REPLACE VIEW `atg_erp.prod_orders_enriched` AS
SELECT
  o.company_id,
  o.order_id,
  o.quote_id,
  o.inventory_item_id,
  i.name AS item_name,
  o.status,
  o.priority,
  TIMESTAMP(o.created_at) AS created_at,
  TIMESTAMP(o.start_date) AS start_date,
  TIMESTAMP(o.due_date) AS due_date,
  TIMESTAMP(o.completed_at) AS completed_at,
  FORMAT_TIMESTAMP('%Y%m', TIMESTAMP(o.created_at)) AS month_yyyymm,
  DATE(TIMESTAMP(o._ingest_ts)) AS ingest_date
FROM `atg_erp.raw_production_orders` o
LEFT JOIN `atg_erp.raw_inventory` i
  ON o.company_id = i.company_id
  AND o.inventory_item_id = i.item_id;
