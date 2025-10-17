import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    required this.productName,
    required this.category,
    required this.sku,
    required this.quantity,
    required this.unit,
    required this.location,
    required this.minStock,
    required this.status,
    this.updatedAt,
    this.createdAt,
  });

  factory InventoryItemModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return InventoryItemModel.fromMap(doc.id, data);
  }

  factory InventoryItemModel.fromMap(String id, Map<String, dynamic> data) {
    return InventoryItemModel(
      id: id,
      productName: (data['product_name'] as String? ?? '').trim(),
      category: (data['category'] as String? ?? '').trim(),
      sku: (data['sku'] as String? ?? '').trim(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unit: (data['unit'] as String? ?? '').trim(),
      location: (data['location'] as String? ?? '').trim(),
      minStock: (data['min_stock'] as num?)?.toInt() ?? 0,
      status: (data['status'] as String? ?? 'active').trim(),
      updatedAt: _toDate(data['updated_at']),
      createdAt: _toDate(data['created_at']),
    );
  }

  final String id;
  final String productName;
  final String category;
  final String sku;
  final int quantity;
  final String unit;
  final String location;
  final int minStock;
  final String status;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  bool get isBelowMin => quantity < minStock;

  InventoryItemModel copyWith({
    String? productName,
    String? category,
    String? sku,
    int? quantity,
    String? unit,
    String? location,
    int? minStock,
    String? status,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return InventoryItemModel(
      id: id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      minStock: minStock ?? this.minStock,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final payload = <String, dynamic>{
      'product_name': productName,
      'category': category,
      'sku': sku,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'min_stock': minStock,
      'status': status,
    };

    if (includeTimestamps) {
      payload['created_at'] = createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp();
      payload['updated_at'] = updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp();
    }

    return payload;
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
