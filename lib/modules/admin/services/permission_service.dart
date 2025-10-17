import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPermissionService {
  AdminPermissionService._();

  static final AdminPermissionService instance = AdminPermissionService._();

  final CollectionReference<Map<String, dynamic>> _permissionsCollection =
      FirebaseFirestore.instance.collection('permissions');

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPermissions() {
    return _permissionsCollection.snapshots();
  }

  Future<void> updatePermission(String module, Map<String, dynamic> data) {
    return _permissionsCollection
        .doc(module)
        .set(data, SetOptions(merge: true));
  }

  Future<void> addModule(String moduleName) {
    return _permissionsCollection.doc(moduleName).set({});
  }
}
