import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';
import '../widgets/inventory_card.dart';
import 'inventory_detail_page.dart';
import 'inventory_edit_page.dart';
import 'stock_scanner_page.dart';

class InventoryListPage extends StatelessWidget {
  const InventoryListPage({super.key});

  static const routeName = '/inventory';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depo & Envanter'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const InventoryEditPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<InventoryItemModel>>(
        stream: InventoryService.instance.getInventoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Envanter verileri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? <InventoryItemModel>[];
          if (items.isEmpty) {
            return const Center(
              child: Text('Henüz envanter kaydı bulunmuyor.'),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final device =
                  ResponsiveBreakpoints.sizeForWidth(constraints.maxWidth);
              final listView = ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InventoryCard(
                    item: item,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InventoryDetailPage(itemId: item.id),
                        ),
                      );
                    },
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InventoryEditPage(itemId: item.id),
                        ),
                      );
                    },
                  );
                },
              );

              if (device == DeviceSize.phone) {
                return Column(
                  children: [
                    Expanded(child: listView),
                    const SizedBox(height: 8),
                    const _InventoryQuickActions(),
                  ],
                );
              }

              return listView;
            },
          );
        },
      ),
    );
  }
}

class _InventoryQuickActions extends StatelessWidget {
  const _InventoryQuickActions();

  @override
  Widget build(BuildContext context) {
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
              onPressed: () async {
                final result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => const StockScannerPage(),
                    fullscreenDialog: true,
                  ),
                );
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Barkod okundu: $result')),
                  );
                }
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
              label: const Text(
                'Barkod Tara',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InventoryEditPage(),
                  ),
                );
              },
              icon: const Icon(Icons.inventory_2_outlined, size: 28),
              label: const Text(
                'Hızlı Stok Girişi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
