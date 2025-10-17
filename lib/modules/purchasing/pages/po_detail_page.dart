import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/purchase_order_model.dart';
import '../services/purchase_order_service.dart';
import '../services/supplier_service.dart';
import 'bill_edit_page.dart';
import 'po_edit_page.dart';

class PODetailPage extends StatelessWidget {
  const PODetailPage({super.key, required this.poId});

  final String poId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satınalma Emri Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: StreamBuilder<PurchaseOrderModel?>(
        stream: PurchaseOrderService.instance.watchPO(poId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Satınalma emri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(
              child: Text('Satınalma emri bulunamadı veya silinmiş olabilir.'),
            );
          }

          return _PODetailContent(order: order);
        },
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final order = await PurchaseOrderService.instance.getPOById(poId);
    if (!context.mounted) return;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satınalma emri bulunamadı.')),
      );
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => POEditPage(order: order)));
  }
}

class _PODetailContent extends StatefulWidget {
  const _PODetailContent({required this.order});

  final PurchaseOrderModel order;

  @override
  State<_PODetailContent> createState() => _PODetailContentState();
}

class _PODetailContentState extends State<_PODetailContent> {
  late Future<String?> _supplierNameFuture;

  @override
  void initState() {
    super.initState();
    _supplierNameFuture = _loadSupplier();
  }

  Future<String?> _loadSupplier() async {
    final supplier = await SupplierService.instance.getSupplierById(
      widget.order.supplierId,
    );
    return supplier?.supplierName;
  }

  Future<void> _createBill(PurchaseOrderModel order) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BillEditPage(initialPO: order)));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final currencyFormat = NumberFormat.currency(
      symbol: order.currency,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd.MM.yyyy');

    return FutureBuilder<String?>(
      future: _supplierNameFuture,
      builder: (context, supplierSnapshot) {
        final supplierName = supplierSnapshot.data ?? order.supplierId;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.poNumber,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Tedarikçi', value: supplierName),
                      _DetailRow(
                        label: 'Durum',
                        value: order.status.toUpperCase(),
                      ),
                      if (order.expectedDate != null)
                        _DetailRow(
                          label: 'Beklenen Tarih',
                          value: dateFormat.format(order.expectedDate!),
                        ),
                      _DetailRow(
                        label: 'Satır Sayısı',
                        value: '${order.lines.length}',
                      ),
                      if ((order.notes ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(order.notes!),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _createBill(order),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Fatura Oluştur'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satır Detayları',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Stok Kodu')),
                            DataColumn(label: Text('Ürün')),
                            DataColumn(label: Text('Miktar')),
                            DataColumn(label: Text('Birim')),
                            DataColumn(label: Text('Fiyat')),
                            DataColumn(label: Text('Toplam')),
                          ],
                          rows: order.lines
                              .map(
                                (line) => DataRow(
                                  cells: [
                                    DataCell(Text(line.sku)),
                                    DataCell(Text(line.name)),
                                    DataCell(Text(line.quantity.toString())),
                                    DataCell(Text(line.unit)),
                                    DataCell(
                                      Text(currencyFormat.format(line.price)),
                                    ),
                                    DataCell(
                                      Text(
                                        currencyFormat.format(line.lineTotal),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Özet',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Ara Toplam',
                        value: currencyFormat.format(order.subtotal),
                      ),
                      _DetailRow(
                        label:
                            'Vergi ${(order.taxRate * 100).toStringAsFixed(1)}%',
                        value: currencyFormat.format(order.taxTotal),
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Genel Toplam',
                        value: currencyFormat.format(order.grandTotal),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
