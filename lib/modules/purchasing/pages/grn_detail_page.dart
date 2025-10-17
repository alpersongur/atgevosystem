import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/grn_model.dart';
import '../services/grn_service.dart';
import '../services/purchase_order_service.dart';
import '../services/supplier_service.dart';

class GRNDetailPage extends StatelessWidget {
  const GRNDetailPage({super.key, required this.grnId});

  final String grnId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GRN Detayı')),
      body: StreamBuilder<GRNModel?>(
        stream: GRNService.instance.watchGRN(grnId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'GRN bilgisi yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final grn = snapshot.data;
          if (grn == null) {
            return const Center(
              child: Text('GRN bulunamadı veya silinmiş olabilir.'),
            );
          }

          return _GRNDetailContent(grn: grn);
        },
      ),
    );
  }
}

class _GRNDetailContent extends StatefulWidget {
  const _GRNDetailContent({required this.grn});

  final GRNModel grn;

  @override
  State<_GRNDetailContent> createState() => _GRNDetailContentState();
}

class _GRNDetailContentState extends State<_GRNDetailContent> {
  late Future<String?> _supplierFuture;
  late Future<String?> _poNumberFuture;

  @override
  void initState() {
    super.initState();
    _supplierFuture = _loadSupplierName();
    _poNumberFuture = _loadPONumber();
  }

  Future<String?> _loadSupplierName() async {
    final supplier = await SupplierService.instance.getSupplierById(
      widget.grn.supplierId,
    );
    return supplier?.supplierName;
  }

  Future<String?> _loadPONumber() async {
    final po = await PurchaseOrderService.instance.getPOById(widget.grn.poId);
    return po?.poNumber;
  }

  @override
  Widget build(BuildContext context) {
    final grn = widget.grn;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return FutureBuilder<List<String?>>(
      future: Future.wait([_supplierFuture, _poNumberFuture]),
      builder: (context, snapshot) {
        final supplierName = snapshot.hasData ? snapshot.data![0] : null;
        final poNumber = snapshot.hasData ? snapshot.data![1] : null;

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
                        grn.receiptNo,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Satınalma Emri',
                        value: poNumber ?? grn.poId,
                      ),
                      _DetailRow(
                        label: 'Tedarikçi',
                        value: supplierName ?? grn.supplierId,
                      ),
                      _DetailRow(
                        label: 'Durum',
                        value: grn.status.toUpperCase(),
                      ),
                      _DetailRow(
                        label: 'Teslim Tarihi',
                        value: grn.receivedDate != null
                            ? DateFormat('dd.MM.yyyy').format(grn.receivedDate!)
                            : 'Belirtilmemiş',
                      ),
                      _DetailRow(label: 'Depo', value: grn.warehouse),
                      if ((grn.notes ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(grn.notes!),
                        ),
                      if (grn.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Oluşturma: ${dateFormat.format(grn.createdAt!)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      if (grn.updatedAt != null)
                        Text(
                          'Güncelleme: ${dateFormat.format(grn.updatedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
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
                        'Malzeme Satırları',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Stok Kodu')),
                            DataColumn(label: Text('Miktar')),
                            DataColumn(label: Text('Birim')),
                          ],
                          rows: grn.lines
                              .map(
                                (line) => DataRow(
                                  cells: [
                                    DataCell(Text(line.sku)),
                                    DataCell(Text(line.receivedQty.toString())),
                                    DataCell(Text(line.unit)),
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
