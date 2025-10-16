import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  final List<String> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentUserRole;

    if (!allowedRoles.contains(role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacementNamed('/main');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yetkiniz yok.')),
        );
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return child;
  }
}
