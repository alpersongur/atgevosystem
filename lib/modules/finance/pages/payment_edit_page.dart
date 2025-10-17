import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:atgevosystem/core/services/auth_service.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentEditPage extends StatefulWidget {
  const PaymentEditPage({super.key, this.paymentId, this.args});

  static const createRoute = '/finance/payments/add';

  final String? paymentId;
  final PaymentEditPageArgs? args;

  bool get isEditing => paymentId != null;

  @override
  State<PaymentEditPage> createState() => _PaymentEditPageState();
}

class PaymentEditPageArgs {
  const PaymentEditPageArgs({
    this.paymentId,
    this.invoiceId,
    this.customerId,
    this.currency,
    this.amount,
    this.method,
    this.paymentDate,
  });

  final String? paymentId;
  final String? invoiceId;
  final String? customerId;
  final String? currency;
  final double? amount;
  final String? method;
  final DateTime? paymentDate;
}

class _PaymentEditPageState extends State<PaymentEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _invoiceIdController = TextEditingController();
  final _customerIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _txnRefController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentDateController = TextEditingController();

  String _currency = 'TRY';
  String _method = 'transfer';
  DateTime? _paymentDate;

  bool _isSaving = false;
  bool _isLoading = false;

  PaymentModel? _existingPayment;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args != null) {
      if ((args.invoiceId ?? '').isNotEmpty) {
        _invoiceIdController.text = args.invoiceId!;
      }
      if ((args.customerId ?? '').isNotEmpty) {
        _customerIdController.text = args.customerId!;
      }
      if ((args.currency ?? '').isNotEmpty) {
        _currency = args.currency!;
      }
      if ((args.method ?? '').isNotEmpty) {
        _method = args.method!;
      }
      if (args.amount != null) {
        _amountController.text = args.amount!.toStringAsFixed(2);
      }
      _paymentDate = args.paymentDate ?? DateTime.now();
    } else {
      _paymentDate = DateTime.now();
    }
    _updateDateController();

    final targetPaymentId = widget.paymentId ?? widget.args?.paymentId;
    if ((targetPaymentId ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPayment(targetPaymentId!);
      });
    }
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _customerIdController.dispose();
    _amountController.dispose();
    _txnRefController.dispose();
    _notesController.dispose();
    _paymentDateController.dispose();
    super.dispose();
  }

  Future<void> _loadPayment(String paymentId) async {
    setState(() => _isLoading = true);
    try {
      final payment = await PaymentService.instance.getPaymentById(paymentId);
      if (!mounted) return;

      if (payment == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tahsilat bulunamadı.')));
        Navigator.of(context).pop();
        return;
      }

      _existingPayment = payment;
      _invoiceIdController.text = payment.invoiceId;
      _customerIdController.text = payment.customerId;
      _amountController.text = payment.amount.toStringAsFixed(2);
      _currency = payment.currency;
      _method = payment.method;
      _txnRefController.text = payment.txnRef ?? '';
      _notesController.text = payment.notes ?? '';
      _paymentDate = payment.paymentDate ?? DateTime.now();
      _updateDateController();
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tahsilat yüklenirken hata oluştu: $error')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateDateController() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    _paymentDateController.text = _paymentDate != null
        ? dateFormat.format(_paymentDate!)
        : '';
  }

  Future<void> _selectPaymentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
        _updateDateController();
      });
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    if ((_invoiceIdController.text).trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen fatura numarası belirtiniz.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

    final currentUserId = AuthService.instance.currentUser?.uid;
    final payload = <String, dynamic>{
      'invoice_id': _invoiceIdController.text.trim(),
      'customer_id': _customerIdController.text.trim(),
      'amount': amount,
      'currency': _currency,
      'method': _method,
      'payment_date': _paymentDate,
      'txn_ref': _txnRefController.text.trim().isEmpty
          ? null
          : _txnRefController.text.trim(),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'created_by': _existingPayment?.createdBy ?? currentUserId,
    };

    try {
      if (_existingPayment != null) {
        await PaymentService.instance.updatePayment(
          _existingPayment!.id,
          payload,
        );
      } else {
        await PaymentService.instance.addPayment(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tahsilat kaydedildi.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tahsilat kaydedilemedi: $error')));
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
        title: Text(widget.isEditing ? 'Tahsilatı Düzenle' : 'Yeni Tahsilat'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _invoiceIdController,
                    decoration: const InputDecoration(
                      labelText: 'Fatura No / ID',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Fatura numarası zorunludur.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerIdController,
                    decoration: const InputDecoration(
                      labelText: 'Müşteri ID',
                      hintText: 'Opsiyonel',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Tutar'),
                    validator: (value) {
                      final parsed =
                          double.tryParse((value ?? '').replaceAll(',', '.')) ??
                          -1;
                      if (parsed <= 0) {
                        return 'Geçerli bir tutar giriniz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration: const InputDecoration(
                            labelText: 'Para Birimi',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _currency = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _method,
                          decoration: const InputDecoration(
                            labelText: 'Tahsilat Yöntemi',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'transfer',
                              child: Text('Havale / EFT'),
                            ),
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text('Nakit'),
                            ),
                            DropdownMenuItem(
                              value: 'card',
                              child: Text('Kredi Kartı'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _method = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _paymentDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Tahsilat Tarihi',
                      suffixIcon: IconButton(
                        onPressed: _selectPaymentDate,
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Lütfen tarih seçiniz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _txnRefController,
                    decoration: const InputDecoration(
                      labelText: 'İşlem Referansı',
                      hintText: 'Opsiyonel',
                    ),
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
}
