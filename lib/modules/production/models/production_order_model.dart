import 'package:cloud_firestore/cloud_firestore.dart';

class ProductionOrderModel {
  const ProductionOrderModel({
    required this.id,
    required this.quoteId,
    required this.customerId,
    required this.status,
    this.inventoryItemId,
    this.startDate,
    this.estimatedCompletion,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductionOrderModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ProductionOrderModel.fromMap(doc.id, data);
  }

  factory ProductionOrderModel.fromMap(String id, Map<String, dynamic> data) {
    return ProductionOrderModel(
      id: id,
      quoteId: (data['quote_id'] as String? ?? '').trim(),
      customerId: (data['customer_id'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'waiting').trim(),
      inventoryItemId: (data['inventory_item_id'] as String?)?.trim(),
      startDate: _toDate(data['start_date']),
      estimatedCompletion: _toDate(data['estimated_completion']),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
    );
  }

  final String id;
  final String quoteId;
  final String customerId;
  final String status;
  final String? inventoryItemId;
  final DateTime? startDate;
  final DateTime? estimatedCompletion;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'quote_id': quoteId,
      'customer_id': customerId,
      'status': status,
      'inventory_item_id': inventoryItemId,
      'start_date':
          startDate != null ? Timestamp.fromDate(startDate!) : null,
      'estimated_completion': estimatedCompletion != null
          ? Timestamp.fromDate(estimatedCompletion!)
          : null,
      'notes': notes,
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

  ProductionOrderModel copyWith({
    String? status,
    DateTime? startDate,
    DateTime? estimatedCompletion,
    String? notes,
    DateTime? updatedAt,
    String? inventoryItemId,
  }) {
    return ProductionOrderModel(
      id: id,
      quoteId: quoteId,
      customerId: customerId,
      status: status ?? this.status,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      startDate: startDate ?? this.startDate,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
