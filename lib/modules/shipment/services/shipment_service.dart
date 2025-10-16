import 'package:cloud_firestore/cloud_firestore.dart';

import '../../inventory/services/inventory_service.dart';
import '../../production/services/production_service.dart';
import '../models/shipment_model.dart';

class ShipmentService {
  ShipmentService._(this._firestore);

  factory ShipmentService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return ShipmentService._(firestore);
  }

  static final ShipmentService instance =
      ShipmentService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('shipments');

  Stream<List<ShipmentModel>> getShipmentsStream() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ShipmentModel.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<ShipmentModel?> watchShipment(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return ShipmentModel.fromDocument(snapshot);
    });
  }

  Future<ShipmentModel?> getShipmentById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ShipmentModel.fromDocument(doc);
  }

  Future<String> addShipment(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();
    final docRef = await _collection.add(payload);
    return docRef.id;
  }

  Future<void> updateShipment(String id, Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = FieldValue.serverTimestamp();
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteShipment(String id) {
    return _collection.doc(id).delete();
  }

  Future<void> updateStatus(String id, String newStatus) {
    return _collection.doc(id).update({
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
      if (newStatus == 'delivered')
        'delivery_date': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createShipmentForOrder(String orderId) async {
    final order = await ProductionService.instance.getOrderById(orderId);
    if (order == null) {
      throw StateError('Üretim talimatı bulunamadı.');
    }

    final shipmentNo =
        'SHP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final payload = {
      'production_order_id': order.id,
      'customer_id': order.customerId,
      'inventory_item_id': order.inventoryItemId,
      'shipment_no': shipmentNo,
      'carrier': '',
      'vehicle_plate': '',
      'driver_name': '',
      'status': 'preparing',
      'notes': null,
      'departure_date': null,
    };

    await addShipment(payload);

    if (order.inventoryItemId != null) {
      await InventoryService.instance.adjustStock(
        order.inventoryItemId!,
        1,
        'decrease',
      );
    }
  }

  Future<void> adjustInventoryForDelivery(ShipmentModel shipment) async {
    final inventoryId = shipment.inventoryItemId;
    if (inventoryId == null) return;
    await InventoryService.instance.adjustStock(
      inventoryId,
      1,
      'decrease',
    );
  }
}
