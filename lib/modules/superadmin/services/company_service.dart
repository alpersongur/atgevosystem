import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyService {
  CompanyService._();

  static final CompanyService instance = CompanyService._();

  final CollectionReference<Map<String, dynamic>> _companiesCollection =
      FirebaseFirestore.instance.collection('companies');

  Stream<QuerySnapshot<Map<String, dynamic>>> getCompanies() {
    return _companiesCollection.orderBy('created_at', descending: true).snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> addCompany(
    Map<String, dynamic> data,
  ) {
    return _companiesCollection.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'active': data['active'] ?? true,
    });
  }

  Future<void> updateCompany(String id, Map<String, dynamic> data) {
    return _companiesCollection.doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deactivateCompany(String id) {
    return _companiesCollection.doc(id).update({
      'active': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCompany(String id) {
    return _companiesCollection.doc(id).delete();
  }
}
