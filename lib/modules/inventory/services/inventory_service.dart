import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inventory_item_model.dart';

class InventoryService {
  InventoryService._(this._firestore);

  factory InventoryService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return InventoryService._(firestore);
  }

  static final InventoryService instance =
      InventoryService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('inventory');

  Stream<List<InventoryItemModel>> getInventoryStream() {
    return _collection
        .orderBy('product_name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InventoryItemModel.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<InventoryItemModel?> watchItem(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return InventoryItemModel.fromDocument(snapshot);
    });
  }

  Future<InventoryItemModel?> getItem(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return InventoryItemModel.fromDocument(doc);
  }

  Future<String> addItem(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();
    final docRef = await _collection.add(payload);
    return docRef.id;
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = FieldValue.serverTimestamp();
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteItem(String id) {
    return _collection.doc(id).delete();
  }

  Future<void> adjustStock(
    String id,
    int amount,
    String operation,
  ) async {
    if (amount <= 0) {
      throw ArgumentError('amount must be greater than zero');
    }

    final increment = operation == 'decrease' ? -amount : amount;
    await _firestore.runTransaction((transaction) async {
      final docRef = _collection.doc(id);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw StateError('Envanter ürünü bulunamadı.');
      }

      final currentQuantity =
          (snapshot.data()?['quantity'] as num?)?.toInt() ?? 0;
      final newQuantity = currentQuantity + increment;
      if (newQuantity < 0) {
        throw StateError('Stok miktarı sıfırın altına düşemez.');
      }

      transaction.update(docRef, {
        'quantity': newQuantity,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
