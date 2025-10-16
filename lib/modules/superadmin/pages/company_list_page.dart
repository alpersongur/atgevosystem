import 'package:flutter/material.dart';

import '../services/company_service.dart';

class CompanyListPage extends StatelessWidget {
  const CompanyListPage({super.key});

  static const routeName = '/superadmin/companies';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şirketler'),
      ),
      body: StreamBuilder(
        stream: CompanyService.instance.getCompanies(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Şirketler yüklenirken hata oluştu\n${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Kayıtlı şirket bulunmuyor.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = data['name'] as String? ?? 'Adsız Şirket';
              final projectId = data['projectId'] as String? ?? '-';
              final active = data['active'] != false;
              final modules = List<String>.from(data['modules'] as List? ?? []);

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Project ID: $projectId'),
                      Text('Modüller: ${modules.isEmpty ? '-' : modules.join(', ')}'),
                      Text('Durum: ${active ? 'Aktif' : 'Pasif'}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'view':
                          // Gelecekte detay sayfasına yönlendirme
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Detay sayfası yakında.')),
                          );
                          break;
                        case 'deactivate':
                          await CompanyService.instance.deactivateCompany(doc.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$name pasif edildi')),
                            );
                          }
                          break;
                        case 'delete':
                          final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Şirketi Sil'),
                                  content: Text('"$name" şirketini silmek istediğinize emin misiniz?'),
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
                          if (confirm) {
                            await CompanyService.instance.deleteCompany(doc.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$name silindi')),
                              );
                            }
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('Görüntüle')),
                      PopupMenuItem(value: 'deactivate', child: Text('Pasif Et')),
                      PopupMenuItem(value: 'delete', child: Text('Sil')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
