import 'package:flutter/material.dart';

import '../services/lead_service.dart';

class LeadFormPage extends StatefulWidget {
  const LeadFormPage({super.key});

  static const routeName = '/leads/form';

  @override
  State<LeadFormPage> createState() => _LeadFormPageState();
}

class LeadFormPageArguments {
  const LeadFormPageArguments({
    this.leadId,
    this.initialData,
  });

  final String? leadId;
  final Map<String, dynamic>? initialData;
}

class _LeadFormPageState extends State<LeadFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();
  final _assignedToController = TextEditingController();

  final List<String> _statusOptions = const [
    'new',
    'contacted',
    'qualified',
    'lost',
  ];

  String? _status;
  String? _leadId;
  bool _isSaving = false;
  bool _isInitialized = false;

  bool get _isEditing => _leadId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as LeadFormPageArguments?;
    if (args != null) {
      _leadId = args.leadId;
      final data = args.initialData ?? {};
      _nameController.text = (data['name'] as String?) ?? '';
      _companyController.text = (data['company'] as String?) ?? '';
      _contactController.text = (data['contact'] as String?) ?? '';
      _notesController.text = (data['notes'] as String?) ?? '';
      _assignedToController.text = (data['assigned_to'] as String?) ?? '';
      _status = (data['status'] as String?) ?? _statusOptions.first;
    }

    _status ??= _statusOptions.first;
    _isInitialized = true;
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      return;
    }

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'company': _companyController.text.trim(),
      'contact': _contactController.text.trim(),
      'status': _status,
      'notes': _notesController.text.trim(),
      'assigned_to': _assignedToController.text.trim(),
    };

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await LeadService.instance.updateLead(_leadId!, payload);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        await LeadService.instance.addLead(payload);
        if (!mounted) return;

        form.reset();
        _status = _statusOptions.first;
        _nameController.clear();
        _companyController.clear();
        _contactController.clear();
        _notesController.clear();
        _assignedToController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead kaydedildi')),
        );
        setState(() {});
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme sırasında hata oluştu: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Lead Düzenle' : 'Lead Ekle';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ad soyad zorunludur';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Şirket'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration:
                      const InputDecoration(labelText: 'İletişim Bilgisi'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'İletişim bilgisi zorunludur';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Durum'),
                  items: _statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _status = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notlar'),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _assignedToController,
                  decoration:
                      const InputDecoration(labelText: 'Sorumlu Kullanıcı'),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _handleSubmit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
