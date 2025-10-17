import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';
import 'package:atgevosystem/modules/tenant/services/tenant_service.dart';

import '../models/role_model.dart';

class RoleService with FirestoreTimestamps {
  RoleService._();

  static final RoleService instance = RoleService._();

  FirebaseFirestore get _firestore => TenantService.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('roles');

  Stream<List<RoleModel>> getRolesStream() {
    return _collection
        .orderBy('role_name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<RoleModel?> getRoleById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return RoleModel.fromFirestore(doc);
  }

  Future<String> addRole(Map<String, dynamic> data) async {
    final payload = withCreateTimestamps(data);
    final ref = await _collection.add(payload);
    return ref.id;
  }

  Future<void> updateRole(String id, Map<String, dynamic> data) {
    final payload = withUpdateTimestamp(data);
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteRole(String id) {
    return _collection.doc(id).delete();
  }
}
