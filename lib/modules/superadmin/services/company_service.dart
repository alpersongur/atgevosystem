import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

class CompanyService with FirestoreTimestamps {
  CompanyService._();

  static final CompanyService instance = CompanyService._();

  final CollectionReference<Map<String, dynamic>> _companiesCollection =
      FirebaseFirestore.instance.collection('companies');

  Stream<QuerySnapshot<Map<String, dynamic>>> getCompanies() {
    return _companiesCollection
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> addCompany(
    Map<String, dynamic> data,
  ) {
    final payload = {...data, 'active': data['active'] ?? true};
    return _companiesCollection.add(withCreateTimestamps(payload));
  }

  Future<void> updateCompany(String id, Map<String, dynamic> data) {
    return _companiesCollection.doc(id).update(withUpdateTimestamp(data));
  }

  Future<void> deactivateCompany(String id) {
    return _companiesCollection
        .doc(id)
        .update(withUpdateTimestamp({'active': false}));
  }

  Future<void> deleteCompany(String id) {
    return _companiesCollection.doc(id).delete();
  }
}
