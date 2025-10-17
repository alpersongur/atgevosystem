import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/modules/tenant/services/tenant_service.dart';

import '../models/module_access_model.dart';

class ModuleAccessService {
  ModuleAccessService._();

  static final ModuleAccessService instance = ModuleAccessService._();

  FirebaseFirestore get _firestore => TenantService.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('system_modules');

  Stream<List<ModuleAccessModel>> getModulesStream() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ModuleAccessModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> toggleModuleActive(String id, bool isActive) {
    return _collection.doc(id).update({'is_active': isActive});
  }

  Future<void> addModule(String id, Map<String, dynamic> data) {
    final docRef = _collection.doc(id);
    return docRef.set({
      'name': data['name'] ?? '',
      'description': data['description'] ?? '',
      'is_active': data['is_active'] ?? true,
    });
  }
}
