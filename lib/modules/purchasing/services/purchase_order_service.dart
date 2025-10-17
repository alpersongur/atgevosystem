import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/purchase_order_model.dart';

class PurchaseOrderService {
  PurchaseOrderService._(this._firestore);

  factory PurchaseOrderService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return PurchaseOrderService._(firestore);
  }

  static final PurchaseOrderService instance = PurchaseOrderService._(
    FirebaseFirestore.instance,
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('purchase_orders');

  Stream<List<PurchaseOrderModel>> getPOs() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PurchaseOrderModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<PurchaseOrderModel?> watchPO(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return PurchaseOrderModel.fromFirestore(snapshot);
    });
  }

  Future<PurchaseOrderModel?> getPOById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return PurchaseOrderModel.fromFirestore(doc);
  }

  Future<String> addPO(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();
    final ref = await _collection.add(payload);
    return ref.id;
  }

  Future<void> updatePO(String id, Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = FieldValue.serverTimestamp();
    return _collection.doc(id).update(payload);
  }

  Future<void> cancelPO(String id) {
    return _collection.doc(id).update({
      'status': 'canceled',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String id, String status) {
    return _collection.doc(id).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePO(String id) {
    return _collection.doc(id).delete();
  }
}
