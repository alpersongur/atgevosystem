import 'package:flutter/material.dart';

import '../models/tenant_model.dart';
import '../services/tenant_service.dart';

class TenantEditPageArgs {
  const TenantEditPageArgs({this.editTenant});

  final TenantModel? editTenant;
}

class TenantEditPage extends StatefulWidget {
  const TenantEditPage({super.key, this.args});

  static const routeName = '/superadmin/tenants/edit';

  final TenantEditPageArgs? args;

  @override
  State<TenantEditPage> createState() => _TenantEditPageState();
}

class _TenantEditPageState extends State<TenantEditPage> {
  static const List<String> _availableModules = <String>[
    'crm',
    'finance',
    'production',
    'inventory',
    'purchasing',
    'shipment',
    'admin',
    'ai',
    'monitoring',
    'automation',
    'mobile',
    'dashboard',
  ];

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _firebaseProjectIdController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final Set<String> _selectedModules = <String>{};
  String _status = 'active';
  bool _isSubmitting = false;

  TenantModel? get _editingTenant => widget.args?.editTenant;

  @override
  void initState() {
    super.initState();
    final tenant = _editingTenant;
    if (tenant != null) {
      _companyNameController.text = tenant.companyName;
      _firebaseProjectIdController.text = tenant.firebaseProjectId;
      _ownerEmailController.text = tenant.ownerEmail;
      _selectedModules
        ..clear()
        ..addAll(tenant.modules);
      _status = tenant.status;
    } else {
      _selectedModules.add('crm');
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _firebaseProjectIdController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    if (_selectedModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir modül seçimi yapmanız gerekir.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final tenantService = TenantService.instance;
    final payload = <String, dynamic>{
      'company_name': _companyNameController.text.trim(),
      'firebase_project_id': _firebaseProjectIdController.text.trim(),
      'owner_email': _ownerEmailController.text.trim(),
      'modules': _selectedModules.toList(),
      'status': _status,
    };

    try {
      if (_editingTenant == null) {
        await tenantService.addCompany(payload);
      } else {
        await tenantService.updateCompany(_editingTenant!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Firma kaydedilemedi: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingTenant != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Firma Düzenle' : 'Yeni Firma')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Firma Adı',
                    helperText: 'İş ortaklarınız tarafından görünen isim.',
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) {
                      return 'Firma adı zorunludur.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firebaseProjectIdController,
                  decoration: const InputDecoration(
                    labelText: 'Firebase Project ID',
                    helperText:
                        'Tenant bazlı Firebase projesinin kimliği (ör: atgevo-atgmakina).',
                  ),
                  validator: (value) {
                    final projectId = value?.trim() ?? '';
                    if (projectId.isEmpty) {
                      return 'Firebase Project ID zorunludur.';
                    }
                    final regex = RegExp(r'^[a-z0-9-]+$');
                    if (!regex.hasMatch(projectId)) {
                      return 'Sadece küçük harf, rakam ve tire kullanılabilir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Sorumlu E-posta',
                    helperText: 'Firma yönetiminden sorumlu kişi/ekip.',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'E-posta zorunludur.';
                    }
                    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!regex.hasMatch(email)) {
                      return 'Geçerli bir e-posta giriniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(value: 'inactive', child: Text('Pasif')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                  decoration: const InputDecoration(labelText: 'Durum'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Modül Erişimleri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableModules
                      .map((module) {
                        final isSelected = _selectedModules.contains(module);
                        return FilterChip(
                          selected: isSelected,
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
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(isEditing ? 'Güncelle' : 'Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
