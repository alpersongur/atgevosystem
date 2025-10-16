import 'package:flutter/material.dart';

import '../models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final CustomerModel customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
        title: Text(
          customer.companyName.isEmpty
              ? 'İsimsiz Müşteri'
              : customer.companyName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((customer.contactPerson ?? '').isNotEmpty)
                Text(
                  customer.contactPerson!,
                  style: const TextStyle(fontSize: 13),
                ),
              if ((customer.email ?? '').isNotEmpty)
                Text(
                  customer.email!,
                  style: const TextStyle(fontSize: 13),
                ),
              if ((customer.phone ?? '').isNotEmpty)
                Text(
                  customer.phone!,
                  style: const TextStyle(fontSize: 13),
                ),
              if ((customer.address ?? '').isNotEmpty)
                Text(
                  customer.address!,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Müşteriyi düzenle',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.redAccent,
              tooltip: 'Müşteriyi sil',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
