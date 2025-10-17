import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/purchase_order_model.dart';

class PurchaseOrderCard extends StatelessWidget {
  const PurchaseOrderCard({
    super.key,
    required this.order,
    this.supplierName,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final PurchaseOrderModel order;
  final String? supplierName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'partially_received':
        return Colors.deepOrange;
      case 'received':
        return Colors.green;
      case 'billed':
        return Colors.indigo;
      case 'closed':
        return Colors.grey;
      case 'canceled':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: order.currency,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd.MM.yyyy');

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
                    order.poNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(order.status.toUpperCase()),
                  backgroundColor: _statusColor(
                    order.status,
                  ).withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              supplierName ?? order.supplierId,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Satırlar: ${order.lines.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  currencyFormat.format(order.grandTotal),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (order.expectedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Beklenen: ${dateFormat.format(order.expectedDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
