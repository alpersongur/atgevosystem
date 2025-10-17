import 'package:flutter/material.dart';

import '../models/purchase_order_model.dart';
import '../services/purchase_order_service.dart';
import '../services/supplier_service.dart';
import '../widgets/po_card.dart';
import 'po_detail_page.dart';
import 'po_edit_page.dart';

class POListPage extends StatefulWidget {
  const POListPage({super.key});

  static const routeName = '/purchasing/pos';

  @override
  State<POListPage> createState() => _POListPageState();
}

class _POListPageState extends State<POListPage> {
  final PurchaseOrderService _poService = PurchaseOrderService.instance;
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
      appBar: AppBar(title: const Text('Satınalma Emirleri')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Emir ara (PO No / tedarikçi / durum)',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PurchaseOrderModel>>(
              stream: _poService.getPOs(),
              builder: (context, poSnapshot) {
                if (poSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Satınalma emirleri yüklenirken hata oluştu.\n${poSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (poSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = poSnapshot.data ?? <PurchaseOrderModel>[];
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('Henüz satınalma emri bulunmuyor.'),
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
                        ? orders
                        : orders
                              .where((order) {
                                final supplierName =
                                    supplierMap[order.supplierId]
                                        ?.toLowerCase() ??
                                    '';
                                return order.poNumber.toLowerCase().contains(
                                      query,
                                    ) ||
                                    supplierName.contains(query) ||
                                    order.status.toLowerCase().contains(query);
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
                        final order = filtered[index];
                        return PurchaseOrderCard(
                          order: order,
                          supplierName: supplierMap[order.supplierId],
                          onTap: () => _openDetail(order.id),
                          onEdit: () => _openEdit(order),
                          onDelete: () => _confirmDelete(order),
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

  Future<void> _openDetail(String poId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PODetailPage(poId: poId)));
  }

  Future<void> _openEdit(PurchaseOrderModel? order) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => POEditPage(order: order)));

    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            order == null
                ? 'Satınalma emri oluşturuldu.'
                : 'Satınalma emri güncellendi.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(PurchaseOrderModel order) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Satınalma Emrini Sil'),
            content: Text(
              '"${order.poNumber}" numaralı emri silmek istediğinize emin misiniz?',
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
      await _poService.deletePO(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Satınalma emri silindi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme işlemi başarısız: $error')));
    }
  }
}
