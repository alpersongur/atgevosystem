import 'package:flutter/material.dart';

import 'package:atgevosystem/core/models/inventory_item.dart';

class InventoryCard extends StatelessWidget {
  const InventoryCard({super.key, required this.item, this.onTap, this.onEdit});

  final InventoryItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusStyles[item.status] ?? _StatusStyle.fallback;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: item.isBelowMin ? Colors.red.shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kategori: ${item.category}',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          label: Text('${item.quantity} ${item.unit}'),
                          backgroundColor: item.isBelowMin
                              ? Colors.red.shade100
                              : Colors.blue.shade50,
                        ),
                        _StatusChip(info: statusInfo),
                        Text('Konum: ${item.location}'),
                      ],
                    ),
                    if (item.isBelowMin)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Minimum stok: ${item.minStock}',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Düzenle',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.info});

  final _StatusStyle info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        info.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: info.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  static final _StatusStyle fallback = _StatusStyle(
    label: 'Bilinmiyor',
    background: Colors.grey.shade200,
    foreground: Colors.grey.shade700,
  );
}

final Map<String, _StatusStyle> _statusStyles = {
  'active': _StatusStyle(
    label: 'Aktif',
    background: Colors.green.shade50,
    foreground: Colors.green.shade700,
  ),
  'inactive': _StatusStyle(
    label: 'Pasif',
    background: Colors.grey.shade300,
    foreground: Colors.grey.shade700,
  ),
};
