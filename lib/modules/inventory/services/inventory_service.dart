import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import 'package:atgevosystem/core/models/inventory_item.dart';

class InventoryService with FirestoreTimestamps {
  InventoryService._(this._firestore);

  factory InventoryService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return InventoryService._(firestore);
    }
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return instance;
  }

  static InventoryService? _instance;
  static InventoryService? _testInstance;

  static InventoryService get instance {
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return _instance ??= InventoryService._(FirebaseFirestore.instance);
  }

  @visibleForTesting
  static void setTestInstance(InventoryService service) {
    _testInstance = service;
  }

  @visibleForTesting
  static void resetTestInstance() {
    _testInstance = null;
  }

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
    final payload = withCreateTimestamps(data);
    final docRef = await _collection.add(payload);
    return docRef.id;
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) {
    final payload = withUpdateTimestamp(data);
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteItem(String id) {
    return _collection.doc(id).delete();
  }

  Future<void> adjustStock(String id, int amount, String operation) async {
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

      transaction.update(
        docRef,
        withUpdateTimestamp({'quantity': newQuantity}),
      );
    });
  }
}
