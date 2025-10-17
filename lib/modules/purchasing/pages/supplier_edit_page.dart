import 'package:flutter/material.dart';

import '../models/supplier_model.dart';
import '../services/supplier_service.dart';

class SupplierEditPage extends StatefulWidget {
  const SupplierEditPage({super.key, this.supplier});

  final SupplierModel? supplier;

  bool get isEditing => supplier != null;

  @override
  State<SupplierEditPage> createState() => _SupplierEditPageState();
}

class _SupplierEditPageState extends State<SupplierEditPage> {
  final _formKey = GlobalKey<FormState>();
  final SupplierService _service = SupplierService.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _notesController;

  String _paymentTerms = 'net30';
  String _status = 'active';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    _nameController = TextEditingController(text: supplier?.supplierName ?? '');
    _contactController = TextEditingController(
      text: supplier?.contactPerson ?? '',
    );
    _emailController = TextEditingController(text: supplier?.email ?? '');
    _phoneController = TextEditingController(text: supplier?.phone ?? '');
    _addressController = TextEditingController(text: supplier?.address ?? '');
    _cityController = TextEditingController(text: supplier?.city ?? '');
    _countryController = TextEditingController(text: supplier?.country ?? '');
    _taxNumberController = TextEditingController(
      text: supplier?.taxNumber ?? '',
    );
    _notesController = TextEditingController(text: supplier?.notes ?? '');
    _paymentTerms = supplier?.paymentTerms ?? 'net30';
    _status = supplier?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _taxNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Tedarikçi Düzenle' : 'Yeni Tedarikçi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tedarikçi Adı'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tedarikçi adı zorunludur.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Yetkili Kişi'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-posta'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if ((value ?? '').isEmpty) return null;
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(value!)) {
                  return 'Geçerli bir e-posta giriniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adres'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Şehir'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(labelText: 'Ülke'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxNumberController,
              decoration: const InputDecoration(labelText: 'Vergi Numarası'),
            ),
            const SizedBox(height: 16),
            DropdownMenu<String>(
              initialSelection: _paymentTerms,
              label: const Text('Ödeme Koşulu'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'net15', label: 'Net 15'),
                DropdownMenuEntry(value: 'net30', label: 'Net 30'),
                DropdownMenuEntry(value: 'advance', label: 'Peşin'),
                DropdownMenuEntry(value: 'custom', label: 'Özel'),
              ],
              onSelected: (value) {
                if (value != null) {
                  setState(() => _paymentTerms = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownMenu<String>(
              initialSelection: _status,
              label: const Text('Durum'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'active', label: 'Aktif'),
                DropdownMenuEntry(value: 'inactive', label: 'Pasif'),
              ],
              onSelected: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notlar'),
              maxLines: 3,
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
      'supplier_name': _nameController.text.trim(),
      'contact_person': _contactController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'tax_number': _taxNumberController.text.trim(),
      'payment_terms': _paymentTerms,
      'status': _status,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      if (widget.isEditing) {
        await _service.updateSupplier(widget.supplier!.id, payload);
      } else {
        await _service.addSupplier(payload);
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
