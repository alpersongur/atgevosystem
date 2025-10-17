import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.modules,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      uid: (data['uid'] as String? ?? doc.id).trim(),
      email: (data['email'] as String? ?? '').trim(),
      displayName: (data['display_name'] as String? ?? '').trim(),
      role: (data['role'] as String? ?? 'user').trim(),
      isActive: data['is_active'] as bool? ?? true,
      modules: (data['modules'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      createdAt: _toDate(data['created_at']),
      updatedAt: _toDate(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'role': role,
      'is_active': isActive,
      'modules': modules,
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

  final String uid;
  final String email;
  final String displayName;
  final String role;
  final bool isActive;
  final List<String> modules;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
