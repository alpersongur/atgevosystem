import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/lead_service.dart';
import 'lead_form_page.dart';

class LeadListPage extends StatelessWidget {
  const LeadListPage({super.key});

  static const routeName = '/leads';

  @override
  Widget build(BuildContext context) {
    final stream = LeadService.instance.getLeads();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Listesi'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lead verileri alınırken hata oluştu.\n${snapshot.error}',
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
              child: Text('Henüz lead kaydı bulunmuyor.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name = data['name'] as String? ?? 'İsimsiz Lead';
              final company = data['company'] as String? ?? '-';
              final status = data['status'] as String? ?? 'new';
              final assignedTo = data['assigned_to'] as String? ?? '-';
              final notes = data['notes'] as String? ?? '';

              return Card(
                elevation: 1,
                child: ListTile(
                  title: Text(name),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Şirket: $company'),
                        Text('Durum: $status'),
                        Text('Sorumlu: $assignedTo'),
                        if (notes.isNotEmpty) Text('Not: $notes'),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Düzenle',
                        onPressed: () async {
                          final result = await Navigator.of(context).pushNamed(
                            LeadFormPage.routeName,
                            arguments: LeadFormPageArguments(
                              leadId: doc.id,
                              initialData: data,
                            ),
                          );
                          if (!context.mounted) return;
                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lead güncellendi'),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Sil',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Lead Sil'),
                                  content: Text(
                                    '"$name" lead kaydını silmek istediğinize emin misiniz?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Vazgeç'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (!confirm || !context.mounted) return;

                          try {
                            await LeadService.instance.deleteLead(doc.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lead silindi')),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Silme sırasında hata oluştu: $error',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(LeadFormPage.routeName);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
