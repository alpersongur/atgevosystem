import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/customer_service.dart';
import 'add_customer_page.dart';

class CustomersListPage extends StatelessWidget {
  const CustomersListPage({super.key});

  static const routeName = '/customers';

  @override
  Widget build(BuildContext context) {
    final stream = FirestoreService.instance.getCustomers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Listesi'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Veriler alınırken bir hata oluştu.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Henüz müşteri kaydı bulunmuyor.'),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = data['name'] as String? ?? 'Adsız Müşteri';
              final email = data['email'] as String? ?? '-';
              final phone = data['phone'] as String? ?? '-';
              final address = data['address'] as String? ?? '-';

              return Card(
                elevation: 1,
                child: ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(email),
                      Text(phone),
                      Text(address),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Düzenle',
                        onPressed: () {
                          // Düzenleme akışı ileride eklenecek.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Düzenleme özelliği yakında.'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever),
                        tooltip: 'Sil',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Müşteri Sil'),
                                  content: Text(
                                    '"$name" kaydını silmek istediğinize emin misiniz?',
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

                          if (!confirm || !context.mounted) return;

                          try {
                            await FirestoreService.instance
                                .deleteCustomer(doc.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Müşteri silindi'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Silme sırasında bir hata oluştu: $error',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AddCustomerPage.routeName);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
