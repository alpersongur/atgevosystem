import 'package:flutter/material.dart';

import '../models/tenant_model.dart';

class TenantCard extends StatelessWidget {
  const TenantCard({
    super.key,
    required this.tenant,
    required this.onTap,
    required this.onEdit,
    required this.onSelect,
    this.isSelected = false,
  });

  final TenantModel tenant;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modules = tenant.modules;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: isSelected ? 1.5 : 0.2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tenant.companyName.isEmpty
                          ? 'Adsız Firma'
                          : tenant.companyName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      tenant.isActive ? 'Aktif' : 'Pasif',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: tenant.isActive ? Colors.white : null,
                      ),
                    ),
                    backgroundColor: tenant.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tenant.ownerEmail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: modules.isEmpty
                    ? [
                        Chip(
                          label: const Text('Modül tanımlı değil'),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ]
                    : modules
                          .map(
                            (module) => Chip(label: Text(module.toUpperCase())),
                          )
                          .toList(growable: false),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Detay'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Düzenle'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: tenant.isActive ? onSelect : null,
                    icon: Icon(
                      isSelected
                          ? Icons.check_circle_outline
                          : Icons.play_arrow_outlined,
                    ),
                    label: Text(isSelected ? 'Aktif Firma' : 'Aktifleştir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
