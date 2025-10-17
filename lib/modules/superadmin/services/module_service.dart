import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

class ModuleService with FirestoreTimestamps {
  ModuleService._();

  static final ModuleService instance = ModuleService._();

  final CollectionReference<Map<String, dynamic>> _modulesCollection =
      FirebaseFirestore.instance.collection('modules');

  Stream<QuerySnapshot<Map<String, dynamic>>> getModules() {
    return _modulesCollection.snapshots();
  }

  Future<void> updateModuleStatus(String moduleId, bool active) {
    return _modulesCollection
        .doc(moduleId)
        .update(withUpdateTimestamp({'active': active}));
  }

  Future<void> addModule(Map<String, dynamic> moduleData) {
    final payload = {...moduleData, 'active': moduleData['active'] ?? true};
    return _modulesCollection.add(withCreateTimestamps(payload));
  }
}
