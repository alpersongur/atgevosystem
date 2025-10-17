# Looker Studio Dashboard Setup

1. Connect BigQuery project/dataset `atg-erp.eu.atg_erp`.
2. Create the following dashboards (links to be filled after publication):
   - Executive Summary – [Looker Link Placeholder]
   - Operations Heatmap – [Looker Link Placeholder]
   - Purchasing & Supplier Performance – [Looker Link Placeholder]
   - Inventory Turns & Low Stock – [Looker Link Placeholder]
3. Each dashboard should use the materialized tables `mz_fin_monthly` and `mz_ops_kpis` for performant queries.
4. Apply filters for `company_id` in each report to honour tenant isolation.
