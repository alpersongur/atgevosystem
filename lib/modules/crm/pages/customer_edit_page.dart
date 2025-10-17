import 'package:flutter/material.dart';

import 'package:atgevosystem/core/models/customer.dart';
import 'package:atgevosystem/core/services/customer_service.dart';

class CustomerEditPage extends StatefulWidget {
  const CustomerEditPage({super.key, this.customerId});

  static const createRoute = '/crm/customers/add';
  static const editRoute = '/crm/customers/edit';

  final String? customerId;

  bool get isEditing => customerId != null;

  @override
  State<CustomerEditPage> createState() => _CustomerEditPageState();
}

class _CustomerEditPageState extends State<CustomerEditPage> {
  final CustomerService _service = CustomerService();

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadCustomer();
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _taxNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    try {
      final customer = await _service.fetchCustomer(widget.customerId ?? '');
      if (!mounted) return;

      if (customer == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Müşteri bulunamadı.')));
        Navigator.of(context).pop();
        return;
      }

      _companyNameController.text = customer.companyName;
      _contactPersonController.text = customer.contactPerson ?? '';
      _emailController.text = customer.email ?? '';
      _phoneController.text = customer.phone ?? '';
      _addressController.text = customer.address ?? '';
      _cityController.text = customer.city ?? '';
      _taxNumberController.text = customer.taxNumber ?? '';
      _notesController.text = customer.notes ?? '';
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Veriler alınamadı: $error')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    final input = CustomerInput(
      companyName: _companyNameController.text,
      contactPerson: _contactPersonController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      city: _cityController.text,
      taxNumber: _taxNumberController.text,
      notes: _notesController.text,
    );

    try {
      if (widget.isEditing) {
        await _service.updateCustomer(widget.customerId!, input);
      } else {
        await _service.createCustomer(input);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Müşteri kaydedildi')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme sırasında bir hata oluştu: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Müşteriyi Düzenle' : 'Yeni Müşteri'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Şirket Adı',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Şirket adı zorunludur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactPersonController,
                        decoration: const InputDecoration(
                          labelText: 'Yetkili Kişi',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return null;
                          }
                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );
                          if (!emailRegex.hasMatch(text)) {
                            return 'Geçerli bir e-posta girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Telefon'),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Adres'),
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Şehir'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _taxNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Vergi Numarası',
                        ),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notlar'),
                        textInputAction: TextInputAction.newline,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSaving ? null : _submit,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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

class CustomerEditPageArgs {
  const CustomerEditPageArgs({this.customerId});

  final String? customerId;
}
