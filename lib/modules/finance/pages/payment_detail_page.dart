import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/auth_service.dart';
import '../../crm/models/customer_model.dart';
import '../../crm/services/customer_service.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../services/invoice_service.dart';
import '../services/payment_service.dart';
import 'invoice_detail_page.dart';
import 'payment_edit_page.dart';

class PaymentDetailPage extends StatelessWidget {
  const PaymentDetailPage({super.key, required this.paymentId});

  static const routeName = '/finance/payments/detail';

  final String paymentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahsilat Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaymentEditPage(paymentId: paymentId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<PaymentModel?>(
        stream: PaymentService.instance.watchPayment(paymentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tahsilat bilgileri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final payment = snapshot.data;
          if (payment == null) {
            return const Center(
              child: Text('Tahsilat bulunamadı veya silinmiş olabilir.'),
            );
          }

          return _PaymentDetailView(payment: payment);
        },
      ),
    );
  }
}

class PaymentDetailPageArgs {
  const PaymentDetailPageArgs(this.paymentId);

  final String paymentId;
}

class _PaymentDetailView extends StatelessWidget {
  const _PaymentDetailView({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final isSuperAdmin = role == 'superadmin';
    final currencyFormat = NumberFormat.currency(
      symbol: payment.currency,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd.MM.yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyFormat.format(payment.amount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(label: Text(payment.method.toUpperCase())),
                      const SizedBox(width: 12),
                      Text('Para Birimi: ${payment.currency}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Fatura',
                    value: payment.invoiceId,
                    action: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                InvoiceDetailPage(invoiceId: payment.invoiceId),
                          ),
                        );
                      },
                      child: const Text('Faturayı Aç'),
                    ),
                  ),
                  _DetailRow(
                    label: 'Tahsilat Tarihi',
                    value: payment.paymentDate != null
                        ? dateFormat.format(payment.paymentDate!)
                        : '—',
                  ),
                  _DetailRow(
                    label: 'Referans',
                    value: (payment.txnRef ?? '').isEmpty
                        ? 'Belirtilmemiş'
                        : payment.txnRef!,
                  ),
                  if ((payment.notes ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(payment.notes!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<CustomerModel?>(
            stream: CustomerService.instance.watchCustomer(payment.customerId),
            builder: (context, customerSnapshot) {
              if (customerSnapshot.connectionState == ConnectionState.waiting &&
                  customerSnapshot.data == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final customer = customerSnapshot.data;
              if (customer == null) {
                return const SizedBox.shrink();
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Müşteri',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(customer.companyName),
                      if ((customer.contactPerson ?? '').isNotEmpty)
                        Text('Yetkili: ${customer.contactPerson}'),
                      if ((customer.phone ?? '').isNotEmpty)
                        Text('Telefon: ${customer.phone}'),
                      if ((customer.email ?? '').isNotEmpty)
                        Text('E-posta: ${customer.email}'),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<InvoiceModel?>(
            future: InvoiceService.instance.getInvoiceById(payment.invoiceId),
            builder: (context, invoiceSnapshot) {
              final invoice = invoiceSnapshot.data;
              if (invoice == null) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  title: Text('Fatura: ${invoice.invoiceNo}'),
                  subtitle: Text(
                    'Durum: ${invoice.status.toUpperCase()} • Toplam: ${invoice.currency} ${invoice.grandTotal.toStringAsFixed(2)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            InvoiceDetailPage(invoiceId: invoice.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaymentEditPage(paymentId: payment.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Düzenle'),
                ),
              ),
              const SizedBox(width: 12),
              if (isSuperAdmin)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Sil'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tahsilatı Sil'),
            content: const Text(
              'Bu tahsilatı silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await PaymentService.instance.deletePayment(payment.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tahsilat silindi.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tahsilat silinemedi: $error')));
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.action});

  final String label;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
