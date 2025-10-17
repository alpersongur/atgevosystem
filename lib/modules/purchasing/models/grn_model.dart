import 'package:cloud_firestore/cloud_firestore.dart';

class GRNModel {
  const GRNModel({
    required this.id,
    required this.poId,
    required this.supplierId,
    required this.receiptNo,
    required this.lines,
    required this.receivedDate,
    required this.warehouse,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory GRNModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return GRNModel.fromMap(doc.id, data);
  }

  factory GRNModel.fromMap(String id, Map<String, dynamic> data) {
    final linesData = data['lines'] as List<dynamic>? ?? const [];
    return GRNModel(
      id: id,
      poId: (data['po_id'] as String? ?? '').trim(),
      supplierId: (data['supplier_id'] as String? ?? '').trim(),
      receiptNo: (data['receipt_no'] as String? ?? '').trim(),
      lines: linesData
          .map((line) => GRNLine.fromMap(Map<String, dynamic>.from(line)))
          .toList(growable: false),
      receivedDate: _toDate(data['received_date']),
      warehouse: (data['warehouse'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'received').trim(),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
      createdBy: (data['created_by'] as String?)?.trim(),
    );
  }

  final String id;
  final String poId;
  final String supplierId;
  final String receiptNo;
  final List<GRNLine> lines;
  final DateTime? receivedDate;
  final String warehouse;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final payload = <String, dynamic>{
      'po_id': poId,
      'supplier_id': supplierId,
      'receipt_no': receiptNo,
      'lines': lines.map((line) => line.toMap()).toList(growable: false),
      'received_date': receivedDate != null
          ? Timestamp.fromDate(receivedDate!)
          : null,
      'warehouse': warehouse,
      'status': status,
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

class GRNLine {
  const GRNLine({
    required this.sku,
    required this.receivedQty,
    required this.unit,
  });

  factory GRNLine.fromMap(Map<String, dynamic> data) {
    return GRNLine(
      sku: (data['sku'] as String? ?? '').trim(),
      receivedQty: (data['received_qty'] as num?)?.toDouble() ?? 0,
      unit: (data['unit'] as String? ?? '').trim(),
    );
  }

  final String sku;
  final double receivedQty;
  final String unit;

  Map<String, dynamic> toMap() {
    return {'sku': sku, 'received_qty': receivedQty, 'unit': unit};
  }
}
