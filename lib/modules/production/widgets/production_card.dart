import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/production_order_model.dart';

class ProductionCard extends StatelessWidget {
  const ProductionCard({
    super.key,
    required this.order,
    this.onTap,
    this.onEdit,
  });

  final ProductionOrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final startText =
        order.startDate != null ? dateFormat.format(order.startDate!) : '—';
    final etaText = order.estimatedCompletion != null
        ? dateFormat.format(order.estimatedCompletion!)
        : '—';

    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.quoteId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Durum: ${_statusLabel(order.status)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ProductionStatusChip(status: order.status),
                        Text('Başlangıç: $startText'),
                        Text('Tahmini Bitiş: $etaText'),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductionStatusChip extends StatelessWidget {
  const ProductionStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final info = _statusStyles[status] ?? _StatusStyle.fallback;
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
  'waiting': _StatusStyle(
    label: 'Beklemede',
    background: Colors.orange.shade50,
    foreground: Colors.orange.shade800,
  ),
  'in_progress': _StatusStyle(
    label: 'Üretimde',
    background: Colors.indigo.shade50,
    foreground: Colors.indigo.shade700,
  ),
  'quality_check': _StatusStyle(
    label: 'Kalite Kontrol',
    background: Colors.purple.shade50,
    foreground: Colors.purple.shade700,
  ),
  'completed': _StatusStyle(
    label: 'Tamamlandı',
    background: Colors.green.shade50,
    foreground: Colors.green.shade800,
  ),
  'shipped': _StatusStyle(
    label: 'Sevk Edildi',
    background: Colors.teal.shade50,
    foreground: Colors.teal.shade800,
  ),
};

String _statusLabel(String status) {
  return _statusStyles[status]?.label ?? status;
}
