import 'package:cloud_firestore/cloud_firestore.dart';

class ShipmentModel {
  const ShipmentModel({
    required this.id,
    required this.productionOrderId,
    required this.customerId,
    required this.shipmentNo,
    required this.carrier,
    required this.vehiclePlate,
    required this.driverName,
    required this.status,
    this.departureDate,
    this.deliveryDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.inventoryItemId,
  });

  factory ShipmentModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShipmentModel.fromMap(doc.id, data);
  }

  factory ShipmentModel.fromMap(String id, Map<String, dynamic> data) {
    return ShipmentModel(
      id: id,
      productionOrderId: (data['production_order_id'] as String? ?? '').trim(),
      customerId: (data['customer_id'] as String? ?? '').trim(),
      shipmentNo: (data['shipment_no'] as String? ?? '').trim(),
      carrier: (data['carrier'] as String? ?? '').trim(),
      vehiclePlate: (data['vehicle_plate'] as String? ?? '').trim(),
      driverName: (data['driver_name'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'preparing').trim(),
      departureDate: _toDate(data['departure_date']),
      deliveryDate: _toDate(data['delivery_date']),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
      inventoryItemId: (data['inventory_item_id'] as String?)?.trim(),
    );
  }

  final String id;
  final String productionOrderId;
  final String customerId;
  final String shipmentNo;
  final String carrier;
  final String vehiclePlate;
  final String driverName;
  final String status;
  final DateTime? departureDate;
  final DateTime? deliveryDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? inventoryItemId;

  bool get isDelivered => status == 'delivered';

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'production_order_id': productionOrderId,
      'customer_id': customerId,
      'shipment_no': shipmentNo,
      'carrier': carrier,
      'vehicle_plate': vehiclePlate,
      'driver_name': driverName,
      'status': status,
      'departure_date': departureDate != null
          ? Timestamp.fromDate(departureDate!)
          : null,
      'delivery_date': deliveryDate != null
          ? Timestamp.fromDate(deliveryDate!)
          : null,
      'notes': notes,
      'inventory_item_id': inventoryItemId,
    };

    map.removeWhere((_, value) => value == null);

    if (includeTimestamps) {
      map['created_at'] = createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp();
      map['updated_at'] = updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp();
    }

    return map;
  }

  ShipmentModel copyWith({
    String? status,
    DateTime? departureDate,
    DateTime? deliveryDate,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ShipmentModel(
      id: id,
      productionOrderId: productionOrderId,
      customerId: customerId,
      shipmentNo: shipmentNo,
      carrier: carrier,
      vehiclePlate: vehiclePlate,
      driverName: driverName,
      status: status ?? this.status,
      departureDate: departureDate ?? this.departureDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      inventoryItemId: inventoryItemId,
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
