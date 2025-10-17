import 'package:flutter/material.dart';

import '../models/bill_model.dart';
import '../services/bill_service.dart';
import '../services/supplier_service.dart';
import '../widgets/bill_card.dart';
import 'bill_detail_page.dart';
import 'bill_edit_page.dart';

class BillListPage extends StatefulWidget {
  const BillListPage({super.key});

  static const routeName = '/purchasing/bills';

  @override
  State<BillListPage> createState() => _BillListPageState();
}

class _BillListPageState extends State<BillListPage> {
  final BillService _billService = BillService.instance;
  final SupplierService _supplierService = SupplierService.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Satınalma Faturaları')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Fatura ara (No / tedarikçi / durum)',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BillModel>>(
              stream: _billService.getBills(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Faturalar yüklenirken hata oluştu.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bills = snapshot.data ?? <BillModel>[];
                if (bills.isEmpty) {
                  return const Center(
                    child: Text('Henüz vendor faturası bulunmuyor.'),
                  );
                }

                return StreamBuilder(
                  stream: _supplierService.getSuppliers(),
                  builder: (context, supplierSnapshot) {
                    final supplierMap = <String, String>{};
                    if (supplierSnapshot.hasData) {
                      for (final supplier in supplierSnapshot.data!) {
                        supplierMap[supplier.id] = supplier.supplierName;
                      }
                    }

                    final query = _searchController.text.trim().toLowerCase();
                    final filtered = query.isEmpty
                        ? bills
                        : bills
                              .where((bill) {
                                final supplierName =
                                    supplierMap[bill.supplierId]
                                        ?.toLowerCase() ??
                                    '';
                                return bill.billNo.toLowerCase().contains(
                                      query,
                                    ) ||
                                    supplierName.contains(query) ||
                                    bill.status.toLowerCase().contains(query);
                              })
                              .toList(growable: false);

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('Aradığınız kriterde kayıt bulunamadı.'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final bill = filtered[index];
                        return BillCard(
                          bill: bill,
                          supplierName: supplierMap[bill.supplierId],
                          onTap: () => _openDetail(bill.id),
                          onEdit: () => _openEdit(bill),
                          onDelete: () => _confirmDelete(bill),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openDetail(String billId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BillDetailPage(billId: billId)));
  }

  Future<void> _openEdit(BillModel? bill) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => BillEditPage(bill: bill)));
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bill == null ? 'Fatura kaydedildi.' : 'Fatura güncellendi.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BillModel bill) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Faturayı Sil'),
            content: Text(
              '"${bill.billNo}" numaralı faturayı silmek istediğinize emin misiniz?',
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

    if (!confirmed || !mounted) return;

    try {
      await _billService.deleteBill(bill.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fatura silindi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme işlemi başarısız: $error')));
    }
  }
}
