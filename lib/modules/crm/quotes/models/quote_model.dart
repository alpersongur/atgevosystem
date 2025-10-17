import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteModel {
  const QuoteModel({
    required this.id,
    required this.customerId,
    required this.quoteNumber,
    required this.title,
    required this.amount,
    required this.currency,
    required this.status,
    this.validUntil,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.notes,
    this.pdfUrl,
  });

  factory QuoteModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return QuoteModel.fromMap(doc.id, data);
  }

  factory QuoteModel.fromMap(String id, Map<String, dynamic> data) {
    return QuoteModel(
      id: id,
      customerId: (data['customer_id'] as String? ?? '').trim(),
      quoteNumber: (data['quote_number'] as String? ?? '').trim(),
      title: (data['title'] as String? ?? '').trim(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] as String? ?? 'TRY').trim(),
      status: (data['status'] as String? ?? 'pending').trim(),
      validUntil: _toDate(data['valid_until']),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
      createdBy: (data['created_by'] as String?)?.trim(),
      notes: (data['notes'] as String?)?.trim(),
      pdfUrl: (data['pdf_url'] as String?)?.trim(),
    );
  }

  final String id;
  final String customerId;
  final String quoteNumber;
  final String title;
  final double amount;
  final String currency;
  final String status;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? notes;
  final String? pdfUrl;

  bool get isExpired {
    if (validUntil == null) return false;
    final today = DateTime.now();
    return validUntil!.isBefore(DateTime(today.year, today.month, today.day));
  }

  QuoteModel copyWith({
    String? customerId,
    String? quoteNumber,
    String? title,
    double? amount,
    String? currency,
    String? status,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? notes,
    String? pdfUrl,
  }) {
    return QuoteModel(
      id: id,
      customerId: customerId ?? this.customerId,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'customer_id': customerId,
      'quote_number': quoteNumber,
      'title': title,
      'amount': amount,
      'currency': currency,
      'status': status,
      'valid_until': validUntil != null
          ? Timestamp.fromDate(validUntil!)
          : null,
      'created_by': createdBy,
      'notes': notes,
      'pdf_url': pdfUrl,
    };

    map.removeWhere((key, value) => value == null);

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
