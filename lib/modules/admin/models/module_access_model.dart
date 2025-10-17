import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleAccessModel {
  const ModuleAccessModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory ModuleAccessModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ModuleAccessModel(
      id: doc.id,
      name: (data['name'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      isActive: data['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'description': description, 'is_active': isActive};
  }

  final String id;
  final String name;
  final String description;
  final bool isActive;

  ModuleAccessModel copyWith({
    String? name,
    String? description,
    bool? isActive,
  }) {
    return ModuleAccessModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
