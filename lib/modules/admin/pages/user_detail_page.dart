import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:atgevosystem/core/services/auth_service.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key, required this.uid});

  final String uid;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  static const _availableRoles = [
    'superadmin',
    'admin',
    'sales',
    'production',
    'accounting',
    'purchasing',
    'warehouse',
  ];

  static const _availableModules = [
    'crm',
    'production',
    'finance',
    'purchasing',
    'shipment',
    'inventory',
    'accounting',
  ];

  final UserService _service = UserService.instance;

  bool _isSaving = false;
  UserModel? _user;
  String? _selectedRole;
  bool _isActive = true;
  final Set<String> _selectedModules = <String>{};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _service.getUserById(widget.uid);
    if (!mounted) return;
    setState(() {
      _user = user;
      _selectedRole = user?.role;
      _isActive = user?.isActive ?? true;
      _selectedModules
        ..clear()
        ..addAll(user?.modules ?? const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Detayı')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName.isEmpty
                                ? user.email
                                : user.displayName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(user.email),
                          const SizedBox(height: 16),
                          DropdownMenu<String>(
                            initialSelection: _selectedRole,
                            label: const Text('Rol'),
                            dropdownMenuEntries: _availableRoles
                                .map(
                                  (role) => DropdownMenuEntry(
                                    value: role,
                                    label: role.toUpperCase(),
                                  ),
                                )
                                .toList(growable: false),
                            onSelected: (value) {
                              setState(() => _selectedRole = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            value: _isActive,
                            title: const Text('Aktif Kullanıcı'),
                            onChanged: (value) {
                              setState(() => _isActive = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modül Erişimleri',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableModules
                                .map((module) {
                                  final selected = _selectedModules.contains(
                                    module,
                                  );
                                  return FilterChip(
                                    label: Text(module.toUpperCase()),
                                    selected: selected,
                                    onSelected: (value) {
                                      setState(() {
                                        if (value) {
                                          _selectedModules.add(module);
                                        } else {
                                          _selectedModules.remove(module);
                                        }
                                      });
                                    },
                                  );
                                })
                                .toList(growable: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir rol seçiniz.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.updateUser(widget.uid, {
        'role': _selectedRole,
        'is_active': _isActive,
        'modules': _selectedModules.toList(),
      });

      final currentUser = AuthService.instance.currentUser;
      if (currentUser != null && currentUser.uid == widget.uid) {
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        await AuthService.instance.refreshCurrentUserProfile(serverOnly: true);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kullanıcı güncellendi.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Güncelleme başarısız: $error')));
    }
  }
}
