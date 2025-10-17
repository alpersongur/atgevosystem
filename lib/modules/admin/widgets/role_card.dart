import 'package:flutter/material.dart';

import '../models/role_model.dart';

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.role,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final RoleModel role;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final permissions = role.permissions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.toUpperCase())
        .toList(growable: false);

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
                    role.roleName.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.security_outlined, color: Colors.indigo[400]),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              role.description.isEmpty
                  ? 'Açıklama girilmemiş.'
                  : role.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: permissions.isEmpty
                  ? [
                      Chip(
                        label: const Text('MODULE YOK'),
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      ),
                    ]
                  : permissions
                        .map(
                          (module) => Chip(
                            label: Text(module),
                            backgroundColor: Colors.indigo.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        )
                        .toList(growable: false),
            ),
            if (onEdit != null || onDelete != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Düzenle'),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Sil'),
                      ),
                  ],
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
}
