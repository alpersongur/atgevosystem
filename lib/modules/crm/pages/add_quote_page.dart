import 'package:flutter/material.dart';

import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../quotes/services/quote_service.dart';

class AddQuotePage extends StatefulWidget {
  const AddQuotePage({super.key});

  static const routeName = '/add_quote';

  @override
  State<AddQuotePage> createState() => _AddQuotePageState();
}

class _AddQuotePageState extends State<AddQuotePage> {
  final _formKey = GlobalKey<FormState>();
  final List<_ProductEntry> _products = [];
  String? _selectedCustomerId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addProductEntry();
  }

  @override
  void dispose() {
    for (final product in _products) {
      product.dispose();
    }
    super.dispose();
  }

  void _addProductEntry() {
    setState(() {
      _products.add(_ProductEntry(onChanged: _onProductChanged));
    });
  }

  void _removeProductEntry(int index) {
    if (_products.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir ürün eklenmelidir')),
      );
      return;
    }
    setState(() {
      final removed = _products.removeAt(index);
      removed.dispose();
    });
  }

  void _onProductChanged() {
    setState(() {});
  }

  double get _total {
    double sum = 0;
    for (final product in _products) {
      final qty = double.tryParse(product.qtyController.text.replaceAll(',', '.')) ?? 0;
      final price = double.tryParse(product.priceController.text.replaceAll(',', '.')) ?? 0;
      sum += qty * price;
    }
    return sum;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      return;
    }
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir müşteri seçin')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final products = _products
        .map((p) => {
              'name': p.nameController.text.trim(),
              'quantity': double.tryParse(p.qtyController.text.replaceAll(',', '.')) ?? 0,
              'price': double.tryParse(p.priceController.text.replaceAll(',', '.')) ?? 0,
            })
        .toList();

    try {
      await QuoteService().addQuote({
        'customer_id': _selectedCustomerId,
        'products': products,
        'total': _total,
        'status': 'pending',
      });

      if (!mounted) return;

      form.reset();
      for (final product in _products) {
        product.clear();
      }
      setState(() {
        _selectedCustomerId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teklif kaydedildi')),
      );
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
        title: const Text('Yeni Teklif'),
      ),
      body: StreamBuilder<List<CustomerModel>>(
        stream: CustomerService.instance.watchCustomers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Müşteriler yüklenirken hata oluştu.\n${snapshot.error}',
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
              child: Text('Teklif eklemek için önce müşteri oluşturun.'),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      decoration: const InputDecoration(labelText: 'Müşteri'),
                      items: customers
                          .map(
                            (customer) => DropdownMenuItem(
                              value: customer.id,
                              child: Text(
                                customer.companyName.isEmpty
                                    ? 'İsimsiz'
                                    : customer.companyName,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Lütfen müşteri seçin' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ürünler',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      _products.length,
                      (index) => _ProductRow(
                        entry: _products[index],
                        onRemove: () => _removeProductEntry(index),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addProductEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Ürün Ekle'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Toplam: ${_total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
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
            ),
          );
        },
      ),
    );
  }
}

class _ProductEntry {
  _ProductEntry({required VoidCallback onChanged})
      : nameController = TextEditingController(),
        qtyController = TextEditingController(),
        priceController = TextEditingController() {
    nameController.addListener(onChanged);
    qtyController.addListener(onChanged);
    priceController.addListener(onChanged);
  }

  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  void clear() {
    nameController.clear();
    qtyController.clear();
    priceController.clear();
  }

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.entry,
    required this.onRemove,
  });

  final _ProductEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: entry.nameController,
              decoration: const InputDecoration(labelText: 'Ürün Adı'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ürün adı zorunludur';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.qtyController,
                    decoration: const InputDecoration(labelText: 'Adet'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final number =
                          double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (number == null || number <= 0) {
                        return 'Geçerli bir adet girin';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: entry.priceController,
                    decoration: const InputDecoration(labelText: 'Birim Fiyat'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final number =
                          double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (number == null || number <= 0) {
                        return 'Geçerli bir fiyat girin';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
                tooltip: 'Ürünü kaldır',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
