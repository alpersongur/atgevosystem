import 'package:flutter/material.dart';

import '../models/license_model.dart';

class LicenseCard extends StatelessWidget {
  const LicenseCard({
    super.key,
    required this.license,
    required this.onTap,
    required this.onEdit,
  });

  final LicenseModel license;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme, license.status);
    final modulesText = license.modules.isEmpty
        ? '-'
        : license.modules.join(', ').toUpperCase();
    final dateRange = _formatDateRange(license.startDate, license.endDate);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      modulesText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Chip(
                    backgroundColor: statusColor.background,
                    label: Text(
                      license.status.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: statusColor.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Dönem: $dateRange', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(
                'Fiyat: ${license.price.toStringAsFixed(2)} ${license.currency}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Kalan Gün: ${license.remainingDays ?? '-'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Düzenle'),
                  ),
                  const Spacer(),
                  OutlinedButton(onPressed: onTap, child: const Text('Detay')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusColors _statusColor(ThemeData theme, String status) {
    switch (status) {
      case 'active':
        return _StatusColors(
          background: theme.colorScheme.primaryContainer,
          foreground: theme.colorScheme.onPrimaryContainer,
        );
      case 'expired':
        return _StatusColors(
          background: Colors.red.shade100,
          foreground: Colors.red.shade700,
        );
      case 'suspended':
        return _StatusColors(
          background: Colors.orange.shade100,
          foreground: Colors.orange.shade700,
        );
      default:
        return _StatusColors(
          background: theme.colorScheme.surfaceContainerHighest,
          foreground: theme.colorScheme.onSurfaceVariant,
        );
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    final startText = start != null
        ? '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}'
        : '-';
    final endText = end != null
        ? '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year}'
        : '-';
    return '$startText - $endText';
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
