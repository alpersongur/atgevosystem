import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

DateTime? _timestampToDate(dynamic value) {
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

class MonitoringSnapshot {
  const MonitoringSnapshot({
    required this.reads,
    required this.writes,
    required this.deletes,
    required this.storageMb,
    required this.errors,
    required this.activeUsers,
    required this.timestamp,
    required this.hostingStatus,
  });

  factory MonitoringSnapshot.fromMap(Map<String, dynamic> data) {
    return MonitoringSnapshot(
      reads: (data['reads'] as num?)?.toDouble() ?? 0,
      writes: (data['writes'] as num?)?.toDouble() ?? 0,
      deletes: (data['deletes'] as num?)?.toDouble() ?? 0,
      storageMb: (data['storage_mb'] as num?)?.toDouble() ?? 0,
      errors: (data['errors'] as num?)?.toDouble() ?? 0,
      activeUsers: (data['active_users'] as num?)?.toDouble() ?? 0,
      timestamp: _timestampToDate(data['timestamp']),
      hostingStatus: (data['hosting_status'] as String? ?? 'Bilinmiyor').trim(),
    );
  }

  final double reads;
  final double writes;
  final double deletes;
  final double storageMb;
  final double errors;
  final double activeUsers;
  final DateTime? timestamp;
  final String hostingStatus;
}

class MonitoringRealtimeMetrics {
  const MonitoringRealtimeMetrics({
    required this.firestoreReads,
    required this.firestoreWrites,
    required this.firestoreDeletes,
    required this.storageMb,
    required this.functionsErrors,
    required this.activeUsers,
    required this.hostingStatus,
    required this.generatedAt,
  });

  factory MonitoringRealtimeMetrics.fromMap(Map<String, dynamic> data) {
    return MonitoringRealtimeMetrics(
      firestoreReads: (data['reads'] as num?)?.toDouble() ?? 0,
      firestoreWrites: (data['writes'] as num?)?.toDouble() ?? 0,
      firestoreDeletes: (data['deletes'] as num?)?.toDouble() ?? 0,
      storageMb: (data['storage_mb'] as num?)?.toDouble() ?? 0,
      functionsErrors: (data['errors'] as num?)?.toDouble() ?? 0,
      activeUsers: (data['active_users'] as num?)?.toDouble() ?? 0,
      hostingStatus: (data['hosting_status'] as String? ?? 'Bilinmiyor')
          .trim(),
      generatedAt: _timestampToDate(data['timestamp']) ?? DateTime.now(),
    );
  }

  final double firestoreReads;
  final double firestoreWrites;
  final double firestoreDeletes;
  final double storageMb;
  final double functionsErrors;
  final double activeUsers;
  final String hostingStatus;
  final DateTime generatedAt;
}

class MonitoringService {
  MonitoringService._(
    this._firestore,
    this._functions,
  );

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
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList(growable: false),
        );
  }

}
