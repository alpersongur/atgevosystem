import 'package:flutter/material.dart';

import '../services/firebase_project_service.dart';

class AddCompanyPage extends StatefulWidget {
  const AddCompanyPage({super.key});

  static const routeName = '/superadmin/companies/add';

  @override
  State<AddCompanyPage> createState() => _AddCompanyPageState();
}

class _AddCompanyPageState extends State<AddCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final Map<String, bool> _moduleSelections = {
    'crm': true,
    'quotes': false,
    'production': false,
    'accounting': false,
  };

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final selectedModules = _moduleSelections.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await FirebaseProjectService.instance.createFirebaseProject(_nameController.text.trim());

      if (!mounted) return;
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'owner_email': _ownerController.text.trim(),
        'modules': selectedModules,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şirket oluşturma talebi gönderildi.')),  
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şirket oluşturulamadı: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Şirket'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Şirket Adı'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Şirket adı zorunludur';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerController,
                  decoration: const InputDecoration(labelText: 'Sahip E-posta'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'E-posta zorunludur';
                    }
                    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!regex.hasMatch(email)) {
                      return 'Geçerli bir e-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Modül Seçimi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ..._moduleSelections.entries.map((entry) {
                  return CheckboxListTile(
                    value: entry.value,
                    title: Text(entry.key.toUpperCase()),
                    onChanged: (value) {
                      setState(() {
                        _moduleSelections[entry.key] = value ?? false;
                      });
                    },
                  );
                }),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Oluştur'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
