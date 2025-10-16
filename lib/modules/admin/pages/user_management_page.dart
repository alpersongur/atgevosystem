import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../widgets/role_dropdown.dart';
import '../../../services/auth_service.dart';
import 'add_user_page.dart';
import '../../../pages/main_page.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  static const routeName = '/admin/users';

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentUserRole;
    if (role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacementNamed(MainPage.routeName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yetkiniz yok.')),
        );
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AddUserPage.routeName);
            },
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Yeni Kullanıcı',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: UserService.instance.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Kullanıcılar yüklenirken bir hata oluştu.\n${snapshot.error}',
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
              child: Text('Kayıtlı kullanıcı bulunmuyor.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name = data['name'] as String? ?? 'İsimsiz Kullanıcı';
              final email = data['email'] as String? ?? '';
              final role = data['role'] as String? ?? '-';
              final department = data['department'] as String? ?? '-';
              final isActive = data['active'] != false;

              return Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(isActive ? 'Aktif' : 'Pasif'),
                            backgroundColor:
                                isActive ? Colors.green.shade100 : Colors.grey.shade300,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('E-posta: $email'),
                      Text('Rol: $role'),
                      Text('Departman: $department'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final updated =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => EditUserDialog(
                                      uid: doc.id,
                                      initialData: data,
                                    ),
                                  ) ??
                                  false;
                              if (updated && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kullanıcı güncellendi'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Düzenle'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Kullanıcıyı Sil'),
                                      content: Text(
                                        '"$name" kullanıcısını silmek istediğinize emin misiniz?',
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
                                await UserService.instance.deactivateUser(doc.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kullanıcı pasif hale getirildi'),
                                  ),
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'İşlem sırasında hata oluştu: $error',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Sil'),
                          ),
                        ],
                      ),
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

class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    required this.uid,
    required this.initialData,
  });

  final String uid;
  final Map<String, dynamic> initialData;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _departmentController;
  late String _selectedRole;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData['name'] as String? ?? '',
    );
    _departmentController = TextEditingController(
      text: widget.initialData['department'] as String? ?? '',
    );
    _selectedRole = widget.initialData['role'] as String? ?? 'sales';
    _isActive = widget.initialData['active'] != false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad alanı boş bırakılamaz')),
      );
      return;
    }
    if (_departmentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departman alanı boş bırakılamaz')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await UserService.instance.updateUser(widget.uid, {
        'name': _nameController.text.trim(),
        'department': _departmentController.text.trim(),
        'role': _selectedRole,
        'active': _isActive,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme başarısız: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kullanıcıyı Düzenle'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 12),
            RoleDropdown(
              value: _selectedRole,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedRole = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _departmentController,
              decoration: const InputDecoration(labelText: 'Departman'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              title: const Text('Aktif'),
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
