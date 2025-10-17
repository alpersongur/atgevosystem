import 'package:flutter/material.dart';

import '../models/role_model.dart';
import '../services/role_service.dart';

class RoleDetailPage extends StatefulWidget {
  const RoleDetailPage({super.key, this.role});

  final RoleModel? role;

  bool get isEditing => role != null;

  @override
  State<RoleDetailPage> createState() => _RoleDetailPageState();
}

class _RoleDetailPageState extends State<RoleDetailPage> {
  static const _moduleKeys = [
    'crm',
    'production',
    'finance',
    'purchasing',
    'shipment',
    'inventory',
    'accounting',
  ];

  final _formKey = GlobalKey<FormState>();
  final RoleService _service = RoleService.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final Map<String, bool> _permissions = {
    for (final key in _moduleKeys) key: false,
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    _nameController = TextEditingController(text: role?.roleName ?? '');
    _descriptionController = TextEditingController(
      text: role?.description ?? '',
    );
    if (role != null) {
      for (final entry in role.permissions.entries) {
        if (_permissions.containsKey(entry.key)) {
          _permissions[entry.key] = entry.value;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Rolü Düzenle' : 'Yeni Rol'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Rol Adı'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Rol adı zorunludur.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Modül İzinleri',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._moduleKeys.map(
              (moduleKey) => SwitchListTile(
                title: Text(moduleKey.toUpperCase()),
                value: _permissions[moduleKey] ?? false,
                onChanged: (value) {
                  setState(() => _permissions[moduleKey] = value);
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'role_name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'permissions': _permissions,
    };

    try {
      if (widget.isEditing) {
        await _service.updateRole(widget.role!.id, payload);
      } else {
        await _service.addRole(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydetme başarısız: $error')));
    }
  }
}
