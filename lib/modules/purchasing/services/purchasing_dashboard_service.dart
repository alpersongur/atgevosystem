import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bill_model.dart';
import '../models/grn_model.dart';
import '../models/purchase_order_model.dart';
import '../models/purchasing_dashboard_models.dart';

class PurchasingDashboardService {
  PurchasingDashboardService._(this._firestore);

  factory PurchasingDashboardService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return PurchasingDashboardService._(firestore);
  }

  static final PurchasingDashboardService instance =
      PurchasingDashboardService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _poCollection =>
      _firestore.collection('purchase_orders');
  CollectionReference<Map<String, dynamic>> get _grnCollection =>
      _firestore.collection('grn');
  CollectionReference<Map<String, dynamic>> get _billCollection =>
      _firestore.collection('bills');

  Future<PurchasingSummary> getSummary() async {
    final poSnapshot = await _poCollection.get();
    final grnSnapshot = await _grnCollection.get();

    final orders = poSnapshot.docs
        .map(PurchaseOrderModel.fromFirestore)
        .toList(growable: false);
    final grns = grnSnapshot.docs
        .map(GRNModel.fromFirestore)
        .toList(growable: false);

    final now = DateTime.now();
    final totalPOs = orders.length;
    final openPOs = orders
        .where(
          (po) => ![
            'received',
            'closed',
            'canceled',
          ].contains(po.status.toLowerCase()),
        )
        .length;
    final delayedPOs = orders.where((po) {
      final expected = po.expectedDate;
      if (expected == null) return false;
      if (['received', 'closed', 'canceled'].contains(po.status)) return false;
      return expected.isBefore(now);
    }).length;

    final grnByPO = <String, List<GRNModel>>{};
    for (final grn in grns) {
      grnByPO.putIfAbsent(grn.poId, () => []).add(grn);
    }

    final leadTimes = <double>[];
    for (final po in orders) {
      final createdAt = po.createdAt;
      if (createdAt == null) continue;
      final grnList = grnByPO[po.id];
      if (grnList == null || grnList.isEmpty) continue;
      final firstReceipt = grnList
          .map((grn) => grn.receivedDate)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (prev, date) => prev == null || date.isBefore(prev) ? date : prev,
          );
      if (firstReceipt == null) continue;
      final days = firstReceipt.difference(createdAt).inDays;
      if (days >= 0) {
        leadTimes.add(days.toDouble());
      }
    }

    final avgLeadTime = leadTimes.isEmpty
        ? 0.0
        : leadTimes.reduce((a, b) => a + b) / leadTimes.length;

    return PurchasingSummary(
      totalPOs: totalPOs,
      openPOs: openPOs,
      delayedPOs: delayedPOs,
      avgLeadTimeDays: avgLeadTime,
    );
  }

  Future<List<PurchaseOrderModel>> getDelayedPOs() async {
    final now = DateTime.now();
    final snapshot = await _poCollection
        .where('expected_date', isLessThan: Timestamp.fromDate(now))
        .where('status', whereIn: ['open', 'partially_received', 'billed'])
        .orderBy('expected_date')
        .limit(50)
        .get();

    return snapshot.docs
        .map(PurchaseOrderModel.fromFirestore)
        .toList(growable: false);
  }

  Future<Map<String, int>> getStatusDistribution() async {
    final snapshot = await _poCollection.get();
    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final status = (doc.data()['status'] as String? ?? 'open').toLowerCase();
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<SupplierPerformance>> getSupplierPerformance() async {
    final poSnapshot = await _poCollection.get();
    final grnSnapshot = await _grnCollection.get();

    final orders = poSnapshot.docs
        .map(PurchaseOrderModel.fromFirestore)
        .toList(growable: false);
    final grns = grnSnapshot.docs
        .map(GRNModel.fromFirestore)
        .toList(growable: false);

    final grnByPO = <String, List<GRNModel>>{};
    for (final grn in grns) {
      grnByPO.putIfAbsent(grn.poId, () => []).add(grn);
    }

    final performance = <String, SupplierPerformance>{};

    for (final po in orders) {
      final supplierId = po.supplierId;
      final expected = po.expectedDate;
      if (expected == null) continue;
      final grnList = grnByPO[po.id];
      if (grnList == null || grnList.isEmpty) continue;
      final firstReceipt = grnList
          .map((grn) => grn.receivedDate)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (prev, date) => prev == null || date.isBefore(prev) ? date : prev,
          );
      if (firstReceipt == null) continue;

      final isOnTime = !firstReceipt.isAfter(expected);
      final entry = performance[supplierId];
      if (entry == null) {
        performance[supplierId] = SupplierPerformance(
          supplierId: supplierId,
          supplierName: null,
          onTime: isOnTime ? 1 : 0,
          late: isOnTime ? 0 : 1,
        );
      } else {
        performance[supplierId] = entry.copyWith(
          onTime: entry.onTime + (isOnTime ? 1 : 0),
          late: entry.late + (isOnTime ? 0 : 1),
        );
      }
    }

    return performance.values.toList(growable: false);
  }

  Future<List<MonthlySpendPoint>> getMonthlySpend({int monthsBack = 6}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - monthsBack + 1, 1);
    final snapshot = await _billCollection
        .where('issue_date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final totals = <String, double>{};
    for (var i = 0; i < monthsBack; i++) {
      final date = DateTime(now.year, now.month - (monthsBack - 1) + i, 1);
      final ym = _formatYm(date);
      totals[ym] = 0;
    }

    for (final doc in snapshot.docs) {
      final bill = BillModel.fromFirestore(doc);
      final date = bill.issueDate;
      if (date == null) continue;
      final ym = _formatYm(DateTime(date.year, date.month));
      if (!totals.containsKey(ym)) continue;
      totals[ym] = (totals[ym] ?? 0) + bill.grandTotal;
    }

    return totals.entries
        .map((entry) => MonthlySpendPoint(ym: entry.key, total: entry.value))
        .toList(growable: false);
  }

  Future<List<BillModel>> getRecentBills({int limit = 10}) async {
    final snapshot = await _billCollection
        .orderBy('issue_date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(BillModel.fromFirestore).toList(growable: false);
  }

  Future<Map<String, String>> getSupplierNames(
    Iterable<String> supplierIds,
  ) async {
    if (supplierIds.isEmpty) return {};

    final unique = supplierIds.toSet().toList(growable: false);
    final chunks = <List<String>>[];
    const chunkSize = 10;
    for (var i = 0; i < unique.length; i += chunkSize) {
      chunks.add(unique.sublist(i, min(i + chunkSize, unique.length)));
    }

    final names = <String, String>{};
    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection('suppliers')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        names[doc.id] = (doc.data()['supplier_name'] as String? ?? doc.id);
      }
    }
    return names;
  }

  String _formatYm(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
