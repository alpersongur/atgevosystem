import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

import '../models/aging_buckets_model.dart';
import '../models/finance_summary_model.dart';
import '../models/invoice_model.dart';
import '../models/monthly_point_model.dart';
import '../models/top_customer_model.dart';

class FinanceDashboardService {
  FinanceDashboardService._(this._firestore);

  factory FinanceDashboardService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FinanceDashboardService._(firestore);
    }
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return instance;
  }

  static FinanceDashboardService? _instance;
  static FinanceDashboardService? _testInstance;

  static FinanceDashboardService get instance {
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return _instance ??=
        FinanceDashboardService._(FirebaseFirestore.instance);
  }

  @visibleForTesting
  static void setTestInstance(FinanceDashboardService service) {
    _testInstance = service;
  }

  @visibleForTesting
  static void resetTestInstance() {
    _testInstance = null;
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _invoiceCollection =>
      _firestore.collection('invoices');

  CollectionReference<Map<String, dynamic>> get _paymentCollection =>
      _firestore.collection('payments');

  Future<FinanceSummary> getSummary({DateTime? from, DateTime? to}) async {
    final invoiceSnapshot = await _buildInvoiceRangeQuery(from, to).get();
    final paymentSnapshot = await _buildPaymentRangeQuery(from, to).get();

    double invoicedTotal = 0;
    DateTime? firstInvoiceDate;
    DateTime? lastInvoiceDate;

    for (final doc in invoiceSnapshot.docs) {
      final data = doc.data();
      invoicedTotal += (data['grand_total'] as num?)?.toDouble() ?? 0;
      final issueDate = _toDate(data['issue_date']);
      if (issueDate != null) {
        final currentFirst = firstInvoiceDate;
        if (currentFirst == null || issueDate.isBefore(currentFirst)) {
          firstInvoiceDate = issueDate;
        }
        final currentLast = lastInvoiceDate;
        if (currentLast == null || issueDate.isAfter(currentLast)) {
          lastInvoiceDate = issueDate;
        }
      }
    }

    double collectedTotal = 0;
    DateTime? firstPaymentDate;
    DateTime? lastPaymentDate;

    for (final doc in paymentSnapshot.docs) {
      final data = doc.data();
      collectedTotal += (data['amount'] as num?)?.toDouble() ?? 0;
      final paymentDate = _toDate(data['payment_date']);
      if (paymentDate != null) {
        final currentFirst = firstPaymentDate;
        if (currentFirst == null || paymentDate.isBefore(currentFirst)) {
          firstPaymentDate = paymentDate;
        }
        final currentLast = lastPaymentDate;
        if (currentLast == null || paymentDate.isAfter(currentLast)) {
          lastPaymentDate = paymentDate;
        }
      }
    }

    final outstanding = invoicedTotal - collectedTotal;

    final periodStart =
        from ??
        firstInvoiceDate ??
        firstPaymentDate ??
        DateTime.now().subtract(const Duration(days: 30));
    final periodEnd =
        to ?? lastInvoiceDate ?? lastPaymentDate ?? DateTime.now();

    final rawSpan = periodEnd.difference(periodStart).inDays.abs() + 1;
    final daySpan = rawSpan < 1 ? 1 : rawSpan;
    final avgDailySales = daySpan > 0 ? invoicedTotal / daySpan : 0.0;
    final dso = avgDailySales > 0 ? outstanding / avgDailySales : 0.0;

    return FinanceSummary(
      invoiced: invoicedTotal,
      collected: collectedTotal,
      outstanding: outstanding,
      dso: dso,
    );
  }

  Future<List<MonthlyPoint>> getMonthlySeries(int monthsBack) async {
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month - monthsBack + 1, 1);
    final invoiceSnapshot = await _buildInvoiceRangeQuery(
      startMonth,
      null,
    ).get();
    final paymentSnapshot = await _buildPaymentRangeQuery(
      startMonth,
      null,
    ).get();

    final orderedMonths = <String, DateTime>{};
    for (var i = 0; i < monthsBack; i++) {
      final date = DateTime(now.year, now.month - (monthsBack - 1) + i, 1);
      orderedMonths[_formatYm(date)] = date;
    }

    final totals = {
      for (final entry in orderedMonths.entries)
        entry.key: _MonthlyTotals(invoiced: 0, collected: 0),
    };

    for (final doc in invoiceSnapshot.docs) {
      final invoiceData = doc.data();
      final issueDate = _toDate(invoiceData['issue_date']);
      if (issueDate == null) continue;
      final ym = _formatYm(issueDate);
      if (!totals.containsKey(ym)) continue;
      final amount = (invoiceData['grand_total'] as num?)?.toDouble() ?? 0;
      totals[ym] = totals[ym]!.copyWith(
        invoiced: totals[ym]!.invoiced + amount,
      );
    }

    for (final doc in paymentSnapshot.docs) {
      final paymentData = doc.data();
      final paymentDate = _toDate(paymentData['payment_date']);
      if (paymentDate == null) continue;
      final ym = _formatYm(paymentDate);
      if (!totals.containsKey(ym)) continue;
      final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0;
      totals[ym] = totals[ym]!.copyWith(
        collected: totals[ym]!.collected + amount,
      );
    }

    return orderedMonths.keys
        .map(
          (ym) => MonthlyPoint(
            ym: ym,
            invoiced: totals[ym]?.invoiced ?? 0,
            collected: totals[ym]?.collected ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, double>> getCurrencyBreakdown() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11, 1);
    final snapshot = await _buildInvoiceRangeQuery(start, null).get();

    final breakdown = <String, double>{};
    for (final doc in snapshot.docs) {
      final currency = (doc.data()['currency'] as String? ?? 'TRY')
          .toUpperCase();
      final amount = (doc.data()['grand_total'] as num?)?.toDouble() ?? 0;
      breakdown[currency] = (breakdown[currency] ?? 0) + amount;
    }
    return breakdown;
  }

  Future<AgingBuckets> getAgingBuckets() async {
    final snapshot = await _invoiceCollection
        .where('status', whereIn: ['unpaid', 'partial'])
        .get();

    if (snapshot.docs.isEmpty) return AgingBuckets.empty;

    final invoiceIds = snapshot.docs.map((doc) => doc.id).toList();
    final paymentsByInvoice = <String, double>{};

    for (final chunk in _chunk(invoiceIds, 10)) {
      final paymentSnapshot = await _paymentCollection
          .where('invoice_id', whereIn: chunk)
          .get();
      for (final doc in paymentSnapshot.docs) {
        final invoiceId = (doc.data()['invoice_id'] as String?) ?? '';
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        if (invoiceId.isEmpty) continue;
        paymentsByInvoice[invoiceId] =
            (paymentsByInvoice[invoiceId] ?? 0) + amount;
      }
    }

    double b0_30 = 0;
    double b31_60 = 0;
    double b61_90 = 0;
    double b90p = 0;
    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final dueDate = _toDate(data['due_date']);
      if (dueDate == null) continue;
      final grandTotal = (data['grand_total'] as num?)?.toDouble() ?? 0;
      final paid = paymentsByInvoice[doc.id] ?? 0;
      final outstanding = max(0.0, grandTotal - paid);
      if (outstanding <= 0) continue;

      final days = now
          .difference(DateTime(dueDate.year, dueDate.month, dueDate.day))
          .inDays;

      if (days <= 30) {
        b0_30 += outstanding;
      } else if (days <= 60) {
        b31_60 += outstanding;
      } else if (days <= 90) {
        b61_90 += outstanding;
      } else {
        b90p += outstanding;
      }
    }

    return AgingBuckets(
      b0_30: b0_30,
      b31_60: b31_60,
      b61_90: b61_90,
      b90p: b90p,
    );
  }

  Future<List<TopCustomer>> getTopCustomers({int limit = 10}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11, 1);
    final snapshot = await _buildInvoiceRangeQuery(start, null).get();

    final totals = <String, double>{};
    for (final doc in snapshot.docs) {
      final customerId = (doc.data()['customer_id'] as String?) ?? '';
      if (customerId.isEmpty) continue;
      final amount = (doc.data()['grand_total'] as num?)?.toDouble() ?? 0;
      totals[customerId] = (totals[customerId] ?? 0) + amount;
    }

    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(limit)
        .map((entry) => TopCustomer(customerId: entry.key, total: entry.value))
        .toList(growable: false);
  }

  Future<List<InvoiceModel>> getOverdueInvoices() async {
    final now = DateTime.now();
    final snapshot = await _invoiceCollection
        .where('status', whereIn: ['unpaid', 'partial'])
        .where('due_date', isLessThan: Timestamp.fromDate(now))
        .orderBy('due_date')
        .limit(100)
        .get();

    return snapshot.docs
        .map(InvoiceModel.fromFirestore)
        .toList(growable: false);
  }

  Query<Map<String, dynamic>> _buildInvoiceRangeQuery(
    DateTime? from,
    DateTime? to,
  ) {
    Query<Map<String, dynamic>> query = _invoiceCollection;
    var filtered = false;
    if (from != null) {
      query = query.where(
        'issue_date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(from)),
      );
      filtered = true;
    }
    if (to != null) {
      query = query.where(
        'issue_date',
        isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(to)),
      );
      filtered = true;
    }
    if (filtered) {
      query = query.orderBy('issue_date');
    }
    return query;
  }

  Query<Map<String, dynamic>> _buildPaymentRangeQuery(
    DateTime? from,
    DateTime? to,
  ) {
    Query<Map<String, dynamic>> query = _paymentCollection;
    var filtered = false;
    if (from != null) {
      query = query.where(
        'payment_date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(from)),
      );
      filtered = true;
    }
    if (to != null) {
      query = query.where(
        'payment_date',
        isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(to)),
      );
      filtered = true;
    }
    if (filtered) {
      query = query.orderBy('payment_date');
    }
    return query;
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  String _formatYm(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Iterable<List<T>> _chunk<T>(List<T> items, int size) sync* {
    if (items.isEmpty) return;
    for (var i = 0; i < items.length; i += size) {
      yield items.sublist(i, min(i + size, items.length));
    }
  }
}

class _MonthlyTotals {
  const _MonthlyTotals({required this.invoiced, required this.collected});

  final double invoiced;
  final double collected;

  _MonthlyTotals copyWith({double? invoiced, double? collected}) {
    return _MonthlyTotals(
      invoiced: invoiced ?? this.invoiced,
      collected: collected ?? this.collected,
    );
  }
}
