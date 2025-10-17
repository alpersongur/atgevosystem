import 'package:flutter/material.dart';

import '../models/grn_model.dart';
import '../services/grn_service.dart';
import '../services/supplier_service.dart';
import '../widgets/grn_card.dart';
import 'grn_detail_page.dart';
import 'grn_edit_page.dart';

class GRNListPage extends StatefulWidget {
  const GRNListPage({super.key});

  static const routeName = '/purchasing/grn';

  @override
  State<GRNListPage> createState() => _GRNListPageState();
}

class _GRNListPageState extends State<GRNListPage> {
  final GRNService _grnService = GRNService.instance;
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
      appBar: AppBar(title: const Text('Mal Kabul (GRN)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'GRN ara (Numara / tedarikçi / durum)',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GRNModel>>(
              stream: _grnService.getGRNs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Mal kabuller yüklenirken hata oluştu.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final grns = snapshot.data ?? <GRNModel>[];
                if (grns.isEmpty) {
                  return const Center(
                    child: Text('Henüz mal kabul kaydı bulunmuyor.'),
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
                        ? grns
                        : grns
                              .where((grn) {
                                final supplierName =
                                    supplierMap[grn.supplierId]
                                        ?.toLowerCase() ??
                                    '';
                                return grn.receiptNo.toLowerCase().contains(
                                      query,
                                    ) ||
                                    supplierName.contains(query) ||
                                    grn.status.toLowerCase().contains(query);
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
                        final grn = filtered[index];
                        return GRNCard(
                          grn: grn,
                          supplierName: supplierMap[grn.supplierId],
                          onTap: () => _openDetail(grn.id),
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
        onPressed: () => _openEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openDetail(String grnId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GRNDetailPage(grnId: grnId)));
  }

  Future<void> _openEdit() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const GRNEditPage()));
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mal kabul kaydı oluşturuldu.')),
      );
    }
  }
}
