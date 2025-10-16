import 'package:flutter/material.dart';

class SystemActionButtons extends StatelessWidget {
  const SystemActionButtons({
    super.key,
    required this.onUsers,
    required this.onPermissions,
    required this.onModules,
  });

  final VoidCallback onUsers;
  final VoidCallback onPermissions;
  final VoidCallback onModules;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: onUsers,
          icon: const Icon(Icons.manage_accounts),
          label: const Text('Kullanıcı Yönetimi'),
        ),
        FilledButton.icon(
          onPressed: onPermissions,
          icon: const Icon(Icons.security),
          label: const Text('İzinler'),
        ),
        FilledButton.icon(
          onPressed: onModules,
          icon: const Icon(Icons.apps),
          label: const Text('Modüller'),
        ),
      ],
    );
  }
}
