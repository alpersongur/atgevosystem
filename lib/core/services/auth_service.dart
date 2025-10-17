import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class AuthService {
  AuthService._({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static AuthService? _instance;
  static AuthService? _testInstance;

  static AuthService get instance {
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return _instance ??= AuthService._();
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final StreamController<UserProfileState?> _profileController =
      StreamController<UserProfileState?>.broadcast();

  SharedPreferences? _prefs;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  Timer? _refreshDebounce;
  bool _initialized = false;

  UserProfileState? _currentProfile;

  User? get currentUser => _auth.currentUser;
  String? get currentUserRole => _currentProfile?.role;
  List<String> get currentUserModules => _currentProfile?.modules ?? const [];
  bool get isCurrentUserActive => _currentProfile?.isActive ?? true;
  UserProfileState? get currentProfile => _currentProfile;

  String? get cachedRole => _currentProfile?.role;
  String? get cachedDepartment => _currentProfile?.department;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<UserProfileState?> get profileStream => _profileController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();
    _authSubscription = _auth.authStateChanges().listen(_handleAuthStateChange);

    final user = _auth.currentUser;
    if (user != null) {
      final cached = await _loadCachedProfile(user.uid);
      if (cached != null) {
        _updateProfile(cached, persist: false);
      }
    } else {
      _updateProfile(null, persist: false);
    }
  }

  Future<UserCredential> login(String email, String password) async {
    await initialize();

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.reload();
      await user.getIdToken(true);
      final cached = await _loadCachedProfile(user.uid);
      if (cached != null) {
        _updateProfile(cached, persist: false);
      }
    }

    return credential;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _stopProfileSync();
    _updateProfile(null);
  }

  Future<void> refreshCurrentUserProfile({bool serverOnly = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _updateProfile(null);
      return;
    }

    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () async {
      final snapshot = await _fetchUserDoc(user.uid, serverOnly: serverOnly);
      await _hydrateFromSnapshot(user, snapshot, source: ProfileDataSource.api);
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserProfile(
    String uid, {
    bool serverOnly = false,
  }) {
    return _fetchUserDoc(uid, serverOnly: serverOnly);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _stopProfileSync();
    await _profileController.close();
    _refreshDebounce?.cancel();
  }

  Future<void> _handleAuthStateChange(User? user) async {
    await _stopProfileSync();
    if (user == null) {
      _updateProfile(null);
      return;
    }

    await user.reload();
    await user.getIdToken(true);

    final cached = await _loadCachedProfile(user.uid);
    if (cached != null) {
      _updateProfile(cached, persist: false);
    }

    await _startUserProfileSync(user, fromAuthChange: true);
  }

  Future<void> _startUserProfileSync(
    User user, {
    required bool fromAuthChange,
  }) async {
    await _profileSubscription?.cancel();

    final docRef = _firestore.collection('users').doc(user.uid);

    _profileSubscription = docRef.snapshots().listen(
      (snapshot) {
        unawaited(
          _hydrateFromSnapshot(
            user,
            snapshot,
            source: ProfileDataSource.snapshot,
          ),
        );
      },
      onError: (error, stackTrace) {
        debugPrint(
          'Kullanıcı profili dinlenirken hata oluştu: $error\n$stackTrace',
        );
      },
    );

    if (fromAuthChange) {
      final initialSnapshot = await _fetchUserDoc(user.uid, serverOnly: false);
      await _hydrateFromSnapshot(
        user,
        initialSnapshot,
        source: ProfileDataSource.initial,
      );
    }
  }

  Future<void> _stopProfileSync() async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _fetchUserDoc(
    String uid, {
    bool serverOnly = false,
  }) async {
    try {
      final options = GetOptions(
        source: serverOnly ? Source.server : Source.serverAndCache,
      );
      return await _firestore.collection('users').doc(uid).get(options);
    } catch (error, stackTrace) {
      debugPrint('Kullanıcı verisi alınırken hata oluştu: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> _hydrateFromSnapshot(
    User user,
    DocumentSnapshot<Map<String, dynamic>>? snapshot, {
    required ProfileDataSource source,
  }) async {
    if (snapshot == null || !snapshot.exists) {
      debugPrint(
        'Uyarı: ${user.uid} için Firestore kullanıcı dokümanı bulunamadı.',
      );
      _updateProfile(null);
      return;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final profile = UserProfileState(
      uid: user.uid,
      email: (data['email'] as String?)?.trim(),
      displayName: (data['display_name'] as String?)?.trim(),
      role: (data['role'] as String?)?.trim(),
      department: (data['department'] as String?)?.trim(),
      modules: (data['modules'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .map((module) => module.trim())
          .where((module) => module.isNotEmpty)
          .toList(growable: false),
      isActive: data['is_active'] as bool? ?? true,
      lastSyncedAt: DateTime.now(),
      source: source,
    );

    if (!profile.isActive) {
      debugPrint(
        'Kullanıcı ${profile.email ?? profile.uid} pasif durumda. Oturum kapatılıyor.',
      );
      await logout();
      return;
    }

    await _reconcileClaims(user, profile);
    _updateProfile(profile);
  }

  Future<void> _reconcileClaims(User user, UserProfileState profile) async {
    try {
      final tokenResult = await user.getIdTokenResult(true);
      final tokenRole = tokenResult.claims?['role'] as String?;
      if (tokenRole == null) {
        debugPrint(
          'Bilgi: ${profile.email ?? profile.uid} için token içinde role claim yok.',
        );
        return;
      }

      if (profile.role != null && profile.role != tokenRole) {
        debugPrint(
          'Rol uyumsuzluğu tespit edildi. Token: $tokenRole, Firestore: ${profile.role}. Firestore güncelleniyor.',
        );
        await _firestore.collection('users').doc(profile.uid).update({
          'role': tokenRole,
          'updated_at': FieldValue.serverTimestamp(),
        });
        _updateProfile(profile.copyWith(role: tokenRole), persist: false);
      }
    } catch (error, stackTrace) {
      debugPrint('Claims kontrolü sırasında hata: $error\n$stackTrace');
    }
  }

  Future<UserProfileState?> _loadCachedProfile(String uid) async {
    final key = _cacheKey(uid);
    final cachedJson = _prefs?.getString(key);
    if (cachedJson == null || cachedJson.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
      return UserProfileState.fromJson(decoded);
    } catch (error) {
      debugPrint('Önbellekten profil okunamadı: $error');
      return null;
    }
  }

  Future<void> _persistProfile(UserProfileState? profile) async {
    final uid = profile?.uid ?? _auth.currentUser?.uid;
    if (uid == null) return;

    if (profile == null) {
      await _prefs?.remove(_cacheKey(uid));
      return;
    }

    try {
      await _prefs?.setString(_cacheKey(uid), jsonEncode(profile.toJson()));
    } catch (error) {
      debugPrint('Profil önbelleğe alınamadı: $error');
    }
  }

  void _updateProfile(UserProfileState? profile, {bool persist = true}) {
    if (_currentProfile != null &&
        profile != null &&
        _currentProfile == profile) {
      _currentProfile = profile;
      if (persist) {
        unawaited(_persistProfile(profile));
      }
      return;
    }

    if (_currentProfile == null && profile == null) {
      if (persist) {
        unawaited(_persistProfile(null));
      }
      return;
    }

    _currentProfile = profile;
    _profileController.add(profile);
    if (persist) {
      unawaited(_persistProfile(profile));
    }
  }

  String _cacheKey(String uid) => 'user_profile_$uid';

  @visibleForTesting
  void debugSetProfile(UserProfileState? profile) {
    _currentProfile = profile;
    _profileController.add(profile);
  }

  @visibleForTesting
  Future<void> debugClearProfile() async {
    await _stopProfileSync();
    _currentProfile = null;
    _profileController.add(null);
  }

  @visibleForTesting
  static void setTestInstance(AuthService service) {
    _testInstance = service;
  }

  @visibleForTesting
  static void resetTestInstance() {
    _testInstance = null;
  }

  @visibleForTesting
  factory AuthService.test({FirebaseAuth? auth, FirebaseFirestore? firestore}) {
    return AuthService._(auth: auth, firestore: firestore);
  }
}
