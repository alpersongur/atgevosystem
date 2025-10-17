import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/modules/tenant/services/tenant_service.dart';

class AdminPermissionService {
  AdminPermissionService._();

  static final AdminPermissionService instance = AdminPermissionService._();

  CollectionReference<Map<String, dynamic>> get _permissionsCollection =>
      TenantService.instance.tenantCollection('permissions');

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
