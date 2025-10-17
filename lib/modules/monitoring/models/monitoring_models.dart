import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? monitoringTimestampToDate(dynamic value) {
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
      timestamp: monitoringTimestampToDate(data['timestamp']),
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
      hostingStatus: (data['hosting_status'] as String? ?? 'Bilinmiyor').trim(),
      generatedAt:
          monitoringTimestampToDate(data['timestamp']) ?? DateTime.now(),
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
