import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _cachedRole;
  String? _cachedDepartment;

  String? get cachedRole => _cachedRole;
  String? get cachedDepartment => _cachedDepartment;
  User? get currentUser => _auth.currentUser;
  String? get currentUserRole => _cachedRole;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final profile = await getUserProfile(user.uid);
      if (profile != null && profile.exists) {
        final data = profile.data() ?? <String, dynamic>{};
        _cachedRole = data['role'] as String?;
        _cachedDepartment = data['department'] as String?;
      } else {
        _cachedRole = null;
        _cachedDepartment = null;
      }
    }

    return credential;
  }

  Future<void> logout() async {
    await _auth.signOut();
    _cachedRole = null;
    _cachedDepartment = null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }
}
