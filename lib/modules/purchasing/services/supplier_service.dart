import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import '../models/supplier_model.dart';

class SupplierService with FirestoreTimestamps {
  SupplierService._(this._firestore);

  factory SupplierService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return SupplierService._(firestore);
  }

  static final SupplierService instance = SupplierService._(
    FirebaseFirestore.instance,
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('suppliers');

  Stream<List<SupplierModel>> getSuppliers() {
    return _collection
        .orderBy('supplier_name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SupplierModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<SupplierModel?> watchSupplier(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return SupplierModel.fromFirestore(snapshot);
    });
  }

  Future<SupplierModel?> getSupplierById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return SupplierModel.fromFirestore(doc);
  }

  Future<String> addSupplier(Map<String, dynamic> data) async {
    final payload = withCreateTimestamps(data);
    final ref = await _collection.add(payload);
    return ref.id;
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> data) {
    final payload = withUpdateTimestamp(data);
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteSupplier(String id) {
    return _collection.doc(id).delete();
  }
}
