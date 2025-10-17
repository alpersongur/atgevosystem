import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.companyName,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.taxNumber,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CustomerModel(
      id: doc.id,
      companyName: (data['company_name'] as String? ?? '').trim(),
      contactPerson: (data['contact_person'] as String?)?.trim(),
      email: (data['email'] as String?)?.trim(),
      phone: (data['phone'] as String?)?.trim(),
      address: (data['address'] as String?)?.trim(),
      city: (data['city'] as String?)?.trim(),
      taxNumber: (data['tax_number'] as String?)?.trim(),
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _timestampToDate(data['created_at']),
      updatedAt: _timestampToDate(data['updated_at']),
    );
  }

  final String id;
  final String companyName;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? taxNumber;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerModel copyWith({
    String? companyName,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? taxNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      taxNumber: taxNumber ?? this.taxNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool matchesSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return [
      companyName,
      contactPerson ?? '',
      email ?? '',
      phone ?? '',
      address ?? '',
      city ?? '',
      taxNumber ?? '',
      notes ?? '',
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }

  Map<String, Object?> toMap({bool includeTimestamps = false}) {
    final map = <String, Object?>{
      'company_name': companyName.trim(),
      'contact_person': contactPerson?.trim(),
      'email': email?.trim(),
      'phone': phone?.trim(),
      'address': address?.trim(),
      'city': city?.trim(),
      'tax_number': taxNumber?.trim(),
      'notes': notes?.trim(),
    };

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

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class CustomerInput {
  CustomerInput({
    required String companyName,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? taxNumber,
    String? notes,
  }) : companyName = companyName.trim(),
       contactPerson = _normalize(contactPerson),
       email = _normalize(email),
       phone = _normalize(phone),
       address = _normalize(address),
       city = _normalize(city),
       taxNumber = _normalize(taxNumber),
       notes = _normalize(notes);

  final String companyName;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? taxNumber;
  final String? notes;

  Map<String, dynamic> toMap({bool includeUpdatedAt = false}) {
    final payload = <String, dynamic>{
      'company_name': companyName,
      'contact_person': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'tax_number': taxNumber,
      'notes': notes,
    };

    if (includeUpdatedAt) {
      payload['updated_at'] = FieldValue.serverTimestamp();
    }

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
