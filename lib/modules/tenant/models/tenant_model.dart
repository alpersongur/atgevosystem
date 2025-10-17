import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Çoklu tenant yapısındaki şirket (firma) kayıtlarını temsil eder.
class TenantModel extends Equatable {
  const TenantModel({
    required this.id,
    required this.companyName,
    required this.firebaseProjectId,
    required this.ownerEmail,
    required this.modules,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyName;
  final String firebaseProjectId;
  final String ownerEmail;
  final List<String> modules;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'active';

  TenantModel copyWith({
    String? id,
    String? companyName,
    String? firebaseProjectId,
    String? ownerEmail,
    List<String>? modules,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TenantModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      modules: modules ?? this.modules,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static TenantModel fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return TenantModel(
      id: snapshot.id,
      companyName: (data['company_name'] as String? ?? '').trim(),
      firebaseProjectId: (data['firebase_project_id'] as String? ?? '').trim(),
      ownerEmail: (data['owner_email'] as String? ?? '').trim(),
      modules: List<String>.from(data['modules'] as List? ?? const []),
      status: (data['status'] as String? ?? 'inactive').trim(),
      createdAt: _toDateTime(data['created_at']),
      updatedAt: _toDateTime(data['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'company_name': companyName,
      'firebase_project_id': firebaseProjectId,
      'owner_email': ownerEmail,
      'modules': modules,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, dynamic> toCacheJson() {
    return <String, dynamic>{
      'id': id,
      'company_name': companyName,
      'firebase_project_id': firebaseProjectId,
      'owner_email': ownerEmail,
      'modules': modules,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TenantModel.fromCache(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as String? ?? '',
      companyName: (json['company_name'] as String? ?? '').trim(),
      firebaseProjectId: (json['firebase_project_id'] as String? ?? '').trim(),
      ownerEmail: (json['owner_email'] as String? ?? '').trim(),
      modules: List<String>.from(json['modules'] as List? ?? const []),
      status: (json['status'] as String? ?? 'inactive').trim(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _toDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    companyName,
    firebaseProjectId,
    ownerEmail,
    modules,
    status,
    createdAt,
    updatedAt,
  ];
}
