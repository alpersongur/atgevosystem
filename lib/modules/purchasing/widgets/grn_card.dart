import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/grn_model.dart';

class GRNCard extends StatelessWidget {
  const GRNCard({super.key, required this.grn, this.supplierName, this.onTap});

  final GRNModel grn;
  final String? supplierName;
  final VoidCallback? onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'received':
        return Colors.green;
      case 'qc_hold':
        return Colors.orange;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    grn.receiptNo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(grn.status.toUpperCase()),
                  backgroundColor: _statusColor(
                    grn.status,
                  ).withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    color: _statusColor(grn.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              supplierName ?? grn.supplierId,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    grn.receivedDate != null
                        ? dateFormat.format(grn.receivedDate!)
                        : 'Tarih belirtilmemiş',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  grn.warehouse,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Satırlar: ${grn.lines.length}',
              style: Theme.of(context).textTheme.bodySmall,
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
