import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.customerId,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.subtotal,
    required this.taxRate,
    required this.taxTotal,
    required this.grandTotal,
    required this.status,
    this.quoteId,
    this.shipmentId,
    this.notes,
    this.attachmentUrl,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory InvoiceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return InvoiceModel.fromMap(doc.id, data);
  }

  factory InvoiceModel.fromMap(String id, Map<String, dynamic> data) {
    return InvoiceModel(
      id: id,
      invoiceNo: (data['invoice_no'] as String? ?? '').trim(),
      customerId: (data['customer_id'] as String? ?? '').trim(),
      issueDate: _toDate(data['issue_date']),
      dueDate: _toDate(data['due_date']),
      currency: (data['currency'] as String? ?? 'TRY').trim(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      taxRate: (data['tax_rate'] as num?)?.toDouble() ?? 0,
      taxTotal: (data['tax_total'] as num?)?.toDouble() ?? 0,
      grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0,
      status: (data['status'] as String? ?? 'unpaid').trim(),
      quoteId: (data['quote_id'] as String?)?.trim(),
      shipmentId: (data['shipment_id'] as String?)?.trim(),
      notes: (data['notes'] as String?)?.trim(),
      attachmentUrl: (data['attachment_url'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
      createdBy: (data['created_by'] as String?)?.trim(),
    );
  }

  final String id;
  final String invoiceNo;
  final String customerId;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String currency;
  final double subtotal;
  final double taxRate;
  final double taxTotal;
  final double grandTotal;
  final String status;
  final String? quoteId;
  final String? shipmentId;
  final String? notes;
  final String? attachmentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final payload = <String, dynamic>{
      'invoice_no': invoiceNo,
      'quote_id': quoteId,
      'shipment_id': shipmentId,
      'customer_id': customerId,
      'issue_date': issueDate != null ? Timestamp.fromDate(issueDate!) : null,
      'due_date': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'currency': currency,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_total': taxTotal,
      'grand_total': grandTotal,
      'status': status,
      'notes': notes,
      'attachment_url': attachmentUrl,
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

  InvoiceModel copyWith({
    String? invoiceNo,
    String? customerId,
    double? subtotal,
    double? taxRate,
    double? taxTotal,
    double? grandTotal,
    String? status,
    String? notes,
    String? attachmentUrl,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceModel(
      id: id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customerId: customerId ?? this.customerId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      currency: currency,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxTotal: taxTotal ?? this.taxTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      quoteId: quoteId,
      shipmentId: shipmentId,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
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
