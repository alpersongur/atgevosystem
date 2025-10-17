import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shipment_model.dart';
import 'shipment_status_chip.dart';

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({
    super.key,
    required this.shipment,
    this.customerName,
    this.onTap,
    this.onEdit,
  });

  final ShipmentModel shipment;
  final String? customerName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final departureText = shipment.departureDate != null
        ? dateFormat.format(shipment.departureDate!)
        : '—';

    return Card(
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
                      shipment.shipmentNo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customerName ?? 'Müşteri: ${shipment.customerId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ShipmentStatusChip(status: shipment.status),
                        Text(
                          'Taşıyıcı: ${shipment.carrier.isEmpty ? '-' : shipment.carrier}',
                        ),
                        Text('Çıkış: $departureText'),
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
