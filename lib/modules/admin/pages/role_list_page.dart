import 'package:flutter/material.dart';

import '../models/role_model.dart';
import '../services/role_service.dart';
import '../widgets/role_card.dart';
import 'role_detail_page.dart';

class RoleListPage extends StatefulWidget {
  const RoleListPage({super.key});

  static const routeName = '/admin/roles';

  @override
  State<RoleListPage> createState() => _RoleListPageState();
}

class _RoleListPageState extends State<RoleListPage> {
  final RoleService _service = RoleService.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rol Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rol ara (isim, açıklama)',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RoleModel>>(
              stream: _service.getRolesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Roller yüklenirken hata oluştu.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final roles = snapshot.data ?? <RoleModel>[];
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? roles
                    : roles
                          .where((role) {
                            return role.roleName.toLowerCase().contains(
                                  query,
                                ) ||
                                role.description.toLowerCase().contains(query);
                          })
                          .toList(growable: false);

                if (filtered.isEmpty) {
                  return const Center(child: Text('Rol bulunamadı.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final role = filtered[index];
                    return RoleCard(
                      role: role,
                      onTap: () => _openDetail(role),
                      onEdit: () => _openDetail(role),
                      onDelete: () => _confirmDelete(role),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDetail(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openDetail(RoleModel? role) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => RoleDetailPage(role: role)));
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(role == null ? 'Rol oluşturuldu.' : 'Rol güncellendi.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(RoleModel role) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rolü Sil'),
            content: Text(
              '"${role.roleName}" rolünü silmek istediğinize emin misiniz?',
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
      await _service.deleteRole(role.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rol silindi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme işlemi başarısız: $error')));
    }
  }
}
