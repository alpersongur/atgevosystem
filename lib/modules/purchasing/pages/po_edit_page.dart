import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/purchase_order_model.dart';
import '../models/supplier_model.dart';
import '../services/purchase_order_service.dart';
import '../services/supplier_service.dart';

class POEditPage extends StatefulWidget {
  const POEditPage({super.key, this.order});

  final PurchaseOrderModel? order;

  bool get isEditing => order != null;

  @override
  State<POEditPage> createState() => _POEditPageState();
}

class _POEditPageState extends State<POEditPage> {
  final _formKey = GlobalKey<FormState>();
  final PurchaseOrderService _poService = PurchaseOrderService.instance;
  final SupplierService _supplierService = SupplierService.instance;

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _expectedDateController = TextEditingController();

  String? _selectedSupplierId;
  String _currency = 'TRY';
  String _status = 'open';
  DateTime? _expectedDate;
  bool _isSaving = false;

  final List<_LineData> _lines = [];

  double get _subtotal => _lines.fold(0, (sum, line) => sum + line.total);
  double get _taxRate =>
      double.tryParse(_taxRateController.text.replaceAll(',', '.')) ?? 0;
  double get _taxTotal => _subtotal * _taxRate;
  double get _grandTotal => _subtotal + _taxTotal;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    if (order != null) {
      _numberController.text = order.poNumber;
      _taxRateController.text = order.taxRate.toStringAsFixed(2);
      _notesController.text = order.notes ?? '';
      _selectedSupplierId = order.supplierId;
      _currency = order.currency;
      _status = order.status;
      _expectedDate = order.expectedDate;
      if (_expectedDate != null) {
        _expectedDateController.text = DateFormat(
          'dd.MM.yyyy',
        ).format(_expectedDate!);
      }
      _lines.addAll(order.lines.map(_LineData.fromLine));
    } else {
      _numberController.text = _generatePONumber();
      _taxRateController.text = '0.20';
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    _expectedDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryFormat = NumberFormat.currency(
      symbol: _currency,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Satınalma Emrini Düzenle' : 'Yeni Satınalma Emri',
        ),
        actions: [
          if (widget.isEditing)
            TextButton(
              onPressed: _isSaving ? null : _cancelOrder,
              child: const Text('İptal Et'),
            ),
        ],
      ),
      body: StreamBuilder<List<SupplierModel>>(
        stream: _supplierService.getSuppliers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tedarikçiler yüklenemedi.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final suppliers = snapshot.data ?? <SupplierModel>[];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(labelText: 'PO Numarası'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'PO numarası zorunludur.';
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
                    DropdownMenuEntry(value: 'open', label: 'Açık'),
                    DropdownMenuEntry(
                      value: 'partially_received',
                      label: 'Kısmi',
                    ),
                    DropdownMenuEntry(
                      value: 'received',
                      label: 'Teslim Alındı',
                    ),
                    DropdownMenuEntry(value: 'billed', label: 'Faturalandı'),
                    DropdownMenuEntry(value: 'closed', label: 'Kapandı'),
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
                  controller: _taxRateController,
                  decoration: const InputDecoration(
                    labelText: 'Vergi Oranı (örn. 0.20)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _expectedDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Beklenen Tarih',
                    hintText: 'Seçiniz',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickExpectedDate,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notlar'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Satır Sayısı: ${_lines.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    FilledButton.icon(
                      onPressed: _addLine,
                      icon: const Icon(Icons.add),
                      label: const Text('Satır Ekle'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_lines.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Henüz satır eklenmedi.'),
                    ),
                  )
                else
                  Column(
                    children: _lines
                        .asMap()
                        .entries
                        .map(
                          (entry) => Card(
                            child: ListTile(
                              title: Text(
                                '${entry.value.sku} • ${entry.value.name}',
                              ),
                              subtitle: Text(
                                '${entry.value.quantity} ${entry.value.unit} × ${entry.value.price.toStringAsFixed(2)} ${entry.value.currency}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _editLine(entry.key, entry.value),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeLine(entry.key),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
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

  Future<void> _pickExpectedDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() {
        _expectedDate = selected;
        _expectedDateController.text = DateFormat(
          'dd.MM.yyyy',
        ).format(selected);
      });
    }
  }

  Future<void> _addLine() async {
    final newLine = await showDialog<_LineData>(
      context: context,
      builder: (_) => _LineDialog(currency: _currency),
    );
    if (newLine != null) {
      setState(() => _lines.add(newLine));
    }
  }

  Future<void> _editLine(int index, _LineData line) async {
    final updated = await showDialog<_LineData>(
      context: context,
      builder: (_) => _LineDialog(currency: _currency, initial: line),
    );
    if (updated != null) {
      setState(() => _lines[index] = updated);
    }
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  Future<void> _cancelOrder() async {
    if (widget.order == null) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Satınalma Emrini İptal Et'),
            content: Text(
              '"${widget.order!.poNumber}" numaralı emri iptal etmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('İptal Et'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    await _poService.cancelPO(widget.order!.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Satınalma emri iptal edildi.')),
    );
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
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir satır eklemelisiniz.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'po_number': _numberController.text.trim(),
      'supplier_id': _selectedSupplierId,
      'lines': _lines.map((line) => line.toMap()).toList(growable: false),
      'subtotal': _subtotal,
      'tax_rate': _taxRate,
      'tax_total': _taxTotal,
      'grand_total': _grandTotal,
      'currency': _currency,
      'status': _status,
      'expected_date': _expectedDate,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      if (widget.isEditing) {
        await _poService.updatePO(widget.order!.id, payload);
      } else {
        await _poService.addPO(payload);
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

  String _generatePONumber() {
    final now = DateTime.now();
    final sequence = DateFormat('MMddHHmmss').format(now);
    return 'PO-${now.year}-$sequence';
  }
}

class _LineData {
  _LineData({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.currency,
  });

  factory _LineData.fromLine(PurchaseOrderLine line) {
    return _LineData(
      sku: line.sku,
      name: line.name,
      quantity: line.quantity,
      unit: line.unit,
      price: line.price,
      currency: line.currency,
    );
  }

  final String sku;
  final String name;
  final double quantity;
  final String unit;
  final double price;
  final String currency;

  double get total => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'name': name,
      'qty': quantity,
      'unit': unit,
      'price': price,
      'currency': currency,
    };
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isEmphasis ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineDialog extends StatefulWidget {
  const _LineDialog({required this.currency, this.initial});

  final String currency;
  final _LineData? initial;

  @override
  State<_LineDialog> createState() => _LineDialogState();
}

class _LineDialogState extends State<_LineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _skuController = TextEditingController(text: initial?.sku ?? '');
    _nameController = TextEditingController(text: initial?.name ?? '');
    _qtyController = TextEditingController(
      text: initial != null ? initial.quantity.toString() : '1',
    );
    _unitController = TextEditingController(text: initial?.unit ?? 'adet');
    _priceController = TextEditingController(
      text: initial != null ? initial.price.toStringAsFixed(2) : '0',
    );
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Satır Ekle' : 'Satır Düzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'Stok Kodu'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stok kodu zorunludur.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ürün Adı'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ürün adı zorunludur.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Miktar'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  if (parsed == null || parsed <= 0) {
                    return 'Geçerli bir miktar giriniz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Birim'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Birim Fiyat (${widget.currency})',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  if (parsed == null || parsed < 0) {
                    return 'Geçerli bir fiyat giriniz.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Kaydet')),
      ],
    );
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;

    Navigator.of(context).pop(
      _LineData(
        sku: _skuController.text.trim(),
        name: _nameController.text.trim(),
        quantity: qty,
        unit: _unitController.text.trim().isEmpty
            ? 'adet'
            : _unitController.text.trim(),
        price: price,
        currency: widget.currency,
      ),
    );
  }
}
