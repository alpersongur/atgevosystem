import 'package:flutter/material.dart';
import 'package:atgevosystem/core/models/customer.dart';
import 'package:atgevosystem/core/services/customer_service.dart';
import '../models/shipment_model.dart';
import '../services/shipment_service.dart';
import '../widgets/shipment_card.dart';
import 'shipment_detail_page.dart';
import 'shipment_edit_page.dart';

class ShipmentListPage extends StatelessWidget {
  const ShipmentListPage({super.key});

  static const routeName = '/shipment';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sevkiyatlar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ShipmentEditPage()));
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ShipmentModel>>(
        stream: ShipmentService.instance.getShipmentsStream(),
        builder: (context, shipmentSnapshot) {
          if (shipmentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shipmentSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Sevkiyatlar yüklenirken hata oluştu.\n${shipmentSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final shipments = shipmentSnapshot.data ?? <ShipmentModel>[];
          if (shipments.isEmpty) {
            return const Center(
              child: Text('Henüz sevkiyat kaydı bulunmuyor.'),
            );
          }

          return StreamBuilder<List<CustomerModel>>(
            stream: CustomerService.instance.getCustomers(),
            builder: (context, customerSnapshot) {
              final customerMap = {
                for (final customer in customerSnapshot.data ?? [])
                  customer.id: customer.companyName,
              };
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: shipments.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final shipment = shipments[index];
                  return ShipmentCard(
                    shipment: shipment,
                    customerName: customerMap[shipment.customerId],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ShipmentDetailPage(shipmentId: shipment.id),
                        ),
                      );
                    },
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ShipmentEditPage(shipmentId: shipment.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
