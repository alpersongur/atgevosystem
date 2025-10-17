import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../../crm/models/customer_model.dart';
import '../../crm/pages/customer_detail_page.dart';
import '../../crm/quotes/models/quote_model.dart';
import '../../crm/quotes/pages/quote_detail_page.dart';
import '../../crm/quotes/services/quote_service.dart';
import '../../crm/services/customer_service.dart';
import '../../inventory/models/inventory_item_model.dart';
import '../../inventory/pages/inventory_detail_page.dart';
import '../../inventory/services/inventory_service.dart';
import '../../shipment/pages/shipment_edit_page.dart';
import '../models/production_order_model.dart';
import '../services/production_service.dart';
import '../widgets/production_card.dart';

class ProductionDetailPage extends StatefulWidget {
  const ProductionDetailPage({super.key, required this.orderId});

  static const routeName = '/production/orders/detail';

  final String orderId;

  @override
  State<ProductionDetailPage> createState() => _ProductionDetailPageState();
}

class _ProductionDetailPageState extends State<ProductionDetailPage> {
  String? _selectedStatus;
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Üretim Talimatı Detayı')),
      body: StreamBuilder<ProductionOrderModel?>(
        stream: ProductionService.instance.watchOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Üretim talimatı yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(
              child: Text('Üretim talimatı bulunamadı veya silinmiş olabilir.'),
            );
          }

          _selectedStatus ??= order.status;
          final dateFormat = DateFormat('dd.MM.yyyy');

          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(order, dateFormat),
                const SizedBox(height: 16),
                _buildStatusCard(order),
                if (order.status == 'completed') ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ShipmentEditPage(initialOrderId: order.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Sevkiyat Oluştur'),
                  ),
                ],
                const SizedBox(height: 16),
                _buildQuoteAndCustomer(order),
              ],
            ),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final device = ResponsiveBreakpoints.sizeForWidth(
                constraints.maxWidth,
              );
              if (device == DeviceSize.phone) {
                return Column(
                  children: [
                    Expanded(child: content),
                    const SizedBox(height: 8),
                    _buildMobileQuickActions(order),
                  ],
                );
              }
              return content;
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(ProductionOrderModel order, DateFormat dateFormat) {
    final startText = order.startDate != null
        ? dateFormat.format(order.startDate!)
        : '—';
    final etaText = order.estimatedCompletion != null
        ? dateFormat.format(order.estimatedCompletion!)
        : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Talimat Bilgileri',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Teklif No', value: order.quoteId),
            _DetailRow(
              label: 'Durum',
              valueWidget: ProductionStatusChip(status: order.status),
            ),
            _DetailRow(label: 'Başlangıç Tarihi', value: startText),
            _DetailRow(label: 'Tahmini Bitiş', value: etaText),
            if ((order.notes ?? '').isNotEmpty)
              _DetailRow(label: 'Notlar', value: order.notes!, multiline: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileQuickActions(ProductionOrderModel order) {
    final canStart = order.status == 'waiting';
    final canComplete =
        order.status == 'in_progress' || order.status == 'quality_check';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isUpdating || !canStart
                  ? null
                  : () => _updateStatus(order.id, order.status, 'in_progress'),
              icon: const Icon(Icons.play_arrow_rounded, size: 32),
              label: const Text(
                'Üretimi Başlat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isUpdating || !canComplete
                  ? null
                  : () => _updateStatus(order.id, order.status, 'completed'),
              icon: const Icon(Icons.check_circle_outline, size: 32),
              label: const Text(
                'Üretimi Bitir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ProductionOrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durum Güncelle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('status-${order.id}-${_selectedStatus ?? ''}'),
              initialValue: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: const [
                DropdownMenuItem(value: 'waiting', child: Text('Beklemede')),
                DropdownMenuItem(value: 'in_progress', child: Text('Üretimde')),
                DropdownMenuItem(
                  value: 'quality_check',
                  child: Text('Kalite Kontrol'),
                ),
                DropdownMenuItem(value: 'completed', child: Text('Tamamlandı')),
                DropdownMenuItem(value: 'shipped', child: Text('Sevk Edildi')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isUpdating || _selectedStatus == null
                  ? null
                  : () =>
                        _updateStatus(order.id, order.status, _selectedStatus!),
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Durumu Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteAndCustomer(ProductionOrderModel order) {
    final inventoryWidget = order.inventoryItemId == null
        ? const SizedBox.shrink()
        : StreamBuilder<InventoryItemModel?>(
            stream: InventoryService.instance.watchItem(order.inventoryItemId!),
            builder: (context, inventorySnapshot) {
              if (inventorySnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final inventoryItem = inventorySnapshot.data;
              if (inventoryItem == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Envanter kaydı bulunamadı.'),
                  ),
                );
              }

              return Card(
                child: ListTile(
                  title: Text(inventoryItem.productName),
                  subtitle: Text('SKU: ${inventoryItem.sku}'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      InventoryDetailPage.routeName,
                      arguments: InventoryDetailPageArgs(inventoryItem.id),
                    );
                  },
                ),
              );
            },
          );

    return Column(
      children: [
        StreamBuilder<QuoteModel?>(
          stream: QuoteService().watchQuote(order.quoteId),
          builder: (context, quoteSnapshot) {
            if (quoteSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final quote = quoteSnapshot.data;
            if (quote == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('İlgili teklif bulunamadı.'),
                ),
              );
            }

            return Card(
              child: ListTile(
                title: Text(quote.quoteNumber),
                subtitle: Text(quote.title),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // For now, navigate back to quote detail via popping.
                  Navigator.of(context).pushNamed(
                    '/crm/quotes/detail',
                    arguments: QuoteDetailPageArgs(quote.id),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<CustomerModel?>(
          stream: CustomerService.instance.watchCustomer(order.customerId),
          builder: (context, customerSnapshot) {
            if (customerSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final customer = customerSnapshot.data;
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
        ),
        const SizedBox(height: 12),
        inventoryWidget,
      ],
    );
  }

  Future<void> _updateStatus(
    String id,
    String previousStatus,
    String newStatus,
  ) async {
    setState(() => _isUpdating = true);
    try {
      await ProductionService.instance.updateOrderStatus(id, newStatus);
      if (mounted) {
        setState(() => _selectedStatus = newStatus);
      }
      if (newStatus == 'completed' && previousStatus != 'completed') {
        final currentOrder = await ProductionService.instance.getOrderById(id);
        final inventoryId = currentOrder?.inventoryItemId;
        if (inventoryId != null) {
          await InventoryService.instance.adjustStock(
            inventoryId,
            1,
            'increase',
          );
        }
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
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.multiline = false,
  }) : assert(
         value != null || valueWidget != null,
         'Either value or valueWidget must be provided',
       );

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
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
            child:
                valueWidget ??
                Text(
                  value ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
          ),
        ],
      ),
    );
  }
}

class ProductionDetailPageArgs {
  const ProductionDetailPageArgs(this.orderId);

  final String orderId;
}
