-- Finance Invoices Enriched View
CREATE OR REPLACE VIEW `atg_erp.fin_invoices_enriched` AS
WITH invoices AS (
  SELECT
    company_id,
    invoice_id,
    customer_id,
    amount,
    tax_amount,
    status,
    currency,
    TIMESTAMP(created_at) AS created_at,
    TIMESTAMP(updated_at) AS updated_at,
    TIMESTAMP(paid_at) AS paid_at,
    DATE(TIMESTAMP(_ingest_ts)) AS ingest_date
  FROM `atg_erp.raw_invoices`
),
payments AS (
  SELECT
    company_id,
    invoice_id,
    SUM(amount) AS collected_total
  FROM `atg_erp.raw_payments`
  GROUP BY company_id, invoice_id
)
SELECT
  inv.company_id,
  inv.invoice_id,
  inv.customer_id,
  cust.customer_name,
  inv.amount,
  inv.tax_amount,
  inv.status,
  inv.currency,
  inv.created_at,
  inv.updated_at,
  inv.paid_at,
  SAFE_DIVIDE(pay.collected_total, inv.amount) AS collection_ratio,
  FORMAT_TIMESTAMP('%Y%m', inv.created_at) AS month_yyyymm,
  inv.ingest_date
FROM invoices inv
LEFT JOIN payments pay
  ON inv.company_id = pay.company_id
  AND inv.invoice_id = pay.invoice_id
LEFT JOIN `atg_erp.raw_customers` cust
  ON inv.company_id = cust.company_id
  AND inv.customer_id = cust.customer_id;
