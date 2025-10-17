import 'package:flutter/material.dart';

import '../models/user_model.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user, this.onTap, this.onEdit});

  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final roleChipColor = _roleColor(user.role);
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.displayName.isEmpty ? user.email : user.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(user.role.toUpperCase()),
                  backgroundColor: roleChipColor.withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    color: roleChipColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: user.modules
                  .map(
                    (module) => Chip(
                      label: Text(module.toUpperCase()),
                      backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Text(
              user.isActive ? 'Aktif' : 'Pasif',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: user.isActive ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onEdit != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Düzenle'),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return Colors.redAccent;
      case 'admin':
        return Colors.indigo;
      case 'sales':
        return Colors.blue;
      case 'production':
        return Colors.deepPurple;
      case 'accounting':
        return Colors.green;
      case 'purchasing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
