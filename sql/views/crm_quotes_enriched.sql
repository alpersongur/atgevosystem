-- CRM Quotes Enriched View
-- Dataset: atg_erp
-- Refresh: view over raw exports, uses tenant company_id for isolation.
CREATE OR REPLACE VIEW `atg_erp.crm_quotes_enriched` AS
SELECT
  q.company_id,
  q.quote_id AS quote_id,
  q.customer_id,
  c.customer_name,
  q.status,
  q.amount,
  q.currency,
  TIMESTAMP(q.created_at) AS created_at,
  TIMESTAMP(q.updated_at) AS updated_at,
  FORMAT_TIMESTAMP('%Y%m', TIMESTAMP(q.created_at)) AS month_yyyymm,
  DATE(TIMESTAMP(q._ingest_ts)) AS ingest_date
FROM `atg_erp.raw_quotes` q
LEFT JOIN `atg_erp.raw_customers` c
  ON q.company_id = c.company_id
  AND q.customer_id = c.customer_id;

-- Recommended table configuration (execute separately):
-- ALTER TABLE `atg_erp.crm_quotes_enriched`
--   SET OPTIONS (
--     partition_expiration_days = 365,
--     require_partition_filter = true
--   );
