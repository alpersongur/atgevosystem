import 'package:flutter/material.dart';

import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';
import '../widgets/inventory_card.dart';
import 'inventory_detail_page.dart';
import 'inventory_edit_page.dart';

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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
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
        },
      ),
    );
  }
}
