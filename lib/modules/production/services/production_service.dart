import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import '../models/production_order_model.dart';

class ProductionService with FirestoreTimestamps {
  ProductionService._(this._firestore);

  factory ProductionService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return ProductionService._(firestore);
  }

  static final ProductionService instance = ProductionService._(
    FirebaseFirestore.instance,
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('production_orders');

  Future<String> addOrder(Map<String, dynamic> data) async {
    final payload = withCreateTimestamps(data);
    final docRef = await _collection.add(payload);
    return docRef.id;
  }

  Future<void> updateOrderStatus(String id, String newStatus) {
    final payload = withUpdateTimestamp({'status': newStatus});
    return _collection.doc(id).update(payload);
  }

  Stream<List<ProductionOrderModel>> getOrdersStream() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ProductionOrderModel.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<ProductionOrderModel?> watchOrder(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return ProductionOrderModel.fromDocument(snapshot);
    });
  }

  Future<ProductionOrderModel?> getOrderById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ProductionOrderModel.fromDocument(doc);
  }
}
