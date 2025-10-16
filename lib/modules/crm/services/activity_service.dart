import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityService {
  ActivityService._();

  static final ActivityService instance = ActivityService._();

  final CollectionReference<Map<String, dynamic>> _activitiesCollection =
      FirebaseFirestore.instance.collection('activities');

  Future<DocumentReference<Map<String, dynamic>>> addActivity(
    Map<String, dynamic> data,
  ) {
    final customerId = data['customer_id'] as String?;
    final type = data['type'] as String?;

    if (customerId == null || customerId.isEmpty) {
      throw ArgumentError('customer_id alanı zorunludur');
    }
    if (type == null || type.isEmpty) {
      throw ArgumentError('type alanı zorunludur');
    }

    final payload = <String, dynamic>{
      ...data,
      'timestamp': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    return _activitiesCollection.add(payload);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCustomerActivities(
    String customerId,
  ) {
    return _activitiesCollection
        .where('customer_id', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> recentActivities({
    int limit = 10,
  }) {
    return _activitiesCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> deleteActivity(String activityId) {
    return _activitiesCollection.doc(activityId).delete();
  }
}
