import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/license_model.dart';
import '../services/license_service.dart';

class LicenseEditPageArgs {
  const LicenseEditPageArgs({required this.companyId, this.editLicense});

  final String companyId;
  final LicenseModel? editLicense;
}

class LicenseEditPage extends StatefulWidget {
  const LicenseEditPage({super.key, required this.args});

  static const routeName = '/superadmin/licenses/edit';

  final LicenseEditPageArgs args;

  @override
  State<LicenseEditPage> createState() => _LicenseEditPageState();
}

class _LicenseEditPageState extends State<LicenseEditPage> {
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
  ];

  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: 'TRY');
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedModules = <String>{};
  bool _isSubmitting = false;

  LicenseModel? get _editing => widget.args.editLicense;

  @override
  void initState() {
    super.initState();
    final editing = _editing;
    if (editing != null) {
      _priceController.text = editing.price.toStringAsFixed(2);
      _currencyController.text = editing.currency;
      _startDate = editing.startDate;
      _endDate = editing.endDate;
      _selectedModules
        ..clear()
        ..addAll(editing.modules);
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
      _selectedModules.addAll(const ['crm']);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? _startDate ?? DateTime.now()
        : _endDate ?? DateTime.now().add(const Duration(days: 30));
    final firstDate = isStart
        ? DateTime(2023, 1, 1)
        : _startDate ?? DateTime(2023);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 30));
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    if (_selectedModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir modül seçmelisiniz.')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlangıç ve bitiş tarihini belirtmelisiniz.'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final price = num.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;

    final payload = <String, dynamic>{
      'modules': _selectedModules.toList(),
      'start_date': Timestamp.fromDate(_startDate!),
      'end_date': Timestamp.fromDate(_endDate!),
      'price': price,
      'currency': _currencyController.text.trim().toUpperCase(),
      'status': _editing?.status ?? 'active',
    };

    try {
      final service = LicenseService.instance;
      if (_editing == null) {
        await service.addLicense(widget.args.companyId, payload);
      } else {
        await service.updateLicense(
          widget.args.companyId,
          _editing!.id,
          payload,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lisans kaydedilemedi: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Lisans Düzenle' : 'Yeni Lisans')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableModules
                      .map((module) {
                        final selected = _selectedModules.contains(module);
                        return FilterChip(
                          selected: selected,
                          label: Text(module.toUpperCase()),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Başlangıç',
                        date: _startDate,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DateField(
                        label: 'Bitiş',
                        date: _endDate,
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Fiyat',
                          prefixText: '₺ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final price = num.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          if (price == null || price <= 0) {
                            return 'Geçerli bir fiyat giriniz.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _currencyController,
                        decoration: const InputDecoration(
                          labelText: 'Para Birimi',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          final currency = value?.trim() ?? '';
                          if (currency.length != 3) {
                            return '3 harfli kod';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = date != null
        ? '${date!.day.toString().padLeft(2, '0')}.'
              '${date!.month.toString().padLeft(2, '0')}.'
              '${date!.year}'
        : '-';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(display),
      ),
    );
  }
}
