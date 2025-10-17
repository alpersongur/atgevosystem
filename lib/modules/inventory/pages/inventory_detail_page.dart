import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/auth_service.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';
import '../widgets/inventory_card.dart';
import '../widgets/stock_adjustment_dialog.dart';
import 'inventory_edit_page.dart';

class InventoryDetailPage extends StatelessWidget {
  const InventoryDetailPage({super.key, required this.itemId});

  static const routeName = '/inventory/detail';

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Envanter Detayı')),
      body: StreamBuilder<InventoryItemModel?>(
        stream: InventoryService.instance.watchItem(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final item = snapshot.data;
          if (item == null) {
            return const Center(
              child: Text('Envanter kaydı bulunamadı veya silinmiş olabilir.'),
            );
          }

          return _InventoryDetailContent(item: item);
        },
      ),
    );
  }
}

class _InventoryDetailContent extends StatelessWidget {
  const _InventoryDetailContent({required this.item});

  final InventoryItemModel item;

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        AuthService.instance.currentUserRole?.toLowerCase() == 'superadmin';
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InventoryCard(item: item),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detaylar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'SKU', value: item.sku),
                  _DetailRow(label: 'Kategori', value: item.category),
                  _DetailRow(label: 'Konum', value: item.location),
                  _DetailRow(
                    label: 'Minimum Stok',
                    value: '${item.minStock} ${item.unit}',
                  ),
                  _DetailRow(
                    label: 'Durum',
                    value: item.status == 'active' ? 'Aktif' : 'Pasif',
                  ),
                  _DetailRow(
                    label: 'Güncellenme',
                    value: item.updatedAt != null
                        ? dateFormat.format(item.updatedAt!)
                        : '—',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => _adjustStock(context, 'increase'),
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Stok Ekle'),
              ),
              ElevatedButton.icon(
                onPressed: () => _adjustStock(context, 'decrease'),
                icon: const Icon(Icons.indeterminate_check_box_outlined),
                label: const Text('Stok Azalt'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InventoryEditPage(itemId: item.id),
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
                  onPressed: () => _deleteItem(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Sil'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _adjustStock(BuildContext context, String operation) async {
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => StockAdjustmentDialog(operation: operation),
    );

    if (amount == null) return;

    try {
      await InventoryService.instance.adjustStock(item.id, amount, operation);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            operation == 'increase' ? 'Stok arttırıldı.' : 'Stok azaltıldı.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stok güncellenemedi: $error')));
    }
  }

  Future<void> _deleteItem(BuildContext context) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Envanter Kaydını Sil'),
            content: Text(
              '"${item.productName}" kaydını silmek istediğinize emin misiniz?',
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

    if (!confirm) return;

    try {
      await InventoryService.instance.deleteItem(item.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Envanter kaydı silindi.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme işlemi başarısız: $error')));
    }
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class InventoryDetailPageArgs {
  const InventoryDetailPageArgs(this.itemId);

  final String itemId;
}
