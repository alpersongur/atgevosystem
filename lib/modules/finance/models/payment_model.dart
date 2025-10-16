import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.customerId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.paymentDate,
    this.txnRef,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory PaymentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PaymentModel.fromMap(doc.id, data);
  }

  factory PaymentModel.fromMap(String id, Map<String, dynamic> data) {
    return PaymentModel(
      id: id,
      invoiceId: (data['invoice_id'] as String? ?? '').trim(),
      customerId: (data['customer_id'] as String? ?? '').trim(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] as String? ?? 'TRY').trim(),
      method: (data['method'] as String? ?? 'transfer').trim(),
      paymentDate: _toDate(data['payment_date']),
      txnRef: (data['txn_ref'] as String?)?.trim(),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
      createdBy: (data['created_by'] as String?)?.trim(),
    );
  }

  final String id;
  final String invoiceId;
  final String customerId;
  final double amount;
  final String currency;
  final String method;
  final DateTime? paymentDate;
  final String? txnRef;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final payload = <String, dynamic>{
      'invoice_id': invoiceId,
      'customer_id': customerId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'payment_date': paymentDate != null
          ? Timestamp.fromDate(paymentDate!)
          : null,
      'txn_ref': txnRef,
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
