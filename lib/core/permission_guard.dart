import 'package:flutter/material.dart';

import 'permission_service.dart';
import 'services/auth_service.dart';

class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.module,
    required this.action,
    required this.child,
    this.loading = const Center(child: CircularProgressIndicator()),
    this.denied,
  });

  final String module;
  final String action;
  final Widget child;
  final Widget loading;
  final Widget? denied;

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentUserRole;
    if (role == null) {
      return denied ?? const SizedBox.shrink();
    }
    final normalizedModule = module.toLowerCase();
    final normalizedAction = action.toLowerCase();
    return FutureBuilder<Map<String, bool>>(
      future: PermissionService.instance.getPermissions(normalizedModule),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading;
        }
        if (snapshot.hasError) {
          return denied ?? const SizedBox.shrink();
        }
        final permissions = snapshot.data ?? const {};
        final allowed = permissions[normalizedAction] == true;
        return allowed ? child : (denied ?? const SizedBox.shrink());
      },
    );
  }
}
