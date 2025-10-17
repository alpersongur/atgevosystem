import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  const BillModel({
    required this.id,
    required this.poId,
    required this.supplierId,
    required this.billNo,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.subtotal,
    required this.taxRate,
    required this.taxTotal,
    required this.grandTotal,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory BillModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BillModel.fromMap(doc.id, data);
  }

  factory BillModel.fromMap(String id, Map<String, dynamic> data) {
    return BillModel(
      id: id,
      poId: (data['po_id'] as String? ?? '').trim(),
      supplierId: (data['supplier_id'] as String? ?? '').trim(),
      billNo: (data['bill_no'] as String? ?? '').trim(),
      issueDate: _toDate(data['issue_date']),
      dueDate: _toDate(data['due_date']),
      currency: (data['currency'] as String? ?? 'TRY').trim(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      taxRate: (data['tax_rate'] as num?)?.toDouble() ?? 0,
      taxTotal: (data['tax_total'] as num?)?.toDouble() ?? 0,
      grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0,
      status: (data['status'] as String? ?? 'unpaid').trim(),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
      createdBy: (data['created_by'] as String?)?.trim(),
    );
  }

  final String id;
  final String poId;
  final String supplierId;
  final String billNo;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String currency;
  final double subtotal;
  final double taxRate;
  final double taxTotal;
  final double grandTotal;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final payload = <String, dynamic>{
      'po_id': poId,
      'supplier_id': supplierId,
      'bill_no': billNo,
      'issue_date': issueDate != null ? Timestamp.fromDate(issueDate!) : null,
      'due_date': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'currency': currency,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_total': taxTotal,
      'grand_total': grandTotal,
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
