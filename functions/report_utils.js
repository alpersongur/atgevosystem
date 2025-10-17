const {BigQuery} = require("@google-cloud/bigquery");
const ExcelJS = require("exceljs");
const PDFDocument = require("pdfkit");

const bigquery = new BigQuery();

function buildSql(reportType) {
  switch (reportType) {
    case 'crmQuotesSummary':
      return `SELECT customer_id, SUM(amount) AS total_amount, COUNT(1) AS quote_count
        FROM atg_erp.crm_quotes_enriched
        WHERE company_id = @company_id AND created_at BETWEEN @from AND @to
        GROUP BY customer_id`;
    case 'finInvoiceAging':
      return `SELECT * FROM atg_erp.fin_invoices_enriched
        WHERE company_id = @company_id AND created_at BETWEEN @from AND @to`;
    case 'finSalesVsCollections':
      return `SELECT ym, SUM(invoiced_total) AS invoiced, SUM(collected_total) AS collected
        FROM atg_erp.mz_fin_monthly
        WHERE company_id = @company_id AND month_start BETWEEN @from AND @to
        GROUP BY ym ORDER BY ym`;
    case 'prodOrdersByStatus':
      return `SELECT status, COUNT(1) AS count
        FROM atg_erp.prod_orders_enriched
        WHERE company_id = @company_id AND created_at BETWEEN @from AND @to
        GROUP BY status`;
    case 'invLowStock':
      return `SELECT item_id, name, quantity, min_stock
        FROM atg_erp.raw_inventory
        WHERE company_id = @company_id AND quantity < min_stock`;
    case 'purPurchaseOrdersAging':
      return `SELECT status, COUNT(1) AS count
        FROM atg_erp.raw_purchase_orders
        WHERE company_id = @company_id AND created_at BETWEEN @from AND @to
        GROUP BY status`;
    case 'shpDeliveriesMonthly':
      return `SELECT FORMAT_TIMESTAMP('%Y-%m', TIMESTAMP(created_at)) AS ym, COUNT(1) AS deliveries
        FROM atg_erp.raw_shipments
        WHERE company_id = @company_id AND created_at BETWEEN @from AND @to
        GROUP BY ym ORDER BY ym`;
    default:
      throw new Error('UNKNOWN_REPORT');
  }
}

async function fetchReportData({companyId, reportType, dateFrom, dateTo, filters = {}}) {
  const sql = buildSql(reportType);
  const params = {
    company_id: companyId,
    from: dateFrom.toISOString(),
    to: dateTo.toISOString(),
    ...filters,
  };
  const [job] = await bigquery.createQueryJob({
    query: sql,
    params,
    useLegacySql: false,
  });
  const [rows] = await job.getQueryResults();
  const columns = rows.length ? Object.keys(rows[0]) : [];
  return {columns, rows};
}

function toCsv({columns, rows}) {
  const header = columns.join(',');
  const body = rows.map((row) => columns.map((col) => JSON.stringify(row[col] ?? '')).join(',')).join('\n');
  return Buffer.from(`${header}\n${body}`, 'utf8');
}

async function toXlsx({columns, rows}) {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Rapor');
  sheet.addRow(columns);
  rows.forEach((row) => {
    sheet.addRow(columns.map((col) => row[col] ?? ''));
  });
  return workbook.xlsx.writeBuffer();
}

function toPdf({columns, rows}, title = 'Rapor') {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({margin: 30});
    const buffers = [];
    doc.on('data', (chunk) => buffers.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(buffers)));
    doc.on('error', reject);

    doc.fontSize(18).text(title, {align: 'left'});
    doc.moveDown();

    if (!columns.length) {
      doc.text('Veri yok');
      doc.end();
      return;
    }

    const tableRows = [columns, ...rows.map((row) => columns.map((col) => `${row[col] ?? ''}`))];
    tableRows.forEach((row) => {
      doc.text(row.join(' | '));
    });

    doc.end();
  });
}

module.exports = {
  fetchReportData,
  toCsv,
  toXlsx,
  toPdf,
};
