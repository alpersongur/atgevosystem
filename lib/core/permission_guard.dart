import 'package:flutter/material.dart';

import 'permission_service.dart';

class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.module,
    required this.action,
    required this.child,
  });

  final String module;
  final String action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final normalizedModule = module.toLowerCase();
    final normalizedAction = action.toLowerCase();
    return FutureBuilder<Map<String, bool>>(
      future: PermissionService.instance.getPermissions(normalizedModule),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final permissions = snapshot.data ?? const {};
        final allowed = permissions[normalizedAction] == true;
        return allowed ? child : const SizedBox.shrink();
      },
    );
  }
}
