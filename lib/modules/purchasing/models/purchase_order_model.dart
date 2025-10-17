import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrderModel {
  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.supplierId,
    required this.lines,
    required this.subtotal,
    required this.taxRate,
    required this.taxTotal,
    required this.grandTotal,
    required this.currency,
    required this.status,
    this.expectedDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory PurchaseOrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PurchaseOrderModel.fromMap(doc.id, data);
  }

  factory PurchaseOrderModel.fromMap(String id, Map<String, dynamic> data) {
    final linesData = data['lines'] as List<dynamic>? ?? const [];
    return PurchaseOrderModel(
      id: id,
      poNumber: (data['po_number'] as String? ?? '').trim(),
      supplierId: (data['supplier_id'] as String? ?? '').trim(),
      lines: linesData
          .map(
            (line) => PurchaseOrderLine.fromMap(
              Map<String, dynamic>.from(line as Map),
            ),
          )
          .toList(growable: false),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      taxRate: (data['tax_rate'] as num?)?.toDouble() ?? 0,
      taxTotal: (data['tax_total'] as num?)?.toDouble() ?? 0,
      grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] as String? ?? 'TRY').trim(),
      status: (data['status'] as String? ?? 'open').trim(),
      expectedDate: _toDate(data['expected_date']),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
      createdBy: (data['created_by'] as String?)?.trim(),
    );
  }

  final String id;
  final String poNumber;
  final String supplierId;
  final List<PurchaseOrderLine> lines;
  final double subtotal;
  final double taxRate;
  final double taxTotal;
  final double grandTotal;
  final String currency;
  final String status;
  final DateTime? expectedDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final payload = <String, dynamic>{
      'po_number': poNumber,
      'supplier_id': supplierId,
      'lines': lines.map((line) => line.toMap()).toList(growable: false),
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_total': taxTotal,
      'grand_total': grandTotal,
      'currency': currency,
      'status': status,
      'expected_date': expectedDate != null
          ? Timestamp.fromDate(expectedDate!)
          : null,
      'notes': notes,
      'created_by': createdBy,
    };

    payload.removeWhere((_, value) => value == null);

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

  PurchaseOrderModel copyWith({
    String? poNumber,
    String? supplierId,
    List<PurchaseOrderLine>? lines,
    double? subtotal,
    double? taxRate,
    double? taxTotal,
    double? grandTotal,
    String? currency,
    String? status,
    DateTime? expectedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PurchaseOrderModel(
      id: id,
      poNumber: poNumber ?? this.poNumber,
      supplierId: supplierId ?? this.supplierId,
      lines: lines ?? this.lines,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxTotal: taxTotal ?? this.taxTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      expectedDate: expectedDate ?? this.expectedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
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

class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.currency,
  });

  factory PurchaseOrderLine.fromMap(Map<String, dynamic> data) {
    return PurchaseOrderLine(
      sku: (data['sku'] as String? ?? '').trim(),
      name: (data['name'] as String? ?? '').trim(),
      quantity: (data['qty'] as num?)?.toDouble() ?? 0,
      unit: (data['unit'] as String? ?? '').trim(),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] as String? ?? 'TRY').trim(),
    );
  }

  final String sku;
  final String name;
  final double quantity;
  final String unit;
  final double price;
  final String currency;

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'name': name,
      'qty': quantity,
      'unit': unit,
      'price': price,
      'currency': currency,
    };
  }

  PurchaseOrderLine copyWith({
    String? sku,
    String? name,
    double? quantity,
    String? unit,
    double? price,
    String? currency,
  }) {
    return PurchaseOrderLine(
      sku: sku ?? this.sku,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      currency: currency ?? this.currency,
    );
  }

  double get lineTotal => quantity * price;
}
