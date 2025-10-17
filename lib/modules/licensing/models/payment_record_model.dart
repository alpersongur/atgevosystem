import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PaymentRecordModel extends Equatable {
  const PaymentRecordModel({
    required this.id,
    required this.licenseId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.transactionId,
    required this.paymentDate,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String licenseId;
  final num amount;
  final String currency;
  final String method;
  final String transactionId;
  final DateTime? paymentDate;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  static PaymentRecordModel fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return PaymentRecordModel(
      id: snapshot.id,
      licenseId: (data['license_id'] as String? ?? '').trim(),
      amount: data['amount'] as num? ?? 0,
      currency: (data['currency'] as String? ?? 'TRY').toUpperCase(),
      method: (data['method'] as String? ?? 'manual').toLowerCase(),
      transactionId: (data['transaction_id'] as String? ?? '').trim(),
      paymentDate: _toDate(data['payment_date']),
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'license_id': licenseId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'transaction_id': transactionId,
      'payment_date': paymentDate,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    licenseId,
    amount,
    currency,
    method,
    transactionId,
    paymentDate,
    status,
    notes,
    createdAt,
  ];
}
