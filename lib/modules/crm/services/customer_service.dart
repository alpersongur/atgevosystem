import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final CollectionReference<Map<String, dynamic>> _customersCollection =
      FirebaseFirestore.instance.collection('customers');

  Future<DocumentReference<Map<String, dynamic>>> addCustomer(
      Map<String, dynamic> data) {
    final payload = {
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    };
    return _customersCollection.add(payload);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCustomers() {
    return _customersCollection
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> updateCustomer(
    String id,
    Map<String, dynamic> data,
  ) {
    return _customersCollection.doc(id).update(data);
  }

  Future<void> deleteCustomer(String id) {
    return _customersCollection.doc(id).delete();
  }
}
