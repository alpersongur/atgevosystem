import 'package:flutter/material.dart';

import '../models/supplier_model.dart';

class SupplierCard extends StatelessWidget {
  const SupplierCard({
    super.key,
    required this.supplier,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final SupplierModel supplier;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'inactive':
        return Colors.redAccent;
      case 'active':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    supplier.supplierName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(supplier.status.toUpperCase()),
                  backgroundColor: _statusColor(
                    supplier.status,
                  ).withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    color: _statusColor(supplier.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              supplier.contactPerson.isNotEmpty
                  ? supplier.contactPerson
                  : 'Yetkili belirtilmemiş',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              supplier.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${supplier.city}, ${supplier.country}',
              style: theme.textTheme.bodySmall,
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
