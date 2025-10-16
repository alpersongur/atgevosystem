import 'package:cloud_firestore/cloud_firestore.dart';

class LeadService {
  LeadService._();

  static final LeadService instance = LeadService._();

  final CollectionReference<Map<String, dynamic>> _leadsCollection =
      FirebaseFirestore.instance.collection('leads');

  Stream<QuerySnapshot<Map<String, dynamic>>> getLeads() {
    return _leadsCollection
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> addLead(
    Map<String, dynamic> data,
  ) {
    final payload = {
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    return _leadsCollection.add(payload);
  }

  Future<void> updateLead(
    String id,
    Map<String, dynamic> data,
  ) {
    final payload = {
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    };
    return _leadsCollection.doc(id).update(payload);
  }

  Future<void> deleteLead(String id) {
    return _leadsCollection.doc(id).delete();
  }
}
