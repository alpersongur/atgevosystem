import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/role_model.dart';

class RoleService {
  RoleService._(this._firestore);

  factory RoleService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return RoleService._(firestore);
  }

  static final RoleService instance = RoleService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

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
    final payload = Map<String, dynamic>.from(data)
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();
    final ref = await _collection.add(payload);
    return ref.id;
  }

  Future<void> updateRole(String id, Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = FieldValue.serverTimestamp();
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteRole(String id) {
    return _collection.doc(id).delete();
  }
}
