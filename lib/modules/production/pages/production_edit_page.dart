import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../crm/models/customer_model.dart';
import '../../crm/quotes/models/quote_model.dart';
import '../../crm/quotes/pages/quote_edit_page.dart';
import '../../crm/quotes/services/quote_service.dart';
import '../../crm/services/customer_service.dart';
import '../../inventory/models/inventory_item_model.dart';
import '../../inventory/services/inventory_service.dart';
import '../services/production_service.dart';

class ProductionEditPage extends StatefulWidget {
  const ProductionEditPage({super.key});

  static const routeName = '/production/orders/new';

  @override
  State<ProductionEditPage> createState() => _ProductionEditPageState();
}

class _ProductionEditPageState extends State<ProductionEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _estimatedDateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _estimatedDate;
  String? _selectedStatus = 'waiting';
  String? _selectedQuoteId;
  String? _selectedCustomerId;
  String? _selectedInventoryItemId;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _startDateController.dispose();
    _estimatedDateController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _pickEstimatedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _estimatedDate = picked;
        _estimatedDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedQuoteId == null || _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen teklif ve müşteri seçin.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ProductionService.instance.addOrder({
        'quote_id': _selectedQuoteId,
        'customer_id': _selectedCustomerId,
        'inventory_item_id': _selectedInventoryItemId,
        'status': _selectedStatus ?? 'waiting',
        'start_date': _startDate,
        'estimated_completion': _estimatedDate,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Üretim talimatı oluşturuldu.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Talimat oluşturulamadı: $error')),
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
        title: const Text('Yeni Üretim Talimatı'),
      ),
      body: StreamBuilder<List<QuoteModel>>(
        stream: QuoteService().getQuotes(),
        builder: (context, quoteSnapshot) {
          if (quoteSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final quotes = (quoteSnapshot.data ?? [])
              .where((quote) => quote.status == 'approved')
              .toList();
          if (quotes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Talimat oluşturmak için onaylı bir teklif bulunmalıdır.'),
              ),
            );
          }

          _selectedQuoteId ??= quotes.first.id;

          return StreamBuilder<List<CustomerModel>>(
            stream: CustomerService.instance.getCustomers(),
            builder: (context, customerSnapshot) {
              if (customerSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final customers = customerSnapshot.data ?? [];
              if (customers.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Talimat oluşturmak için müşteri gereklidir.'),
                  ),
                );
              }

              _selectedCustomerId ??= customers.first.id;

              return StreamBuilder<List<InventoryItemModel>>(
                stream: InventoryService.instance.getInventoryStream(),
                builder: (context, inventorySnapshot) {
                  final inventoryItems = inventorySnapshot.data ?? [];
                  if (_selectedInventoryItemId == null && inventoryItems.isNotEmpty) {
                    _selectedInventoryItemId = inventoryItems.first.id;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey('quote-${_selectedQuoteId ?? ''}'),
                        initialValue: _selectedQuoteId,
                        decoration: const InputDecoration(labelText: 'Teklif'),
                        items: quotes
                            .map(
                              (quote) => DropdownMenuItem(
                                value: quote.id,
                                child: Text('${quote.quoteNumber} • ${quote.title}'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _selectedQuoteId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('inventory-${_selectedInventoryItemId ?? ''}'),
                        initialValue: _selectedInventoryItemId,
                        decoration: const InputDecoration(
                          labelText: 'Üretilen Ürün (Envanter Kaydı)',
                        ),
                        items: inventoryItems
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.productName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _selectedInventoryItemId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('customer-${_selectedCustomerId ?? ''}'),
                        initialValue: _selectedCustomerId,
                        decoration: const InputDecoration(labelText: 'Müşteri'),
                        items: customers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(customer.companyName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCustomerId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('status-${_selectedStatus ?? ''}'),
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Durum'),
                        items: const [
                          DropdownMenuItem(value: 'waiting', child: Text('Beklemede')),
                          DropdownMenuItem(value: 'in_progress', child: Text('Üretimde')),
                          DropdownMenuItem(value: 'quality_check', child: Text('Kalite Kontrol')),
                          DropdownMenuItem(value: 'completed', child: Text('Tamamlandı')),
                          DropdownMenuItem(value: 'shipped', child: Text('Sevk Edildi')),
                        ],
                        onChanged: (value) => setState(() => _selectedStatus = value),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _startDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Başlangıç Tarihi',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range_outlined),
                            onPressed: _pickStartDate,
                          ),
                        ),
                        onTap: _pickStartDate,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _estimatedDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tahmini Bitiş',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.event_outlined),
                            onPressed: _pickEstimatedDate,
                          ),
                        ),
                        onTap: _pickEstimatedDate,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notlar'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSaving ? null : _submit,
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
              );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(QuoteEditPage.createRoute);
        },
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Teklif Oluştur'),
      ),
    );
  }
}
