import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:meta/meta.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';
import 'package:atgevosystem/modules/tenant/services/tenant_service.dart';

import '../models/user_model.dart';

class UserService with FirestoreTimestamps {
  UserService._(this._firestoreProvider);

  factory UserService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return UserService._(() => firestore);
    }
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return instance;
  }

  static UserService? _instance;
  static UserService? _testInstance;

  static UserService get instance {
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return _instance ??=
        UserService._(() => TenantService.instance.firestore);
  }

  @visibleForTesting
  static void setTestInstance(UserService service) {
    _testInstance = service;
  }

  @visibleForTesting
  static void resetTestInstance() {
    _testInstance = null;
  }

  final FirebaseFirestore Function() _firestoreProvider;

  FirebaseFirestore get _firestore => _firestoreProvider();

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
    final doc = await _collection
        .doc(uid)
        .get(const GetOptions(source: Source.serverAndCache));
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

  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required List<String> modules,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'createUserWithRole',
    );
    await callable.call({
      'email': email,
      'password': password,
      'displayName': displayName,
      'role': role,
      'modules': modules,
    });
  }
}
