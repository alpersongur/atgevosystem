import 'package:cloud_firestore/cloud_firestore.dart';

class RoleModel {
  const RoleModel({
    required this.id,
    required this.roleName,
    required this.permissions,
    required this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory RoleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return RoleModel(
      id: doc.id,
      roleName: (data['role_name'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      permissions: (data['permissions'] as Map<String, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key, value == true)),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final payload = <String, dynamic>{
      'role_name': roleName,
      'description': description,
      'permissions': permissions,
    };

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

  final String id;
  final String roleName;
  final Map<String, bool> permissions;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoleModel copyWith({
    String? roleName,
    Map<String, bool>? permissions,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleModel(
      id: id,
      roleName: roleName ?? this.roleName,
      permissions: permissions ?? this.permissions,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
