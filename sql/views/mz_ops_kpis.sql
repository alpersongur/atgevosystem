-- Materialized operational KPIs table.
CREATE TABLE IF NOT EXISTS `atg_erp.mz_ops_kpis`
PARTITION BY DATE(kpi_date)
CLUSTER BY company_id AS
WITH quotes AS (
  SELECT
    company_id,
    DATE(created_at) AS kpi_date,
    COUNTIF(status IN ('open', 'pending')) AS open_quotes
  FROM `atg_erp.crm_quotes_enriched`
  GROUP BY company_id, kpi_date
),
production AS (
  SELECT
    company_id,
    DATE(created_at) AS kpi_date,
    COUNTIF(status NOT IN ('completed', 'cancelled')) AS active_prod_orders
  FROM `atg_erp.prod_orders_enriched`
  GROUP BY company_id, kpi_date
),
shipments AS (
  SELECT
    company_id,
    DATE(TIMESTAMP(created_at)) AS kpi_date,
    COUNTIF(status NOT IN ('delivered', 'cancelled')) AS pending_shipments
  FROM `atg_erp.raw_shipments`
  GROUP BY company_id, kpi_date
)
SELECT
  COALESCE(q.company_id, p.company_id, s.company_id) AS company_id,
  COALESCE(q.kpi_date, p.kpi_date, s.kpi_date) AS kpi_date,
  IFNULL(q.open_quotes, 0) AS open_quotes,
  IFNULL(p.active_prod_orders, 0) AS active_prod_orders,
  IFNULL(s.pending_shipments, 0) AS pending_shipments,
  CURRENT_TIMESTAMP() AS refreshed_at
FROM quotes q
FULL OUTER JOIN production p
  ON q.company_id = p.company_id
  AND q.kpi_date = p.kpi_date
FULL OUTER JOIN shipments s
  ON COALESCE(q.company_id, p.company_id) = s.company_id
  AND COALESCE(q.kpi_date, p.kpi_date) = s.kpi_date;
