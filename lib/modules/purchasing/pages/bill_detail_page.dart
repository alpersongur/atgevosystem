import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bill_model.dart';
import '../models/purchase_order_model.dart';
import '../services/bill_service.dart';
import '../services/purchase_order_service.dart';
import '../services/supplier_service.dart';
import 'bill_edit_page.dart';

class BillDetailPage extends StatelessWidget {
  const BillDetailPage({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Fatura Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: StreamBuilder<BillModel?>(
        stream: BillService.instance.watchBill(billId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Fatura bilgisi yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bill = snapshot.data;
          if (bill == null) {
            return const Center(
              child: Text('Fatura bulunamadı veya silinmiş olabilir.'),
            );
          }

          return _BillDetailContent(bill: bill);
        },
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final bill = await BillService.instance.getBillById(billId);
    if (!context.mounted) return;
    if (bill == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fatura bulunamadı.')));
      return;
    }

    PurchaseOrderModel? po;
    if (bill.poId.isNotEmpty) {
      po = await PurchaseOrderService.instance.getPOById(bill.poId);
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillEditPage(bill: bill, initialPO: po),
      ),
    );
  }
}

class _BillDetailContent extends StatefulWidget {
  const _BillDetailContent({required this.bill});

  final BillModel bill;

  @override
  State<_BillDetailContent> createState() => _BillDetailContentState();
}

class _BillDetailContentState extends State<_BillDetailContent> {
  late Future<String?> _supplierNameFuture;
  late Future<String?> _poNumberFuture;

  @override
  void initState() {
    super.initState();
    _supplierNameFuture = _loadSupplierName();
    _poNumberFuture = _loadPONumber();
  }

  Future<String?> _loadSupplierName() async {
    final supplier = await SupplierService.instance.getSupplierById(
      widget.bill.supplierId,
    );
    return supplier?.supplierName;
  }

  Future<String?> _loadPONumber() async {
    if (widget.bill.poId.isEmpty) return null;
    final po = await PurchaseOrderService.instance.getPOById(widget.bill.poId);
    return po?.poNumber;
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final currencyFormat = NumberFormat.currency(
      symbol: bill.currency,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd.MM.yyyy');

    return FutureBuilder<List<String?>>(
      future: Future.wait([_supplierNameFuture, _poNumberFuture]),
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
                        bill.billNo,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Satınalma Emri',
                        value:
                            poNumber ?? (bill.poId.isEmpty ? '—' : bill.poId),
                      ),
                      _DetailRow(
                        label: 'Tedarikçi',
                        value: supplierName ?? bill.supplierId,
                      ),
                      _DetailRow(
                        label: 'Durum',
                        value: bill.status.toUpperCase(),
                      ),
                      _DetailRow(
                        label: 'Fatura Tarihi',
                        value: bill.issueDate != null
                            ? dateFormat.format(bill.issueDate!)
                            : 'Belirtilmemiş',
                      ),
                      _DetailRow(
                        label: 'Vade Tarihi',
                        value: bill.dueDate != null
                            ? dateFormat.format(bill.dueDate!)
                            : 'Belirtilmemiş',
                      ),
                      if ((bill.notes ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(bill.notes!),
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
                        value: currencyFormat.format(bill.subtotal),
                      ),
                      _DetailRow(
                        label:
                            'Vergi ${(bill.taxRate * 100).toStringAsFixed(1)}%',
                        value: currencyFormat.format(bill.taxTotal),
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Genel Toplam',
                        value: currencyFormat.format(bill.grandTotal),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durum Güncelle',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final status in const [
                            'unpaid',
                            'partial',
                            'paid',
                            'canceled',
                          ])
                            ChoiceChip(
                              label: Text(status.toUpperCase()),
                              selected: bill.status == status,
                              onSelected: (selected) {
                                if (selected && bill.status != status) {
                                  BillService.instance.markBillStatus(
                                    bill.id,
                                    status,
                                  );
                                }
                              },
                            ),
                        ],
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
