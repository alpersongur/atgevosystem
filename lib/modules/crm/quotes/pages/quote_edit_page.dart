import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../services/quote_service.dart';

class QuoteEditPage extends StatefulWidget {
  const QuoteEditPage({
    super.key,
    this.quoteId,
  });

  static const createRoute = '/crm/quotes/add';
  static const editRoute = '/crm/quotes/edit';

  final String? quoteId;

  bool get isEditing => quoteId != null;

  @override
  State<QuoteEditPage> createState() => _QuoteEditPageState();
}

class _QuoteEditPageState extends State<QuoteEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _quoteNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _validUntilController = TextEditingController();

  String? _selectedCustomerId;
  String _selectedStatus = 'pending';
  String _selectedCurrency = 'TRY';
  DateTime? _validUntil;

  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadQuote();
    } else {
      _quoteNumberController.text = _generateQuoteNumber();
    }
  }

  @override
  void dispose() {
    _quoteNumberController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() => _isLoading = true);
    try {
      final quote =
          await QuoteService().getQuoteById(widget.quoteId ?? '');
      if (!mounted) return;

      if (quote == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teklif bulunamadı.')),
        );
        Navigator.of(context).pop();
        return;
      }

      _quoteNumberController.text = quote.quoteNumber;
      _titleController.text = quote.title;
      _amountController.text = quote.amount.toStringAsFixed(2);
      _notesController.text = quote.notes ?? '';
      _selectedCustomerId = quote.customerId;
      _selectedStatus = quote.status;
      _selectedCurrency = quote.currency;
      _validUntil = quote.validUntil;
      if (_validUntil != null) {
        _validUntilController.text =
            DateFormat('dd.MM.yyyy').format(_validUntil!);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teklif yüklenirken hata oluştu: $error')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _generateQuoteNumber() {
    final now = DateTime.now();
    final suffix = DateFormat('MMddHHmmss').format(now);
    return 'Q-${now.year}-$suffix';
  }

  Future<void> _selectValidUntil() async {
    final now = DateTime.now();
    final initialDate = _validUntil ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _validUntil = picked;
        _validUntilController.text =
            DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen müşteri seçin.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final amount = double.tryParse(
          _amountController.text.replaceAll(',', '.'),
        ) ??
        0;

    final payload = <String, dynamic>{
      'customer_id': _selectedCustomerId,
      'quote_number': _quoteNumberController.text.trim(),
      'title': _titleController.text.trim(),
      'amount': amount,
      'currency': _selectedCurrency,
      'status': _selectedStatus,
      'valid_until': _validUntil,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      if (widget.isEditing) {
        await QuoteService().updateQuote(widget.quoteId!, payload);
      } else {
        await QuoteService().addQuote(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teklif kaydedildi')),
      );
      Navigator.of(context).pop(true);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Teklifi Düzenle' : 'Yeni Teklif'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<CustomerModel>>(
              stream: CustomerService().getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Müşteri verileri alınamadı.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = snapshot.data ?? <CustomerModel>[];

                if (customers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Teklif oluşturmak için önce müşteri eklemelisiniz.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                _selectedCustomerId ??= customers.first.id;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey('customer-${_selectedCustomerId ?? ''}'),
                          initialValue: _selectedCustomerId,
                          decoration:
                              const InputDecoration(labelText: 'Müşteri'),
                          items: customers
                              .map(
                                (customer) => DropdownMenuItem(
                                  value: customer.id,
                                  child: Text(customer.companyName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCustomerId = value),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quoteNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Teklif Numarası',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Teklif numarası zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration:
                              const InputDecoration(labelText: 'Başlık'),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Başlık zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Tutar',
                            prefixIcon: Icon(Icons.numbers_outlined),
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Tutar zorunludur';
                            }
                            final parsed =
                                double.tryParse(text.replaceAll(',', '.'));
                            if (parsed == null || parsed < 0) {
                              return 'Geçerli bir tutar girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey('currency-$_selectedCurrency'),
                          initialValue: _selectedCurrency,
                          decoration:
                              const InputDecoration(labelText: 'Para Birimi'),
                          items: const [
                            DropdownMenuItem(
                              value: 'TRY',
                              child: Text('TRY'),
                            ),
                            DropdownMenuItem(
                              value: 'USD',
                              child: Text('USD'),
                            ),
                            DropdownMenuItem(
                              value: 'EUR',
                              child: Text('EUR'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCurrency = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey('status-$_selectedStatus'),
                          initialValue: _selectedStatus,
                          decoration:
                              const InputDecoration(labelText: 'Durum'),
                          items: const [
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Beklemede'),
                            ),
                            DropdownMenuItem(
                              value: 'approved',
                              child: Text('Onaylandı'),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text('Reddedildi'),
                            ),
                            DropdownMenuItem(
                              value: 'in_production',
                              child: Text('Üretimde'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _validUntilController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Geçerlilik Tarihi',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.date_range_outlined),
                              onPressed: _selectValidUntil,
                            ),
                          ),
                          onTap: _selectValidUntil,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration:
                              const InputDecoration(labelText: 'Notlar'),
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Kaydet'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class QuoteEditPageArgs {
  const QuoteEditPageArgs({this.quoteId});

  final String? quoteId;
}
