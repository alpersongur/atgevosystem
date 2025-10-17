import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/timestamp_helper.dart';
import '../models/tenant_model.dart';
import 'tenant_firebase_options_registry.dart';

class TenantService with FirestoreTimestamps {
  TenantService._();

  static final TenantService instance = TenantService._();

  static const _prefsActiveTenantKey = 'tenant.active_company';

  final StreamController<TenantModel?> _activeTenantController =
      StreamController<TenantModel?>.broadcast();

  SharedPreferences? _prefs;
  TenantModel? _activeTenant;
  bool _initialized = false;
  String? _currentFirebaseProjectId;
  FirebaseApp? _activeTenantApp;
  FirebaseFirestore? _tenantFirestore;
  FirebaseAuth? _tenantAuth;

  TenantModel? get activeTenant => _activeTenant;
  Stream<TenantModel?> get activeTenantStream => _activeTenantController.stream;

  FirebaseFirestore get firestore =>
      _tenantFirestore ?? FirebaseFirestore.instance;

  FirebaseAuth get auth => _tenantAuth ?? FirebaseAuth.instance;

  FirebaseApp? get activeFirebaseApp => _activeTenantApp;

  String? get activeTenantId => _activeTenant?.id;

  String requireActiveTenantId() {
    final tenantId = _activeTenant?.id;
    if (tenantId == null || tenantId.isEmpty) {
      throw StateError('Aktif firma seçilmeden bu işlem yapılamaz.');
    }
    return tenantId;
  }

  CollectionReference<Map<String, dynamic>> tenantCollection(String path) {
    if (_tenantFirestore != null) {
      return _tenantFirestore!.collection(path);
    }
    final tenantId = requireActiveTenantId();
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(tenantId)
        .collection(path);
  }

  CollectionReference<Map<String, dynamic>> get _companiesCollection =>
      FirebaseFirestore.instance.collection('companies');

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    final cachedTenantJson = _prefs?.getString(_prefsActiveTenantKey);
    if (cachedTenantJson != null && cachedTenantJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedTenantJson) as Map<String, dynamic>;
        final cachedTenant = TenantModel.fromCache(decoded);
        _applyActiveTenant(cachedTenant, persist: false);
        _currentFirebaseProjectId = cachedTenant.firebaseProjectId;
      } catch (error) {
        // Geçersiz cache'i temizle.
        await _prefs?.remove(_prefsActiveTenantKey);
      }
    }
  }

  Stream<List<TenantModel>> getCompaniesStream() {
    return _companiesCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TenantModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  Future<TenantModel?> fetchCompanyById(String id) async {
    final doc = await _companiesCollection.doc(id).get();
    if (!doc.exists) return null;
    return TenantModel.fromSnapshot(doc);
  }

  Stream<TenantModel?> watchCompany(String id) {
    return _companiesCollection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return TenantModel.fromSnapshot(snapshot);
    });
  }

  Future<String> addCompany(Map<String, dynamic> data) async {
    final payload = withCreateTimestamps(<String, dynamic>{
      ...data,
      'status': data['status'] ?? 'active',
    });
    final docRef = await _companiesCollection.add(payload);
    return docRef.id;
  }

  Future<void> updateCompany(String id, Map<String, dynamic> data) {
    return _companiesCollection.doc(id).update(withUpdateTimestamp(data));
  }

  Future<void> deactivateCompany(String id) {
    return _companiesCollection
        .doc(id)
        .update(withUpdateTimestamp(<String, dynamic>{'status': 'inactive'}));
  }

  Future<void> activateCompany(String id) {
    return _companiesCollection
        .doc(id)
        .update(withUpdateTimestamp(<String, dynamic>{'status': 'active'}));
  }

  Future<void> setActiveCompany(String id) async {
    final tenant = await fetchCompanyById(id);
    if (tenant == null) {
      throw StateError('Belirtilen firma bulunamadı.');
    }
    await _persistActiveTenant(tenant);
    await _reloadFirebaseAppFor(tenant);
    _applyActiveTenant(tenant, persist: false);
  }

  Future<void> setActiveCompanyFromModel(TenantModel tenant) async {
    await _persistActiveTenant(tenant);
    await _reloadFirebaseAppFor(tenant);
    _applyActiveTenant(tenant, persist: false);
  }

  Future<void> clearActiveCompany() async {
    _activeTenant = null;
    _currentFirebaseProjectId = null;
    _activeTenantApp = null;
    _tenantFirestore = null;
    _tenantAuth = null;
    await _prefs?.remove(_prefsActiveTenantKey);
    _activeTenantController.add(null);
  }

  Future<void> refreshActiveTenantFromRemote() async {
    final cached = _activeTenant;
    if (cached == null) return;
    final latest = await fetchCompanyById(cached.id);
    if (latest == null) {
      await clearActiveCompany();
      return;
    }
    await _persistActiveTenant(latest);
    _applyActiveTenant(latest, persist: false);
  }

  /// Uygulama açılışında Firebase başlatılmadan önce çağrılmalı.
  Future<FirebaseOptions?> resolveStartupFirebaseOptions() async {
    await initialize();
    final cachedTenant = _activeTenant;
    if (cachedTenant == null) return null;
    return TenantFirebaseOptionsRegistry.instance.resolveByProjectId(
      cachedTenant.firebaseProjectId,
    );
  }

  Future<void> ensureTenantAppInitialized() async {
    await initialize();
    final tenant = _activeTenant;
    if (tenant == null) return;
    await _reloadFirebaseAppFor(tenant);
  }

  Future<void> _persistActiveTenant(TenantModel tenant) async {
    await initialize();
    final encoded = jsonEncode(tenant.toCacheJson());
    await _prefs?.setString(_prefsActiveTenantKey, encoded);
  }

  void _applyActiveTenant(TenantModel tenant, {required bool persist}) {
    _activeTenant = tenant;
    _currentFirebaseProjectId = tenant.firebaseProjectId;
    _activeTenantController.add(tenant);
    if (persist) {
      unawaited(_persistActiveTenant(tenant));
    }
  }

  Future<void> _reloadFirebaseAppFor(TenantModel tenant) async {
    final options = TenantFirebaseOptionsRegistry.instance.resolveByProjectId(
      tenant.firebaseProjectId,
    );
    if (options == null) {
      throw StateError(
        'Firebase yapılandırması bulunamadı: ${tenant.firebaseProjectId}',
      );
    }

    if (_currentFirebaseProjectId == tenant.firebaseProjectId &&
        _activeTenantApp != null) {
      return;
    }

    FirebaseApp tenantApp;
    try {
      tenantApp = Firebase.app(tenant.id);
    } catch (_) {
      tenantApp = await Firebase.initializeApp(
        name: tenant.id,
        options: options,
      );
    }

    _activeTenantApp = tenantApp;
    _tenantFirestore = FirebaseFirestore.instanceFor(app: tenantApp);
    _tenantAuth = FirebaseAuth.instanceFor(app: tenantApp);
    _currentFirebaseProjectId = tenant.firebaseProjectId;
  }
}
