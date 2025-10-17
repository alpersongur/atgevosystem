import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bill_model.dart';
import '../models/purchase_order_model.dart';
import '../models/supplier_model.dart';
import '../services/bill_service.dart';
import '../services/purchase_order_service.dart';
import '../services/supplier_service.dart';

class BillEditPage extends StatefulWidget {
  const BillEditPage({super.key, this.bill, this.initialPO});

  final BillModel? bill;
  final PurchaseOrderModel? initialPO;

  bool get isEditing => bill != null;

  @override
  State<BillEditPage> createState() => _BillEditPageState();
}

class _BillEditPageState extends State<BillEditPage> {
  final _formKey = GlobalKey<FormState>();
  final BillService _billService = BillService.instance;
  final SupplierService _supplierService = SupplierService.instance;
  final PurchaseOrderService _poService = PurchaseOrderService.instance;

  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedSupplierId;
  PurchaseOrderModel? _selectedPO;
  String _currency = 'TRY';
  String _status = 'unpaid';
  DateTime? _issueDate;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    if (bill != null) {
      _billNoController.text = bill.billNo;
      _issueDate = bill.issueDate;
      _dueDate = bill.dueDate;
      _issueDateController.text = _formatDate(_issueDate);
      _dueDateController.text = _formatDate(_dueDate);
      _subtotalController.text = bill.subtotal.toStringAsFixed(2);
      _taxRateController.text = bill.taxRate.toStringAsFixed(2);
      _notesController.text = bill.notes ?? '';
      _selectedSupplierId = bill.supplierId;
      _currency = bill.currency;
      _status = bill.status;
    } else {
      final initialPO = widget.initialPO;
      if (initialPO != null) {
        _selectedSupplierId = initialPO.supplierId;
        _selectedPO = initialPO;
        _currency = initialPO.currency;
        _subtotalController.text = initialPO.subtotal.toStringAsFixed(2);
        _taxRateController.text = initialPO.taxRate.toStringAsFixed(2);
      }
      _billNoController.text = _generateBillNo();
    }
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _issueDateController.dispose();
    _dueDateController.dispose();
    _subtotalController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      double.tryParse(_subtotalController.text.replaceAll(',', '.')) ?? 0;
  double get _taxRate =>
      double.tryParse(_taxRateController.text.replaceAll(',', '.')) ?? 0;
  double get _taxTotal => _subtotal * _taxRate;
  double get _grandTotal => _subtotal + _taxTotal;

  @override
  Widget build(BuildContext context) {
    final summaryFormat = NumberFormat.currency(
      symbol: _currency,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Vendor Faturayı Düzenle' : 'Yeni Vendor Faturası',
        ),
      ),
      body: StreamBuilder<List<SupplierModel>>(
        stream: _supplierService.getSuppliers(),
        builder: (context, supplierSnapshot) {
          if (supplierSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tedarikçiler yüklenemedi.\n${supplierSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (supplierSnapshot.connectionState == ConnectionState.waiting &&
              supplierSnapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final suppliers = supplierSnapshot.data ?? <SupplierModel>[];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _billNoController,
                  decoration: const InputDecoration(labelText: 'Fatura No'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Fatura numarası zorunludur.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownMenu<String>(
                  initialSelection: _selectedSupplierId,
                  label: const Text('Tedarikçi'),
                  dropdownMenuEntries: suppliers
                      .map(
                        (supplier) => DropdownMenuEntry(
                          value: supplier.id,
                          label: supplier.supplierName,
                        ),
                      )
                      .toList(growable: false),
                  onSelected: (value) {
                    setState(() => _selectedSupplierId = value);
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<PurchaseOrderModel>>(
                  future: _poService.getPOs().first,
                  builder: (context, snapshot) {
                    final orders = snapshot.data ?? <PurchaseOrderModel>[];
                    final entries = orders
                        .map(
                          (order) => DropdownMenuEntry(
                            value: order.id,
                            label: order.poNumber,
                          ),
                        )
                        .toList(growable: false);
                    final initialPOId = _selectedPO?.id ?? widget.initialPO?.id;
                    return DropdownMenu<String>(
                      initialSelection: initialPOId,
                      label: const Text('Satınalma Emri (opsiyonel)'),
                      dropdownMenuEntries: entries,
                      onSelected: (value) {
                        final match = orders.firstWhere(
                          (element) => element.id == value,
                          orElse: () => _selectedPO ?? orders.first,
                        );
                        setState(() {
                          _selectedPO = match;
                          _selectedSupplierId = match.supplierId;
                          _currency = match.currency;
                          _subtotalController.text = match.subtotal
                              .toStringAsFixed(2);
                          _taxRateController.text = match.taxRate
                              .toStringAsFixed(2);
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownMenu<String>(
                  initialSelection: _currency,
                  label: const Text('Para Birimi'),
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'TRY', label: 'TRY'),
                    DropdownMenuEntry(value: 'USD', label: 'USD'),
                    DropdownMenuEntry(value: 'EUR', label: 'EUR'),
                  ],
                  onSelected: (value) {
                    if (value != null) {
                      setState(() => _currency = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownMenu<String>(
                  initialSelection: _status,
                  label: const Text('Durum'),
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'unpaid', label: 'Ödenmemiş'),
                    DropdownMenuEntry(value: 'partial', label: 'Kısmi Ödendi'),
                    DropdownMenuEntry(value: 'paid', label: 'Ödendi'),
                    DropdownMenuEntry(value: 'canceled', label: 'İptal'),
                  ],
                  onSelected: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _issueDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fatura Tarihi',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(isIssueDate: true),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Fatura tarihi seçiniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dueDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Vade Tarihi',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () => _pickDate(isIssueDate: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subtotalController,
                  decoration: InputDecoration(
                    labelText: 'Ara Toplam ($_currency)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed < 0) {
                      return 'Geçerli bir tutar giriniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxRateController,
                  decoration: const InputDecoration(
                    labelText: 'Vergi Oranı (örn. 0.20)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notlar'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryRow(
                          label: 'Ara Toplam',
                          value: summaryFormat.format(_subtotal),
                        ),
                        _SummaryRow(
                          label: 'Vergi',
                          value: summaryFormat.format(_taxTotal),
                        ),
                        const Divider(),
                        _SummaryRow(
                          label: 'Genel Toplam',
                          value: summaryFormat.format(_grandTotal),
                          isEmphasis: true,
                        ),
                      ],
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

  Future<void> _pickDate({required bool isIssueDate}) async {
    final now = DateTime.now();
    final initial = isIssueDate
        ? (_issueDate ?? now)
        : (_dueDate ?? _issueDate ?? now.add(const Duration(days: 30)));
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = selected;
          _issueDateController.text = _formatDate(_issueDate);
          if (_dueDate == null || _dueDate!.isBefore(selected)) {
            _dueDate = selected.add(const Duration(days: 30));
            _dueDateController.text = _formatDate(_dueDate);
          }
        } else {
          _dueDate = selected;
          _dueDateController.text = _formatDate(_dueDate);
        }
      });
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tedarikçi seçiniz.')),
      );
      return;
    }
    if (_issueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen fatura tarihini seçiniz.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'bill_no': _billNoController.text.trim(),
      'supplier_id': _selectedSupplierId,
      'po_id': _selectedPO?.id ?? widget.initialPO?.id,
      'issue_date': _issueDate,
      'due_date': _dueDate,
      'currency': _currency,
      'subtotal': _subtotal,
      'tax_rate': _taxRate,
      'tax_total': _taxTotal,
      'grand_total': _grandTotal,
      'status': _status,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      if (widget.isEditing) {
        await _billService.updateBill(widget.bill!.id, payload);
      } else {
        await _billService.addBill(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fatura kaydedilemedi: $error')));
    }
  }

  String _generateBillNo() {
    final now = DateTime.now();
    final sequence = DateFormat('MMddHHmmss').format(now);
    return 'BILL-${now.year}-$sequence';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy').format(date);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isEmphasis ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
