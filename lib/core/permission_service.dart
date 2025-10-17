import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

import '../modules/tenant/services/tenant_service.dart';
import '../modules/licensing/services/license_service.dart';
import 'services/auth_service.dart';

class PermissionService {
  PermissionService._({FirebaseFirestore? firestore})
    : _firestoreProvider = firestore != null
          ? (() => firestore)
          : (() => TenantService.instance.firestore);

  static PermissionService? _instance;
  static PermissionService? _testInstance;

  static PermissionService get instance {
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return _instance ??= PermissionService._();
  }

  final FirebaseFirestore Function() _firestoreProvider;

  FirebaseFirestore get _firestore => _firestoreProvider();

  final Map<String, Map<String, bool>> _cache = {};
  bool? _licenseIsActiveCache;
  DateTime? _lastLicenseCheck;
  String? _licenseTenantId;

  Future<Map<String, bool>> getPermissions(String module) async {
    final normalizedModule = module.toLowerCase();
    final role = AuthService.instance.currentUserRole;
    if (role == null) {
      return {};
    }

    final cacheKey = '$role::$normalizedModule';

    if (!await _ensureLicenseIsActive(role)) {
      _cache[cacheKey] = {};
      return _cache[cacheKey]!;
    }
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final doc = await _firestore
        .collection('permissions')
        .doc(normalizedModule)
        .get();
    final data = doc.data();
    if (data == null) {
      _cache[cacheKey] = {};
      return _cache[cacheKey]!;
    }

    final roleData = data[role];
    if (roleData is Map) {
      _cache[cacheKey] = roleData.map(
        (key, value) => MapEntry(key.toString().toLowerCase(), value == true),
      );
    } else {
      _cache[cacheKey] = {};
    }

    return _cache[cacheKey]!;
  }

  bool can(String module, String action) {
    final normalizedModule = module.toLowerCase();
    final normalizedAction = action.toLowerCase();
    final role = AuthService.instance.currentUserRole;
    if (role == null) return false;
    final cacheKey = '$role::$normalizedModule';
    final permissions = _cache[cacheKey];
    if (permissions == null) {
      return false;
    }
    return permissions[normalizedAction] == true;
  }

  void clearCache() {
    _cache.clear();
    _clearLicenseCache();
  }

  void _clearLicenseCache() {
    _licenseIsActiveCache = null;
    _lastLicenseCheck = null;
    _licenseTenantId = null;
  }

  Future<bool> _ensureLicenseIsActive(String role) async {
    if (role == 'superadmin') {
      return true;
    }
    final tenantId = TenantService.instance.activeTenantId;
    if (tenantId == null || tenantId.isEmpty) {
      return true;
    }
    if (_licenseTenantId != tenantId) {
      _clearLicenseCache();
      _licenseTenantId = tenantId;
    }
    final now = DateTime.now();
    if (_licenseIsActiveCache != null &&
        _lastLicenseCheck != null &&
        now.difference(_lastLicenseCheck!) < const Duration(minutes: 5)) {
      return _licenseIsActiveCache!;
    }
    final isValid = await LicenseService.instance.checkLicenseValidity(
      tenantId,
    );
    _licenseIsActiveCache = isValid;
    _lastLicenseCheck = now;
    return isValid;
  }

  @visibleForTesting
  static void setTestInstance(PermissionService service) {
    _testInstance = service;
  }

  @visibleForTesting
  static void resetTestInstance() {
    _testInstance = null;
  }

  @visibleForTesting
  factory PermissionService.test({FirebaseFirestore? firestore}) {
    return PermissionService._(firestore: firestore);
  }
}
