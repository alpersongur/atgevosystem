import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.supplierName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    required this.taxNumber,
    required this.paymentTerms,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory SupplierModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return SupplierModel.fromMap(doc.id, data);
  }

  factory SupplierModel.fromMap(String id, Map<String, dynamic> data) {
    return SupplierModel(
      id: id,
      supplierName: (data['supplier_name'] as String? ?? '').trim(),
      contactPerson: (data['contact_person'] as String? ?? '').trim(),
      email: (data['email'] as String? ?? '').trim(),
      phone: (data['phone'] as String? ?? '').trim(),
      address: (data['address'] as String? ?? '').trim(),
      city: (data['city'] as String? ?? '').trim(),
      country: (data['country'] as String? ?? '').trim(),
      taxNumber: (data['tax_number'] as String? ?? '').trim(),
      paymentTerms: (data['payment_terms'] as String? ?? 'net30').trim(),
      status: (data['status'] as String? ?? 'active').trim(),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
      createdBy: (data['created_by'] as String?)?.trim(),
    );
  }

  final String id;
  final String supplierName;
  final String contactPerson;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String taxNumber;
  final String paymentTerms;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final payload = <String, dynamic>{
      'supplier_name': supplierName,
      'contact_person': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'tax_number': taxNumber,
      'payment_terms': paymentTerms,
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

  SupplierModel copyWith({
    String? supplierName,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? taxNumber,
    String? paymentTerms,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return SupplierModel(
      id: id,
      supplierName: supplierName ?? this.supplierName,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      taxNumber: taxNumber ?? this.taxNumber,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      status: status ?? this.status,
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
