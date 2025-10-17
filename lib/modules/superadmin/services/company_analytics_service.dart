import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_project_service.dart';

class CompanyAnalyticsService {
  CompanyAnalyticsService._();

  static final CompanyAnalyticsService instance = CompanyAnalyticsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getCompanyUsage(String companyId) async {
    final doc = await _firestore.collection('companies').doc(companyId).get();
    final data = doc.data() ?? <String, dynamic>{};
    return Map<String, dynamic>.from(data['usage'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> getAllCompaniesUsage() async {
    final snapshot = await _firestore.collection('companies').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'name': data['name'], 'usage': data['usage'] ?? {}};
    }).toList();
  }

  Future<void> updateCompanyUsage(
    String companyId,
    Map<String, dynamic> usage,
  ) {
    return _firestore.collection('companies').doc(companyId).set({
      'usage': usage,
      'usage_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCompanyLogs(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> triggerUsageRefresh(String companyId) {
    return FirebaseProjectService.instance.deployDefaultRules(
      companyId,
    ); // Placeholder for admin API call.
  }
}
