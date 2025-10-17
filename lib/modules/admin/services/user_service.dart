import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  UserService._(this._firestore);

  factory UserService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return UserService._(firestore);
  }

  static final UserService instance = UserService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  Stream<List<UserModel>> getUsersStream() {
    return _collection
        .orderBy('display_name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(UserModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsers() {
    return _collection.orderBy('display_name').snapshots();
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUserRole(String uid, String role) {
    return _collection.doc(uid).update({
      'role': role,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleUserActive(String uid, bool isActive) {
    return _collection.doc(uid).update({
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignModules(String uid, List<String> modules) {
    return _collection.doc(uid).update({
      'modules': modules,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _collection.doc(uid).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addUser(Map<String, dynamic> data) async {
    final uid = (data['uid'] as String? ?? '').trim();
    final docRef = uid.isNotEmpty ? _collection.doc(uid) : _collection.doc();
    final payload = {
      'uid': uid.isNotEmpty ? uid : docRef.id,
      'email': (data['email'] as String? ?? '').trim(),
      'display_name': (data['display_name'] as String? ?? '').trim(),
      'role': (data['role'] as String? ?? 'user').trim(),
      'is_active': data['is_active'] as bool? ?? true,
      'modules': (data['modules'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> deactivateUser(String uid) {
    return toggleUserActive(uid, false);
  }
}
