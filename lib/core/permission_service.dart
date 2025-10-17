import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';

class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, bool>> _cache = {};

  Future<Map<String, bool>> getPermissions(String module) async {
    final role = AuthService.instance.currentUserRole;
    if (role == null) {
      _cache[module] = {};
      return _cache[module]!;
    }

    if (_cache.containsKey(module)) {
      return _cache[module]!;
    }

    final doc = await _firestore.collection('permissions').doc(module).get();
    final data = doc.data();
    if (data == null) {
      _cache[module] = {};
      return _cache[module]!;
    }

    final roleData = data[role];
    if (roleData is Map) {
      _cache[module] = roleData.map(
        (key, value) => MapEntry(key.toString(), value == true),
      );
    } else {
      _cache[module] = {};
    }

    return _cache[module]!;
  }

  bool can(String module, String action) {
    final permissions = _cache[module];
    if (permissions == null) {
      return false;
    }
    return permissions[action] == true;
  }

  void clearCache() => _cache.clear();
}
