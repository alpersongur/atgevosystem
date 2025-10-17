-- Materialized finance monthly summary table.
-- Run as scheduled job or via functions/mz_refresh.js
CREATE TABLE IF NOT EXISTS `atg_erp.mz_fin_monthly`
PARTITION BY DATE(month_start)
CLUSTER BY company_id AS
SELECT
  inv.company_id,
  DATE_TRUNC(inv.created_at, MONTH) AS month_start,
  FORMAT_TIMESTAMP('%Y%m', inv.created_at) AS ym,
  SUM(inv.amount) AS invoiced_total,
  SUM(pay.collected_total) AS collected_total,
  SUM(inv.amount - IFNULL(pay.collected_total, 0)) AS outstanding_total,
  CURRENT_TIMESTAMP() AS refreshed_at
FROM `atg_erp.fin_invoices_enriched` inv
LEFT JOIN (
  SELECT
    company_id,
    invoice_id,
    SUM(amount) AS collected_total
  FROM `atg_erp.raw_payments`
  GROUP BY company_id, invoice_id
) pay
  ON inv.company_id = pay.company_id
  AND inv.invoice_id = pay.invoice_id
GROUP BY company_id, month_start, ym;
