import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:atgevosystem/core/models/quote.dart';
import 'quote_status_chip.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    this.customerName,
    this.onTap,
    this.onEdit,
  });

  final QuoteModel quote;
  final String? customerName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: quote.currency,
      decimalDigits: 2,
    );
    final validUntil = quote.validUntil != null
        ? DateFormat('dd.MM.yyyy').format(quote.validUntil!)
        : '—';

    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                      quote.quoteNumber.isEmpty ? 'Teklif' : quote.quoteNumber,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (quote.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        quote.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      customerName ?? 'Müşteri: ${quote.customerId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          currencyFormat.format(quote.amount),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        QuoteStatusChip(status: quote.status),
                        Text(
                          'Geçerlilik: $validUntil',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Teklifi düzenle',
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
