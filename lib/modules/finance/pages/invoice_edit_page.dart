import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/auth_service.dart';
import '../../crm/models/customer_model.dart';
import '../../crm/services/customer_service.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';

class InvoiceEditPage extends StatefulWidget {
  const InvoiceEditPage({super.key, this.invoiceId, this.args});

  static const createRoute = '/finance/invoices/add';
  static const editRoute = '/finance/invoices/edit';

  final String? invoiceId;
  final InvoiceEditPageArgs? args;

  bool get isEditing => invoiceId != null;

  @override
  State<InvoiceEditPage> createState() => _InvoiceEditPageState();
}

class InvoiceEditPageArgs {
  const InvoiceEditPageArgs({
    this.invoiceId,
    this.quoteId,
    this.shipmentId,
    this.customerId,
    this.currency,
    this.amount,
    this.taxRate,
  });

  final String? invoiceId;
  final String? quoteId;
  final String? shipmentId;
  final String? customerId;
  final String? currency;
  final double? amount;
  final double? taxRate;
}

class _InvoiceEditPageState extends State<InvoiceEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _invoiceNoController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _taxRateController = TextEditingController(text: '0.18');
  final _notesController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  String? _selectedCustomerId;
  String _selectedCurrency = 'TRY';
  String? _quoteId;
  String? _shipmentId;
  DateTime? _issueDate;
  DateTime? _dueDate;

  double _taxTotal = 0;
  double _grandTotal = 0;

  bool _isLoading = false;
  bool _isSaving = false;

  InvoiceModel? _existingInvoice;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args != null) {
      _quoteId = args.quoteId;
      _shipmentId = args.shipmentId;
      if (args.customerId != null) {
        _selectedCustomerId = args.customerId;
      }
      if (args.currency != null && args.currency!.isNotEmpty) {
        _selectedCurrency = args.currency!;
      }
      if (args.amount != null) {
        _subtotalController.text = args.amount!.toStringAsFixed(2);
      }
      if (args.taxRate != null) {
        _taxRateController.text = args.taxRate!.toStringAsFixed(2);
      }
    }

    if (widget.isEditing || (args?.invoiceId?.isNotEmpty ?? false)) {
      final targetId = widget.invoiceId ?? args?.invoiceId ?? '';
      if (targetId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadInvoice(targetId);
        });
      }
    } else {
      _issueDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 30));
      _updateDateControllers();
      _recalculateTotals();
    }
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _subtotalController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    _issueDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoice(String invoiceId) async {
    setState(() => _isLoading = true);
    try {
      final invoice = await InvoiceService.instance.getInvoiceById(invoiceId);
      if (!mounted) return;

      if (invoice == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fatura bulunamadı.')));
        Navigator.of(context).pop();
        return;
      }

      _existingInvoice = invoice;
      _invoiceNoController.text = invoice.invoiceNo;
      _selectedCustomerId = invoice.customerId;
      _selectedCurrency = invoice.currency;
      _subtotalController.text = invoice.subtotal.toStringAsFixed(2);
      _taxRateController.text = invoice.taxRate.toStringAsFixed(2);
      _taxTotal = invoice.taxTotal;
      _grandTotal = invoice.grandTotal;
      _quoteId = invoice.quoteId;
      _shipmentId = invoice.shipmentId;
      _notesController.text = invoice.notes ?? '';
      _issueDate = invoice.issueDate ?? DateTime.now();
      _dueDate =
          invoice.dueDate ?? DateTime.now().add(const Duration(days: 30));
      _updateDateControllers();
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fatura yüklenirken hata oluştu: $error')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateDateControllers() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    _issueDateController.text = _issueDate != null
        ? dateFormat.format(_issueDate!)
        : '';
    _dueDateController.text = _dueDate != null
        ? dateFormat.format(_dueDate!)
        : '';
  }

  Future<void> _selectIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _issueDate = picked;
        if (_dueDate == null || _dueDate!.isBefore(picked)) {
          _dueDate = picked.add(const Duration(days: 30));
        }
        _updateDateControllers();
      });
    }
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _updateDateControllers();
      });
    }
  }

  void _recalculateTotals() {
    final subtotal =
        double.tryParse(_subtotalController.text.replaceAll(',', '.')) ?? 0;
    final taxRate =
        double.tryParse(_taxRateController.text.replaceAll(',', '.')) ?? 0;
    final computedTax = subtotal * taxRate;
    setState(() {
      _taxTotal = double.parse(computedTax.toStringAsFixed(2));
      _grandTotal = double.parse((subtotal + _taxTotal).toStringAsFixed(2));
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen müşteri seçiniz.')));
      return;
    }

    setState(() => _isSaving = true);

    final subtotal =
        double.tryParse(_subtotalController.text.replaceAll(',', '.')) ?? 0;
    final taxRate =
        double.tryParse(_taxRateController.text.replaceAll(',', '.')) ?? 0;

    final payload = <String, dynamic>{
      'invoice_no': _invoiceNoController.text.trim(),
      'customer_id': _selectedCustomerId,
      'currency': _selectedCurrency,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_total': _taxTotal,
      'grand_total': _grandTotal,
      'issue_date': _issueDate,
      'due_date': _dueDate,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'quote_id': _quoteId,
      'shipment_id': _shipmentId,
    };

    payload['status'] = _existingInvoice != null
        ? _existingInvoice!.status
        : 'unpaid';
    final currentUserId = AuthService.instance.currentUser?.uid;
    payload['created_by'] = _existingInvoice?.createdBy ?? currentUserId;

    try {
      if (_existingInvoice != null) {
        await InvoiceService.instance.updateInvoice(
          _existingInvoice!.id,
          payload,
        );
      } else {
        await InvoiceService.instance.addInvoice(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fatura kaydedildi.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fatura kaydedilemedi: $error')));
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
        title: Text(widget.isEditing ? 'Faturayı Düzenle' : 'Yeni Fatura'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<CustomerModel>>(
              stream: CustomerService.instance.getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Müşteri verileri yüklenemedi.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = snapshot.data ?? <CustomerModel>[];

                final items = customers
                    .map(
                      (customer) => DropdownMenuItem(
                        value: customer.id,
                        child: Text(customer.companyName),
                      ),
                    )
                    .toList(growable: false);
                final selectedValue =
                    items.any((item) => item.value == _selectedCustomerId)
                    ? _selectedCustomerId
                    : null;

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      TextFormField(
                        controller: _invoiceNoController,
                        decoration: const InputDecoration(
                          labelText: 'Fatura No',
                          hintText: 'Örn. INV-2025-0001',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Fatura numarası zorunludur.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedValue,
                        decoration: const InputDecoration(labelText: 'Müşteri'),
                        items: items,
                        onChanged: (value) =>
                            setState(() => _selectedCustomerId = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen müşteri seçiniz.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _issueDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Düzenlenme Tarihi',
                                suffixIcon: IconButton(
                                  onPressed: _selectIssueDate,
                                  icon: const Icon(Icons.calendar_month),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Lütfen tarih seçiniz.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _dueDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Vade Tarihi',
                                suffixIcon: IconButton(
                                  onPressed: _selectDueDate,
                                  icon: const Icon(Icons.calendar_today),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Lütfen vade tarihi seçiniz.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _subtotalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Ara Toplam',
                                hintText: 'Örn. 10000',
                              ),
                              onChanged: (_) => _recalculateTotals(),
                              validator: (value) {
                                final parsed =
                                    double.tryParse(
                                      (value ?? '').replaceAll(',', '.'),
                                    ) ??
                                    -1;
                                if (parsed < 0) {
                                  return 'Geçerli bir tutar giriniz.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _taxRateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'KDV Oranı',
                                hintText: 'Örn. 0.20',
                              ),
                              onChanged: (_) => _recalculateTotals(),
                              validator: (value) {
                                final parsed =
                                    double.tryParse(
                                      (value ?? '').replaceAll(',', '.'),
                                    ) ??
                                    -1;
                                if (parsed < 0) {
                                  return 'Geçerli bir oran giriniz.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCurrency,
                              decoration: const InputDecoration(
                                labelText: 'Para Birimi',
                              ),
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
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryBox(
                              label: 'KDV Tutarı',
                              value:
                                  '$_selectedCurrency ${_taxTotal.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SummaryBox(
                        label: 'Genel Toplam',
                        value:
                            '$_selectedCurrency ${_grandTotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Notlar'),
                      ),
                      if ((_quoteId ?? '').isNotEmpty ||
                          (_shipmentId ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bağlantılar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  if ((_quoteId ?? '').isNotEmpty)
                                    Text('Teklif ID: $_quoteId'),
                                  if ((_shipmentId ?? '').isNotEmpty)
                                    Text('Sevkiyat ID: $_shipmentId'),
                                ],
                              ),
                            ),
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
                );
              },
            ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
