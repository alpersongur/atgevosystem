import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/report_request_model.dart';

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<ReportData> fetchReport(ReportRequest request) async {
    // Attempt BigQuery via callable if configured
    try {
      final callable = _functions.httpsCallable('runBQQuery');
      final response = await callable.call({
        'sql': _buildSql(request),
        'params': _buildParams(request),
        'company_id': request.companyId,
      });
      final payload = Map<String, dynamic>.from(response.data as Map);
      final rawRows = (payload['rows'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
      final columns = rawRows.isEmpty
          ? const <ReportColumn>[]
          : rawRows.first.keys
                .map((key) => ReportColumn(label: key))
                .toList(growable: false);
      final rows = rawRows
          .map(
            (row) => columns
                .map((column) => row[column.label])
                .toList(growable: false),
          )
          .toList(growable: false);
      return ReportData(
        columns: columns,
        rows: rows,
        generatedAt: DateTime.now(),
      );
    } catch (error) {
      debugPrint('BigQuery rapor sorgusu başarısız: $error');
      return _fetchFromFirestore(request);
    }
  }

  Future<ReportData> _fetchFromFirestore(ReportRequest request) async {
    final message =
        'Firestore yedek verisi bulunamadı. Rapor tipi: ${request.type.name}';
    return ReportData(
      columns: const [ReportColumn(label: 'Bilgi')],
      rows: [
        [message],
      ],
      generatedAt: DateTime.now(),
    );
  }

  String _buildSql(ReportRequest request) {
    switch (request.type) {
      case ReportType.crmQuotesSummary:
        return 'SELECT customer_id, SUM(amount) AS total_amount, COUNT(1) AS quote_count '
            'FROM atg_erp.crm_quotes_enriched '
            'WHERE company_id = @company_id AND created_at BETWEEN @from AND @to '
            'GROUP BY customer_id';
      case ReportType.finInvoiceAging:
        return 'SELECT * FROM atg_erp.fin_invoices_enriched '
            'WHERE company_id = @company_id AND created_at BETWEEN @from AND @to';
      case ReportType.finSalesVsCollections:
        return 'SELECT ym, SUM(invoiced_total) AS invoiced, SUM(collected_total) AS collected '
            'FROM atg_erp.mz_fin_monthly '
            'WHERE company_id = @company_id AND month_start BETWEEN @from AND @to '
            'GROUP BY ym ORDER BY ym';
      case ReportType.prodOrdersByStatus:
        return 'SELECT status, COUNT(1) AS count '
            'FROM atg_erp.prod_orders_enriched '
            'WHERE company_id = @company_id AND created_at BETWEEN @from AND @to '
            'GROUP BY status';
      case ReportType.invLowStock:
        return 'SELECT item_id, name, quantity, min_stock '
            'FROM atg_erp.raw_inventory '
            'WHERE company_id = @company_id AND quantity < min_stock';
      case ReportType.purPurchaseOrdersAging:
        return 'SELECT status, COUNT(1) AS count '
            'FROM atg_erp.raw_purchase_orders '
            'WHERE company_id = @company_id AND created_at BETWEEN @from AND @to '
            'GROUP BY status';
      case ReportType.shpDeliveriesMonthly:
        return 'SELECT FORMAT_TIMESTAMP("%Y-%m", TIMESTAMP(created_at)) AS ym, COUNT(1) AS deliveries '
            'FROM atg_erp.raw_shipments '
            'WHERE company_id = @company_id AND created_at BETWEEN @from AND @to '
            'GROUP BY ym ORDER BY ym';
    }
  }

  Map<String, dynamic> _buildParams(ReportRequest request) {
    return {
      'company_id': request.companyId,
      'from': request.dateFrom.toIso8601String(),
      'to': request.dateTo.toIso8601String(),
      ...request.filters,
    };
  }
}
