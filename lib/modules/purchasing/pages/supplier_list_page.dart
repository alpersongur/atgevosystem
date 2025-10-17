import 'package:flutter/material.dart';

import '../models/supplier_model.dart';
import '../services/supplier_service.dart';
import '../widgets/supplier_card.dart';
import 'supplier_detail_page.dart';
import 'supplier_edit_page.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  static const routeName = '/purchasing/suppliers';

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  final SupplierService _service = SupplierService.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tedarikçi Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tedarikçi ara...',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SupplierModel>>(
              stream: _service.getSuppliers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Tedarikçiler yüklenirken hata oluştu.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final suppliers = snapshot.data ?? <SupplierModel>[];
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? suppliers
                    : suppliers
                          .where(
                            (supplier) =>
                                supplier.supplierName.toLowerCase().contains(
                                  query,
                                ) ||
                                supplier.contactPerson.toLowerCase().contains(
                                  query,
                                ) ||
                                supplier.city.toLowerCase().contains(query),
                          )
                          .toList(growable: false);

                if (filtered.isEmpty) {
                  return const Center(child: Text('Tedarikçi bulunamadı.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final supplier = filtered[index];
                    return SupplierCard(
                      supplier: supplier,
                      onTap: () => _openDetail(supplier),
                      onEdit: () => _openEdit(supplier),
                      onDelete: () => _confirmDelete(supplier),
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

  Future<void> _openDetail(SupplierModel supplier) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupplierDetailPage(supplierId: supplier.id),
      ),
    );
  }

  Future<void> _openEdit(SupplierModel? supplier) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SupplierEditPage(supplier: supplier)),
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            supplier == null
                ? 'Tedarikçi oluşturuldu.'
                : 'Tedarikçi güncellendi.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(SupplierModel supplier) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tedarikçiyi Sil'),
            content: Text(
              '"${supplier.supplierName}" kaydını silmek istediğinize emin misiniz?',
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
      await _service.deleteSupplier(supplier.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tedarikçi silindi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme işlemi başarısız: $error')));
    }
  }
}
