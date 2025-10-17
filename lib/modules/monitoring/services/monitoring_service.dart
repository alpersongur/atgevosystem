import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/monitoring_models.dart';

class MonitoringService {
  MonitoringService._(this._firestore, this._functions);

  factory MonitoringService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) {
    if (firestore == null && functions == null) {
      return instance;
    }
    return MonitoringService._(
      firestore ?? FirebaseFirestore.instance,
      functions ?? FirebaseFunctions.instance,
    );
  }

  static final MonitoringService instance = MonitoringService._(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<MonitoringRealtimeMetrics> fetchRealtimeMetrics() async {
    try {
      final callable = _functions.httpsCallable('getSystemMetrics');
      final response = await callable();
      final data = Map<String, dynamic>.from(response.data as Map);
      return MonitoringRealtimeMetrics.fromMap(data);
    } catch (_) {
      // Fallback to latest snapshot if callable fails.
      final latestSnapshot = await fetchLatestSnapshot();
      if (latestSnapshot != null) {
        return MonitoringRealtimeMetrics(
          firestoreReads: latestSnapshot.reads,
          firestoreWrites: latestSnapshot.writes,
          firestoreDeletes: latestSnapshot.deletes,
          storageMb: latestSnapshot.storageMb,
          functionsErrors: latestSnapshot.errors,
          activeUsers: latestSnapshot.activeUsers,
          hostingStatus: latestSnapshot.hostingStatus,
          generatedAt: latestSnapshot.timestamp ?? DateTime.now(),
        );
      }
      rethrow;
    }
  }

  Future<List<MonitoringSnapshot>> fetchDailySnapshots({int days = 7}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final query = await _firestore
        .collection('system_metrics')
        .doc('daily')
        .collection('records')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('timestamp')
        .get();

    return query.docs
        .map((doc) => MonitoringSnapshot.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<MonitoringSnapshot?> fetchLatestSnapshot() async {
    final latest = await _firestore
        .collection('system_metrics')
        .doc('daily')
        .collection('records')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (latest.docs.isEmpty) return null;
    return MonitoringSnapshot.fromMap(latest.docs.first.data());
  }

  Stream<List<Map<String, dynamic>>> watchRecentErrors({int limit = 10}) {
    return _firestore
        .collection('system_logs')
        .where('type', isEqualTo: 'error')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(growable: false),
        );
  }
}
