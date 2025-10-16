import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleService {
  ModuleService._();

  static final ModuleService instance = ModuleService._();

  final CollectionReference<Map<String, dynamic>> _modulesCollection =
      FirebaseFirestore.instance.collection('modules');

  Stream<QuerySnapshot<Map<String, dynamic>>> getModules() {
    return _modulesCollection.snapshots();
  }

  Future<void> updateModuleStatus(String moduleId, bool active) {
    return _modulesCollection.doc(moduleId).update({
      'active': active,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addModule(Map<String, dynamic> moduleData) {
    return _modulesCollection.add({
      ...moduleData,
      'created_at': FieldValue.serverTimestamp(),
      'active': moduleData['active'] ?? true,
    });
  }
}
