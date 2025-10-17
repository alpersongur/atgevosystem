import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import '../models/user_model.dart';

class UserService with FirestoreTimestamps {
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
    return _collection.doc(uid).update(withUpdateTimestamp({'role': role}));
  }

  Future<void> toggleUserActive(String uid, bool isActive) {
    return _collection
        .doc(uid)
        .update(withUpdateTimestamp({'is_active': isActive}));
  }

  Future<void> assignModules(String uid, List<String> modules) {
    return _collection
        .doc(uid)
        .update(withUpdateTimestamp({'modules': modules}));
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _collection.doc(uid).update(withUpdateTimestamp(data));
  }

  Future<void> addUser(Map<String, dynamic> data) async {
    final uid = (data['uid'] as String? ?? '').trim();
    final docRef = uid.isNotEmpty ? _collection.doc(uid) : _collection.doc();
    final basePayload = {
      'uid': uid.isNotEmpty ? uid : docRef.id,
      'email': (data['email'] as String? ?? '').trim(),
      'display_name': (data['display_name'] as String? ?? '').trim(),
      'role': (data['role'] as String? ?? 'user').trim(),
      'is_active': data['is_active'] as bool? ?? true,
      'modules': (data['modules'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    };
    await docRef.set(
      withCreateTimestamps(basePayload),
      SetOptions(merge: true),
    );
  }

  Future<void> deactivateUser(String uid) {
    return toggleUserActive(uid, false);
  }
}
