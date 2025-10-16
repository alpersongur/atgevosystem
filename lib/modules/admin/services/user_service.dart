import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final CollectionReference<Map<String, dynamic>> _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> addUser(Map<String, dynamic> data) async {
    final providedUid = (data['uid'] as String?)?.trim();
    final docRef = providedUid != null && providedUid.isNotEmpty
        ? _usersCollection.doc(providedUid)
        : _usersCollection.doc();

    final payload = {
      ...data,
      'uid': providedUid?.isNotEmpty == true ? providedUid : docRef.id,
      'created_at': data['created_at'] ?? FieldValue.serverTimestamp(),
      'active': data['active'] ?? true,
    };

    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _usersCollection.doc(uid).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deactivateUser(String uid) {
    return _usersCollection.doc(uid).update({
      'active': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsers() {
    return _usersCollection.orderBy('created_at', descending: true).snapshots();
  }
}
