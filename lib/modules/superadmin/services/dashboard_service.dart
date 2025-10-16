import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  DashboardService._();

  static final DashboardService instance = DashboardService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getUserCount() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getModuleCount() async {
    final snapshot = await _firestore.collection('modules').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getPermissionCount() async {
    final snapshot = await _firestore.collection('permissions').count().get();
    return snapshot.count ?? 0;
  }

  Future<Map<String, int>> getRoleDistribution() async {
    final snapshot = await _firestore.collection('users').get();
    final distribution = <String, int>{};
    for (final doc in snapshot.docs) {
      final role = doc.data()['role'] as String? ?? 'unknown';
      distribution[role] = (distribution[role] ?? 0) + 1;
    }
    return distribution;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getRecentLogs() {
    return _firestore
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }
}
