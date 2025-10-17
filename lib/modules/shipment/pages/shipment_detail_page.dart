import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:atgevosystem/core/services/auth_service.dart';
import 'package:atgevosystem/core/models/customer.dart';
import '../../crm/pages/customer_detail_page.dart';
import 'package:atgevosystem/core/services/customer_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../models/shipment_model.dart';
import '../services/shipment_service.dart';
import '../widgets/shipment_status_chip.dart';
import 'shipment_edit_page.dart';
import '../../finance/pages/invoice_edit_page.dart';

class ShipmentDetailPage extends StatelessWidget {
  const ShipmentDetailPage({super.key, required this.shipmentId});

  static const routeName = '/shipment/detail';

  final String shipmentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sevkiyat Detayı')),
      body: StreamBuilder<ShipmentModel?>(
        stream: ShipmentService.instance.watchShipment(shipmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Sevkiyat verileri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final shipment = snapshot.data;
          if (shipment == null) {
            return const Center(
              child: Text('Sevkiyat kaydı bulunamadı veya silinmiş olabilir.'),
            );
          }

          return _ShipmentDetailContent(shipment: shipment);
        },
      ),
    );
  }
}

class _ShipmentDetailContent extends StatefulWidget {
  const _ShipmentDetailContent({required this.shipment});

  final ShipmentModel shipment;

  @override
  State<_ShipmentDetailContent> createState() => _ShipmentDetailContentState();
}

class _ShipmentDetailContentState extends State<_ShipmentDetailContent> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final shipment = widget.shipment;
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final isSuperAdmin = role == 'superadmin';
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shipment.shipmentNo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ShipmentStatusChip(status: shipment.status),
                      const SizedBox(width: 12),
                      Text(
                        'Taşıyıcı: ${shipment.carrier.isEmpty ? '-' : shipment.carrier}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Araç Plakası',
                    value: shipment.vehiclePlate,
                  ),
                  _DetailRow(label: 'Sürücü', value: shipment.driverName),
                  _DetailRow(
                    label: 'Çıkış Tarihi',
                    value: shipment.departureDate != null
                        ? dateFormat.format(shipment.departureDate!)
                        : '—',
                  ),
                  _DetailRow(
                    label: 'Teslim Tarihi',
                    value: shipment.deliveryDate != null
                        ? dateFormat.format(shipment.deliveryDate!)
                        : (shipment.status == 'delivered'
                              ? 'Teslim edildi'
                              : '—'),
                  ),
                  if ((shipment.notes ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Notlar: ${shipment.notes}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _CustomerSection(customerId: shipment.customerId),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _isUpdating ? null : () => _changeStatus(context),
                icon: const Icon(Icons.update),
                label: const Text('Durumu Güncelle'),
              ),
              ElevatedButton.icon(
                onPressed: _isUpdating || shipment.status == 'delivered'
                    ? null
                    : () => _markDelivered(),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Teslim Edildi'),
              ),
              if (shipment.status == 'delivered')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      InvoiceEditPage.createRoute,
                      arguments: InvoiceEditPageArgs(
                        shipmentId: shipment.id,
                        customerId: shipment.customerId,
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Fatura Oluştur'),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ShipmentEditPage(shipmentId: shipment.id),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Düzenle'),
              ),
              if (isSuperAdmin)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: _isUpdating
                      ? null
                      : () => _deleteShipment(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Sil'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context) async {
    final shipment = widget.shipment;
    final newStatus = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Durum Seç'),
        children: [
          _statusDialogOption(ctx, 'preparing', 'Hazırlanıyor'),
          _statusDialogOption(ctx, 'on_the_way', 'Yolda'),
          _statusDialogOption(ctx, 'delivered', 'Teslim Edildi'),
        ],
      ),
    );

    if (newStatus == null || newStatus == shipment.status) return;

    await _updateStatus(newStatus, setDelivered: newStatus == 'delivered');
  }

  Future<void> _markDelivered() async {
    await _updateStatus('delivered', setDelivered: true);
  }

  Future<void> _updateStatus(String status, {bool setDelivered = false}) async {
    final previousStatus = widget.shipment.status;
    setState(() => _isUpdating = true);
    try {
      await ShipmentService.instance.updateStatus(widget.shipment.id, status);

      if (setDelivered &&
          previousStatus != 'delivered' &&
          widget.shipment.inventoryItemId != null) {
        await InventoryService.instance.adjustStock(
          widget.shipment.inventoryItemId!,
          1,
          'decrease',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Durum güncellendi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Durum güncellenemedi: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _deleteShipment(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sevkiyatı Sil'),
            content: const Text(
              'Bu sevkiyatı silmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ShipmentService.instance.deleteShipment(widget.shipment.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sevkiyat silindi.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme başarısız: $error')));
    }
  }

  Widget _statusDialogOption(BuildContext context, String value, String label) {
    return SimpleDialogOption(
      onPressed: () => Navigator.of(context).pop(value),
      child: Text(label),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CustomerModel?>(
      stream: CustomerService.instance.watchCustomer(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final customer = snapshot.data;
        if (customer == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Müşteri bilgisi bulunamadı.'),
            ),
          );
        }

        return Card(
          child: ListTile(
            title: Text(customer.companyName),
            subtitle: Text(customer.contactPerson ?? 'Yetkili bilgisi yok'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              Navigator.of(context).pushNamed(
                CustomerDetailPage.routeName,
                arguments: CustomerDetailPageArgs(customer.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class ShipmentDetailPageArgs {
  const ShipmentDetailPageArgs(this.shipmentId);

  final String shipmentId;
}
