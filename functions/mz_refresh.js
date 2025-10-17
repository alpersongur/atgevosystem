const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const {BigQuery} = require("@google-cloud/bigquery");

const bigquery = new BigQuery();

async function runStatement(statement) {
  const [job] = await bigquery.createQueryJob({
    query: statement,
    useLegacySql: false,
  });
  await job.getQueryResults();
  logger.info("BigQuery job finished", {jobId: job.id});
}

exports.mz_refresh = functions.pubsub
    .schedule("0 2 * * *")
    .timeZone("Europe/Istanbul")
    .onRun(async () => {
      const scripts = [
        `
        BEGIN TRANSACTION;
          DELETE FROM \`atg_erp.mz_fin_monthly\` WHERE TRUE;
          INSERT INTO \`atg_erp.mz_fin_monthly\`
            (company_id, month_start, ym, invoiced_total, collected_total, outstanding_total, refreshed_at)
          SELECT
            inv.company_id,
            DATE_TRUNC(inv.created_at, MONTH) AS month_start,
            FORMAT_TIMESTAMP('%Y%m', inv.created_at) AS ym,
            SUM(inv.amount) AS invoiced_total,
            SUM(IFNULL(pay.collected_total, 0)) AS collected_total,
            SUM(inv.amount - IFNULL(pay.collected_total, 0)) AS outstanding_total,
            CURRENT_TIMESTAMP() AS refreshed_at
          FROM \`atg_erp.fin_invoices_enriched\` inv
          LEFT JOIN (
            SELECT company_id, invoice_id, SUM(amount) AS collected_total
            FROM \`atg_erp.raw_payments\`
            GROUP BY company_id, invoice_id
          ) pay
          ON inv.company_id = pay.company_id
          AND inv.invoice_id = pay.invoice_id
          GROUP BY company_id, month_start, ym;
        COMMIT TRANSACTION;`,
        `
        BEGIN TRANSACTION;
          DELETE FROM \`atg_erp.mz_ops_kpis\` WHERE TRUE;
          INSERT INTO \`atg_erp.mz_ops_kpis\`
            (company_id, kpi_date, open_quotes, active_prod_orders, pending_shipments, refreshed_at)
          SELECT
            COALESCE(q.company_id, p.company_id, s.company_id) AS company_id,
            COALESCE(q.kpi_date, p.kpi_date, s.kpi_date) AS kpi_date,
            IFNULL(q.open_quotes, 0) AS open_quotes,
            IFNULL(p.active_prod_orders, 0) AS active_prod_orders,
            IFNULL(s.pending_shipments, 0) AS pending_shipments,
            CURRENT_TIMESTAMP() AS refreshed_at
          FROM (
            SELECT company_id, DATE(created_at) AS kpi_date, COUNTIF(status IN ('open', 'pending')) AS open_quotes
            FROM \`atg_erp.crm_quotes_enriched\`
            GROUP BY company_id, kpi_date
          ) q
          FULL OUTER JOIN (
            SELECT company_id, DATE(created_at) AS kpi_date, COUNTIF(status NOT IN ('completed', 'cancelled')) AS active_prod_orders
            FROM \`atg_erp.prod_orders_enriched\`
            GROUP BY company_id, kpi_date
          ) p
          ON q.company_id = p.company_id AND q.kpi_date = p.kpi_date
          FULL OUTER JOIN (
            SELECT company_id, DATE(TIMESTAMP(created_at)) AS kpi_date, COUNTIF(status NOT IN ('delivered', 'cancelled')) AS pending_shipments
            FROM \`atg_erp.raw_shipments\`
            GROUP BY company_id, kpi_date
          ) s
          ON COALESCE(q.company_id, p.company_id) = s.company_id
          AND COALESCE(q.kpi_date, p.kpi_date) = s.kpi_date;
        COMMIT TRANSACTION;`
      ];

      for (const script of scripts) {
        await runStatement(script);
      }

      logger.info("Materialized tables refreshed successfully");
    });
