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
    final hasPermission = PermissionService.instance.can(module, action);

    if (!hasPermission) {
      return const SizedBox.shrink();
    }

    return child;
  }
}
