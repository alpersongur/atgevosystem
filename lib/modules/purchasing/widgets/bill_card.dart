import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bill_model.dart';

class BillCard extends StatelessWidget {
  const BillCard({
    super.key,
    required this.bill,
    this.supplierName,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final BillModel bill;
  final String? supplierName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _statusColor(String status) {
    switch (status) {
      case 'unpaid':
        return Colors.orange;
      case 'partial':
        return Colors.deepPurple;
      case 'paid':
        return Colors.green;
      case 'canceled':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: bill.currency,
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
                    bill.billNo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(bill.status.toUpperCase()),
                  backgroundColor: _statusColor(
                    bill.status,
                  ).withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    color: _statusColor(bill.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              supplierName ?? bill.supplierId,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    bill.issueDate != null
                        ? dateFormat.format(bill.issueDate!)
                        : 'Fatura Tarihi belirtilmemiş',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  currencyFormat.format(bill.grandTotal),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
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
