import 'package:flutter/material.dart';

import '../services/user_service.dart';

class UserEditPage extends StatefulWidget {
  const UserEditPage({super.key});

  static const routeName = '/admin/users/add';

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _roles = const [
    'superadmin',
    'admin',
    'sales',
    'production',
    'accounting',
    'purchasing',
    'warehouse',
  ];

  final List<String> _modules = const [
    'crm',
    'production',
    'finance',
    'purchasing',
    'inventory',
    'shipment',
    'admin',
    'dashboard',
    'accounting',
  ];

  final Set<String> _selectedModules = <String>{'crm', 'admin'};
  String _selectedRole = 'sales';
  bool _isSaving = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kullanıcı')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ad soyad zorunludur.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'E-posta zorunludur.';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    return emailRegex.hasMatch(text)
                        ? null
                        : 'Geçerli bir e-posta girin.';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Geçici Şifre'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre zorunludur.';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: _roles
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.toUpperCase()),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedRole = value);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Modül Erişimleri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _modules
                      .map(
                        (module) => FilterChip(
                          selected: _selectedModules.contains(module),
                          label: Text(module.toUpperCase()),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedModules.add(module);
                              } else {
                                _selectedModules.remove(module);
                              }
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      return;
    }

    if (_selectedModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir modül seçmelisiniz.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await UserService.instance.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        role: _selectedRole,
        modules: _selectedModules.toList(growable: false),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı başarıyla oluşturuldu.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı oluşturulamadı: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
