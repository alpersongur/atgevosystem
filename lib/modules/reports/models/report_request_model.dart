import 'package:equatable/equatable.dart';

enum ReportType {
  crmQuotesSummary,
  finInvoiceAging,
  finSalesVsCollections,
  prodOrdersByStatus,
  invLowStock,
  purPurchaseOrdersAging,
  shpDeliveriesMonthly,
}

class ReportRequest extends Equatable {
  const ReportRequest({
    required this.companyId,
    required this.type,
    required this.dateFrom,
    required this.dateTo,
    this.filters = const <String, dynamic>{},
  });

  final String companyId;
  final ReportType type;
  final DateTime dateFrom;
  final DateTime dateTo;
  final Map<String, dynamic> filters;

  @override
  List<Object?> get props => [companyId, type, dateFrom, dateTo, filters];
}

class ReportColumn {
  const ReportColumn({required this.label});
  final String label;
}

class ReportData {
  const ReportData({
    required this.columns,
    required this.rows,
    this.totals,
    this.generatedAt,
  });

  final List<ReportColumn> columns;
  final List<List<dynamic>> rows;
  final Map<String, dynamic>? totals;
  final DateTime? generatedAt;
}
