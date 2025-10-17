import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/module_service.dart';

class ModuleManagementPage extends StatelessWidget {
  const ModuleManagementPage({super.key});

  static const routeName = '/superadmin/modules';

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isActive = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni Modül'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Modül Adı'),
                    ),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Kod'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Açıklama'),
                      maxLines: 3,
                    ),
                    SwitchListTile(
                      title: const Text('Aktif'),
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final code = codeController.text.trim();
                    final description = descriptionController.text.trim();
                    if (name.isEmpty || code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ad ve kod zorunludur')),
                      );
                      return;
                    }

                    await ModuleService.instance.addModule({
                      'name': name,
                      'code': code,
                      'description': description,
                      'active': isActive,
                    });
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modül Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Modül',
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ModuleService.instance.getModules(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Modüller yüklenirken hata oluştu\n${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Kayıtlı modül yok.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = data['name'] as String? ?? 'Adsız Modül';
              final code = data['code'] as String? ?? '-';
              final description = data['description'] as String? ?? '';
              final isActive = data['active'] == true;

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kod: $code'),
                      if (description.isNotEmpty) Text(description),
                    ],
                  ),
                  trailing: Switch(
                    value: isActive,
                    onChanged: (value) {
                      ModuleService.instance.updateModuleStatus(doc.id, value);
                    },
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
