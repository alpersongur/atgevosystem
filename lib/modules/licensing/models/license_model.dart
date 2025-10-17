import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class LicenseModel extends Equatable {
  const LicenseModel({
    required this.id,
    required this.modules,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final List<String> modules;
  final DateTime? startDate;
  final DateTime? endDate;
  final num price;
  final String currency;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'active';
  int? get remainingDays {
    final end = endDate;
    if (end == null) return null;
    return end.difference(DateTime.now()).inDays;
  }

  LicenseModel copyWith({
    String? id,
    List<String>? modules,
    DateTime? startDate,
    DateTime? endDate,
    num? price,
    String? currency,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LicenseModel(
      id: id ?? this.id,
      modules: modules ?? this.modules,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static LicenseModel fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return LicenseModel(
      id: snapshot.id,
      modules: List<String>.from(data['modules'] as List? ?? const []),
      startDate: _toDate(data['start_date']),
      endDate: _toDate(data['end_date']),
      price: data['price'] as num? ?? 0,
      currency: (data['currency'] as String? ?? 'TRY').toUpperCase(),
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'modules': modules,
      'start_date': startDate,
      'end_date': endDate,
      'price': price,
      'currency': currency,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
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
    modules,
    startDate,
    endDate,
    price,
    currency,
    status,
    createdAt,
    updatedAt,
  ];
}
