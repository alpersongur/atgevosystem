import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/purchase_order_model.dart';
import '../models/supplier_model.dart';
import '../services/grn_service.dart';
import '../services/purchase_order_service.dart';
import '../services/supplier_service.dart';

class GRNEditPage extends StatefulWidget {
  const GRNEditPage({super.key});

  @override
  State<GRNEditPage> createState() => _GRNEditPageState();
}

class _GRNEditPageState extends State<GRNEditPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _receiptNoController = TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _receivedDateController = TextEditingController();

  final PurchaseOrderService _poService = PurchaseOrderService.instance;
  final SupplierService _supplierService = SupplierService.instance;
  final GRNService _grnService = GRNService.instance;

  PurchaseOrderModel? _selectedPO;
  SupplierModel? _selectedSupplier;
  DateTime _receivedDate = DateTime.now();
  String _status = 'received';
  bool _isSaving = false;

  final List<_EditableLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _receiptNoController.text = _generateReceiptNo();
    _receivedDateController.text = DateFormat(
      'dd.MM.yyyy',
    ).format(_receivedDate);
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.controller.dispose();
    }
    _receiptNoController.dispose();
    _warehouseController.dispose();
    _notesController.dispose();
    _receivedDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mal Kabul Kaydı')),
      body: StreamBuilder<List<PurchaseOrderModel>>(
        stream: _poService.getPOs(),
        builder: (context, poSnapshot) {
          if (poSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Satınalma emirleri yüklenemedi.\n${poSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (poSnapshot.connectionState == ConnectionState.waiting &&
              poSnapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = poSnapshot.data ?? <PurchaseOrderModel>[];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DropdownMenu<String>(
                  initialSelection: _selectedPO?.id,
                  label: const Text('Satınalma Emri (PO)'),
                  dropdownMenuEntries: orders
                      .map(
                        (order) => DropdownMenuEntry(
                          value: order.id,
                          label: '${order.poNumber} • ${order.status}',
                        ),
                      )
                      .toList(growable: false),
                  onSelected: (value) {
                    final order = orders.firstWhere(
                      (element) => element.id == value,
                      orElse: () => _selectedPO ?? orders.first,
                    );
                    _handlePOSelected(order);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _receiptNoController,
                  decoration: const InputDecoration(labelText: 'GRN Numarası'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'GRN numarası zorunludur.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _receivedDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Teslim Tarihi',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickReceivedDate,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownMenu<String>(
                  initialSelection: _status,
                  label: const Text('Durum'),
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(
                      value: 'received',
                      label: 'Teslim Alındı',
                    ),
                    DropdownMenuEntry(
                      value: 'qc_hold',
                      label: 'Kalite Kontrol',
                    ),
                    DropdownMenuEntry(value: 'rejected', label: 'Reddedildi'),
                  ],
                  onSelected: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _warehouseController,
                  decoration: const InputDecoration(
                    labelText: 'Depo / Lokasyon',
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedSupplier != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.store_outlined),
                    title: Text(_selectedSupplier!.supplierName),
                    subtitle: Text(
                      _selectedSupplier!.contactPerson.isEmpty
                          ? (_selectedSupplier!.email.isEmpty
                                ? 'Tedarikçi bilgisi'
                                : _selectedSupplier!.email)
                          : _selectedSupplier!.contactPerson,
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notlar'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  'Satır Detayları',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (_lines.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Satınalma emri seçerek satırları yükleyin.'),
                    ),
                  )
                else
                  Column(
                    children: _lines
                        .asMap()
                        .entries
                        .map((entry) => _buildLineCard(entry.key, entry.value))
                        .toList(growable: false),
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

  Widget _buildLineCard(int index, _EditableLine line) {
    final controller = line.controller;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${line.sku} • ${line.name}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Sipariş: ${line.orderedQty} ${line.unit}'),
            if (line.outstandingQty != null)
              Text('Kalan: ${line.outstandingQty} ${line.unit}'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Teslim Miktarı (${line.unit})',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final parsed = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                if (parsed == null || parsed < 0) {
                  return 'Geçerli bir miktar giriniz.';
                }
                if (line.outstandingQty != null &&
                    parsed > line.outstandingQty! + 0.0001) {
                  return 'Kalan miktardan fazla olamaz.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePOSelected(PurchaseOrderModel order) async {
    final supplier = await _supplierService.getSupplierById(order.supplierId);
    final grns = await _grnService.getGRNsByPO(order.id);

    if (!mounted) return;

    final receivedMap = <String, double>{};
    for (final grn in grns) {
      for (final line in grn.lines) {
        receivedMap[line.sku] = (receivedMap[line.sku] ?? 0) + line.receivedQty;
      }
    }

    for (final line in _lines) {
      line.controller.dispose();
    }
    _lines
      ..clear()
      ..addAll(
        order.lines.map((line) {
          final received = receivedMap[line.sku] ?? 0;
          final outstanding =
              ((line.quantity - received).clamp(0, double.infinity) as double);
          final controller = TextEditingController(
            text: outstanding.toStringAsFixed(2),
          );
          return _EditableLine(
            sku: line.sku,
            name: line.name,
            unit: line.unit,
            orderedQty: line.quantity,
            outstandingQty: outstanding,
            controller: controller,
          );
        }),
      );

    setState(() {
      _selectedPO = order;
      _selectedSupplier = supplier;
    });
  }

  Future<void> _pickReceivedDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() {
        _receivedDate = selected;
        _receivedDateController.text = DateFormat(
          'dd.MM.yyyy',
        ).format(selected);
      });
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final order = _selectedPO;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen satınalma emri seçiniz.')),
      );
      return;
    }

    final lines = _lines
        .map((line) {
          final qty =
              double.tryParse(line.controller.text.replaceAll(',', '.')) ?? 0;
          if (qty <= 0) return null;
          return {'sku': line.sku, 'received_qty': qty, 'unit': line.unit};
        })
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir satıra miktar girmelisiniz.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'po_id': order.id,
      'supplier_id': order.supplierId,
      'receipt_no': _receiptNoController.text.trim(),
      'lines': lines,
      'received_date': _receivedDate,
      'warehouse': _warehouseController.text.trim(),
      'status': _status,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      await _grnService.addGRN(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mal kabul kaydı oluşturulamadı: $error')),
      );
    }
  }

  String _generateReceiptNo() {
    final now = DateTime.now();
    final sequence = DateFormat('MMddHHmmss').format(now);
    return 'GRN-${now.year}-$sequence';
  }
}

class _EditableLine {
  _EditableLine({
    required this.sku,
    required this.name,
    required this.unit,
    required this.orderedQty,
    required this.controller,
    this.outstandingQty,
  });

  final String sku;
  final String name;
  final String unit;
  final double orderedQty;
  final double? outstandingQty;
  final TextEditingController controller;
}
