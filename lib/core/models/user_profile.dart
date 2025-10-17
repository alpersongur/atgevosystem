enum ProfileDataSource { cache, snapshot, api, initial }

class UserProfileState {
  const UserProfileState({
    required this.uid,
    required this.modules,
    required this.isActive,
    required this.lastSyncedAt,
    required this.source,
    this.email,
    this.displayName,
    this.role,
    this.department,
  });

  factory UserProfileState.fromJson(Map<String, dynamic> json) {
    return UserProfileState(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      role: json['role'] as String?,
      department: json['department'] as String?,
      modules: (json['modules'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .map((module) => module.trim())
          .where((module) => module.isNotEmpty)
          .toList(growable: false),
      isActive: json['is_active'] as bool? ?? true,
      lastSyncedAt:
          DateTime.tryParse(json['last_synced_at'] as String? ?? '') ??
          DateTime.now(),
      source: ProfileDataSource.values.firstWhere(
        (value) => value.name == (json['source'] as String? ?? ''),
        orElse: () => ProfileDataSource.cache,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'role': role,
      'department': department,
      'modules': modules,
      'is_active': isActive,
      'last_synced_at': lastSyncedAt.toIso8601String(),
      'source': source.name,
    };
  }

  UserProfileState copyWith({
    String? role,
    List<String>? modules,
    bool? isActive,
    DateTime? lastSyncedAt,
    ProfileDataSource? source,
  }) {
    return UserProfileState(
      uid: uid,
      email: email,
      displayName: displayName,
      department: department,
      role: role ?? this.role,
      modules: modules ?? this.modules,
      isActive: isActive ?? this.isActive,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserProfileState) return false;
    return uid == other.uid &&
        role == other.role &&
        department == other.department &&
        isActive == other.isActive &&
        _listEquals(modules, other.modules);
  }

  @override
  int get hashCode =>
      Object.hash(uid, role, department, isActive, Object.hashAll(modules));

  final String uid;
  final String? email;
  final String? displayName;
  final String? role;
  final String? department;
  final List<String> modules;
  final bool isActive;
  final DateTime lastSyncedAt;
  final ProfileDataSource source;

  bool hasModule(String module) =>
      modules.map((m) => m.toLowerCase()).contains(module.toLowerCase());
  bool hasAllModules(Iterable<String> requiredModules) {
    final normalized = modules.map((m) => m.toLowerCase()).toSet();
    return requiredModules
        .map((module) => module.toLowerCase())
        .every(normalized.contains);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
