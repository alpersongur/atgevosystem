import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_models.dart';

class SystemDashboardService {
  SystemDashboardService._(this._firestore);

  factory SystemDashboardService({FirebaseFirestore? firestore}) {
    if (firestore == null) return instance;
    return SystemDashboardService._(firestore);
  }

  static final SystemDashboardService instance = SystemDashboardService._(
    FirebaseFirestore.instance,
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _customerCollection =>
      _firestore.collection('customers');
  CollectionReference<Map<String, dynamic>> get _quoteCollection =>
      _firestore.collection('quotes');
  CollectionReference<Map<String, dynamic>> get _productionCollection =>
      _firestore.collection('production_orders');
  CollectionReference<Map<String, dynamic>> get _shipmentCollection =>
      _firestore.collection('shipments');
  CollectionReference<Map<String, dynamic>> get _invoiceCollection =>
      _firestore.collection('invoices');
  CollectionReference<Map<String, dynamic>> get _paymentCollection =>
      _firestore.collection('payments');
  CollectionReference<Map<String, dynamic>> get _inventoryCollection =>
      _firestore.collection('inventory');
  CollectionReference<Map<String, dynamic>> get _logCollection =>
      _firestore.collection('system_logs');

  static const List<String> _openQuoteStatuses = ['pending', 'in_production'];

  static const List<String> _activeProductionStatuses = [
    'waiting',
    'in_progress',
    'quality_check',
  ];

  static const List<String> _pendingShipmentStatuses = [
    'preparing',
    'on_the_way',
  ];

  static const List<String> _openInvoiceStatuses = ['unpaid', 'partial'];

  Future<DashboardSnapshot> getDashboardSnapshot(DashboardFilter filter) async {
    final results = await Future.wait<dynamic>([
      _countCustomers(filter),
      _countOpenQuotes(filter),
      _countActiveProductionOrders(filter),
      _countPendingShipments(filter),
      _calculateOutstandingInvoices(filter),
      _calculateInventoryValue(filter),
      _countLowStockItems(filter),
      _buildSalesSeries(filter),
    ]);

    final totalCustomers = results[0] as int;
    final openQuotes = results[1] as int;
    final activeProduction = results[2] as int;
    final pendingShipments = results[3] as int;
    final outstandingInvoices = results[4] as double;
    final totalInventoryValue = results[5] as double;
    final lowStockCount = results[6] as int;
    final salesSeries = results[7] as List<DashboardSeriesPoint>;

    final salesTotal = salesSeries.fold<double>(
      0,
      (value, point) => value + point.sales,
    );
    final collectionTotal = salesSeries.fold<double>(
      0,
      (value, point) => value + point.collection,
    );

    final summary = <String, dynamic>{
      'totalCustomers': totalCustomers,
      'openQuotes': openQuotes,
      'activeProductionOrders': activeProduction,
      'pendingShipments': pendingShipments,
      'outstandingInvoices': outstandingInvoices,
      'totalInventoryValue': totalInventoryValue,
      'rangeSalesTotal': salesTotal,
      'rangeCollectionTotal': collectionTotal,
      'monthlySalesTotal': salesTotal,
      'lowStockCount': lowStockCount,
    };

    return DashboardSnapshot(
      summary: summary,
      series: salesSeries,
      lowStockAlerts: lowStockCount,
      generatedAt: DateTime.now(),
    );
  }

  Future<int> _countCustomers(DashboardFilter filter) async {
    final now = DateTime.now();
    final query = _applyDateRange(
      _applyCompanyFilter(_customerCollection, filter),
      'created_at',
      filter.startDate(now),
      filter.endDate(now),
    );
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _countOpenQuotes(DashboardFilter filter) async {
    final now = DateTime.now();
    var query = _quoteCollection.where('status', whereIn: _openQuoteStatuses);
    query = _applyCompanyFilter(query, filter);
    query = _applyDateRange(
      query,
      'created_at',
      filter.startDate(now),
      filter.endDate(now),
    );
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _countActiveProductionOrders(DashboardFilter filter) async {
    final now = DateTime.now();
    var query = _productionCollection.where(
      'status',
      whereIn: _activeProductionStatuses,
    );
    query = _applyCompanyFilter(query, filter);
    query = _applyDateRange(
      query,
      'created_at',
      filter.startDate(now),
      filter.endDate(now),
    );
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _countPendingShipments(DashboardFilter filter) async {
    final now = DateTime.now();
    var query = _shipmentCollection.where(
      'status',
      whereIn: _pendingShipmentStatuses,
    );
    query = _applyCompanyFilter(query, filter);
    query = _applyDateRange(
      query,
      'created_at',
      filter.startDate(now),
      filter.endDate(now),
    );
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<double> _calculateOutstandingInvoices(DashboardFilter filter) async {
    final now = DateTime.now();
    var invoiceQuery = _invoiceCollection.where(
      'status',
      whereIn: _openInvoiceStatuses,
    );
    invoiceQuery = _applyCompanyFilter(invoiceQuery, filter);
    invoiceQuery = _applyDateRange(
      invoiceQuery,
      'issue_date',
      filter.startDate(now),
      filter.endDate(now),
    );

    final invoiceSnapshot = await invoiceQuery.get();

    if (invoiceSnapshot.docs.isEmpty) return 0;

    final invoiceTotals = <String, double>{};
    final invoiceIds = <String>[];

    for (final doc in invoiceSnapshot.docs) {
      final total = (doc.data()['grand_total'] as num?)?.toDouble() ?? 0;
      if (total <= 0) continue;
      invoiceTotals[doc.id] = total;
      invoiceIds.add(doc.id);
    }

    if (invoiceTotals.isEmpty) return 0;

    final paymentsByInvoice = <String, double>{};

    for (final chunk in _chunk(invoiceIds, 10)) {
      var paymentQuery = _paymentCollection.where('invoice_id', whereIn: chunk);
      paymentQuery = _applyCompanyFilter(paymentQuery, filter);
      paymentQuery = _applyDateRange(
        paymentQuery,
        'payment_date',
        filter.startDate(now),
        filter.endDate(now),
      );
      final paymentsSnapshot = await paymentQuery.get();

      for (final paymentDoc in paymentsSnapshot.docs) {
        final data = paymentDoc.data();
        final invoiceId = (data['invoice_id'] as String?)?.trim();
        if (invoiceId == null || invoiceId.isEmpty) continue;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        if (amount <= 0) continue;
        paymentsByInvoice[invoiceId] =
            (paymentsByInvoice[invoiceId] ?? 0) + amount;
      }
    }

    var outstandingTotal = 0.0;

    invoiceTotals.forEach((invoiceId, grandTotal) {
      final paid = paymentsByInvoice[invoiceId] ?? 0;
      final outstanding = grandTotal - paid;
      if (outstanding > 0) {
        outstandingTotal += outstanding;
      }
    });

    return outstandingTotal;
  }

  Future<double> _calculateInventoryValue(DashboardFilter filter) async {
    var query = _applyCompanyFilter(_inventoryCollection, filter);
    final snapshot = await query.get();
    var total = 0.0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
      if (quantity <= 0) continue;

      final unitCost = _extractUnitCost(data);
      if (unitCost != null) {
        total += quantity * unitCost;
        continue;
      }

      final totalValue = (data['total_value'] as num?)?.toDouble();
      if (totalValue != null) {
        total += totalValue;
      }
    }

    return total;
  }

  Future<int> _countLowStockItems(DashboardFilter filter) async {
    var query = _applyCompanyFilter(_inventoryCollection, filter);
    final snapshot = await query.get();
    var count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
      final minStock = (data['min_stock'] as num?)?.toDouble() ?? 0;
      if (minStock > 0 && quantity < minStock) {
        count++;
      }
    }

    return count;
  }

  Future<List<DashboardSeriesPoint>> _buildSalesSeries(
    DashboardFilter filter,
  ) async {
    final now = DateTime.now();
    final start = filter.startDate(now);
    final end = filter.endDate(now);
    final buckets = _buildSeriesBuckets(filter, now);

    final totals = <DateTime, _SeriesTotals>{
      for (final bucket in buckets) bucket.key: _SeriesTotals.zero,
    };

    Query<Map<String, dynamic>> invoiceQuery = _applyCompanyFilter(
      _invoiceCollection,
      filter,
    );
    invoiceQuery = _applyDateRange(invoiceQuery, 'issue_date', start, end);
    final invoiceSnapshot = await invoiceQuery.get();

    for (final doc in invoiceSnapshot.docs) {
      final data = doc.data();
      final issueDate = _toDate(data['issue_date']);
      if (issueDate == null) continue;
      final bucketKey = _resolveBucketKey(filter, issueDate);
      if (bucketKey == null || !totals.containsKey(bucketKey)) continue;
      final amount = (data['grand_total'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) continue;
      final current = totals[bucketKey] ?? _SeriesTotals.zero;
      totals[bucketKey] = current.copyWith(sales: current.sales + amount);
    }

    Query<Map<String, dynamic>> paymentQuery = _applyCompanyFilter(
      _paymentCollection,
      filter,
    );
    paymentQuery = _applyDateRange(paymentQuery, 'payment_date', start, end);
    final paymentSnapshot = await paymentQuery.get();

    for (final doc in paymentSnapshot.docs) {
      final data = doc.data();
      final paymentDate = _toDate(data['payment_date']);
      if (paymentDate == null) continue;
      final bucketKey = _resolveBucketKey(filter, paymentDate);
      if (bucketKey == null || !totals.containsKey(bucketKey)) continue;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) continue;
      final current = totals[bucketKey] ?? _SeriesTotals.zero;
      totals[bucketKey] = current.copyWith(
        collection: current.collection + amount,
      );
    }

    return buckets
        .map(
          (bucket) => DashboardSeriesPoint(
            period: bucket.key,
            label: bucket.label,
            sales: totals[bucket.key]?.sales ?? 0,
            collection: totals[bucket.key]?.collection ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Stream<List<SystemLogEntry>> watchRecentSystemLogs({int limit = 10}) {
    final cappedLimit = limit < 1 ? 10 : limit;
    return _logCollection
        .orderBy('timestamp', descending: true)
        .limit(cappedLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SystemLogEntry.fromFirestore)
              .toList(growable: false),
        );
  }

  Query<Map<String, dynamic>> _applyCompanyFilter(
    Query<Map<String, dynamic>> query,
    DashboardFilter filter,
  ) {
    if (filter.companyId == null || filter.companyId!.isEmpty) return query;
    return query.where('company_id', isEqualTo: filter.companyId);
  }

  Query<Map<String, dynamic>> _applyDateRange(
    Query<Map<String, dynamic>> query,
    String field,
    DateTime start,
    DateTime end,
  ) {
    return query
        .where(field, isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where(field, isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy(field);
  }

  double? _extractUnitCost(Map<String, dynamic> data) {
    final candidates = [
      data['unit_cost'],
      data['unit_price'],
      data['avg_cost'],
      data['average_cost'],
    ];

    for (final value in candidates) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  Iterable<List<T>> _chunk<T>(List<T> source, int size) sync* {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'must be greater than zero');
    }
    for (var i = 0; i < source.length; i += size) {
      final end = min(i + size, source.length);
      yield source.sublist(i, end);
    }
  }

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

  DateTime? _resolveBucketKey(DashboardFilter filter, DateTime source) {
    if (filter.isMonthlyRange) {
      return DateTime(source.year, source.month, 1);
    }
    return DateTime(source.year, source.month, source.day);
  }

  List<_SeriesBucket> _buildSeriesBuckets(
    DashboardFilter filter,
    DateTime reference,
  ) {
    final buckets = <_SeriesBucket>[];
    final formatterMonthly = DateFormat('MMM yy');
    final formatterDaily = DateFormat('dd MMM');

    if (filter.isMonthlyRange) {
      final currentMonthStart = DateTime(reference.year, reference.month, 1);
      for (var i = filter.bucketCount - 1; i >= 0; i--) {
        final target = DateTime(
          currentMonthStart.year,
          currentMonthStart.month - i,
          1,
        );
        buckets.add(
          _SeriesBucket(key: target, label: formatterMonthly.format(target)),
        );
      }
    } else {
      final end = DateTime(reference.year, reference.month, reference.day);
      final start = filter.startDate(
        reference,
      ); // already normalized to midnight.
      DateTime cursor = start;
      while (!cursor.isAfter(end)) {
        buckets.add(
          _SeriesBucket(key: cursor, label: formatterDaily.format(cursor)),
        );
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    return buckets;
  }
}

class SystemLogEntry {
  const SystemLogEntry({
    required this.id,
    required this.message,
    required this.timestamp,
    this.module,
    this.level,
    this.actorName,
    this.metadata,
  });

  factory SystemLogEntry.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SystemLogEntry(
      id: doc.id,
      message: (data['message'] as String? ?? '').trim(),
      module: (data['module'] as String?)?.trim(),
      level: (data['level'] as String?)?.trim(),
      actorName: (data['actor_name'] as String?)?.trim(),
      timestamp: _toDateStatic(data['timestamp']),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final String message;
  final DateTime? timestamp;
  final String? module;
  final String? level;
  final String? actorName;
  final Map<String, dynamic>? metadata;

  static DateTime? _toDateStatic(dynamic value) {
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
}

class _SeriesTotals {
  const _SeriesTotals({required this.sales, required this.collection});

  final double sales;
  final double collection;

  static _SeriesTotals get zero => const _SeriesTotals(sales: 0, collection: 0);

  _SeriesTotals copyWith({double? sales, double? collection}) {
    return _SeriesTotals(
      sales: sales ?? this.sales,
      collection: collection ?? this.collection,
    );
  }
}

class _SeriesBucket {
  const _SeriesBucket({required this.key, required this.label});

  final DateTime key;
  final String label;
}
