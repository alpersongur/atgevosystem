import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../services/auth_service.dart';
import '../../crm/models/customer_model.dart';
import '../../crm/services/customer_service.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../services/invoice_service.dart';
import '../services/payment_service.dart';
import '../widgets/payment_card.dart';
import 'invoice_edit_page.dart';
import 'payment_detail_page.dart';
import 'payment_edit_page.dart';

class InvoiceDetailPage extends StatelessWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  static const routeName = '/finance/invoices/detail';

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvoiceEditPage(invoiceId: invoiceId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<InvoiceModel?>(
        stream: InvoiceService.instance.watchInvoice(invoiceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Fatura bilgileri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final invoice = snapshot.data;
          if (invoice == null) {
            return const Center(
              child: Text('Fatura bulunamadı veya silinmiş olabilir.'),
            );
          }

          return _InvoiceDetailView(invoice: invoice);
        },
      ),
    );
  }
}

class InvoiceDetailPageArgs {
  const InvoiceDetailPageArgs(this.invoiceId);

  final String invoiceId;
}

class _InvoiceDetailView extends StatefulWidget {
  const _InvoiceDetailView({required this.invoice});

  final InvoiceModel invoice;

  @override
  State<_InvoiceDetailView> createState() => _InvoiceDetailViewState();
}

class _InvoiceDetailViewState extends State<_InvoiceDetailView> {
  bool _isUploading = false;

  InvoiceModel get invoice => widget.invoice;

  Future<void> _uploadAttachment(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.single;
    final bytes = pickedFile.bytes;

    if (bytes == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seçilen dosya okunamadı.')));
      return;
    }

    setState(() => _isUploading = true);
    final storageRef = FirebaseStorage.instance.ref().child(
      'invoice_attachments/${invoice.id}.pdf',
    );

    try {
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final downloadUrl = await storageRef.getDownloadURL();
      await InvoiceService.instance.attachPdf(invoice.id, downloadUrl);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF eki yüklendi.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF yüklenemedi: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _openAttachment(String url) async {
    final launched = await launchUrlString(url);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: invoice.currency,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd.MM.yyyy');
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final isSuperAdmin = role == 'superadmin';

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.invoiceNo,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(label: Text(invoice.status.toUpperCase())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Düzenlenme Tarihi',
                    value: invoice.issueDate != null
                        ? dateFormat.format(invoice.issueDate!)
                        : '—',
                  ),
                  _DetailRow(
                    label: 'Vade Tarihi',
                    value: invoice.dueDate != null
                        ? dateFormat.format(invoice.dueDate!)
                        : '—',
                  ),
                  _DetailRow(
                    label: 'Ara Toplam',
                    value: currencyFormat.format(invoice.subtotal),
                  ),
                  _DetailRow(
                    label: 'KDV Oranı',
                    value: (invoice.taxRate * 100).toStringAsFixed(2),
                    suffix: '%',
                  ),
                  _DetailRow(
                    label: 'KDV Tutarı',
                    value: currencyFormat.format(invoice.taxTotal),
                  ),
                  _DetailRow(
                    label: 'Genel Toplam',
                    value: currencyFormat.format(invoice.grandTotal),
                  ),
                  if ((invoice.notes ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(invoice.notes!),
                    ),
                  if ((invoice.quoteId ?? '').isNotEmpty ||
                      (invoice.shipmentId ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if ((invoice.quoteId ?? '').isNotEmpty)
                            Chip(label: Text('Teklif: ${invoice.quoteId}')),
                          if ((invoice.shipmentId ?? '').isNotEmpty)
                            Chip(
                              label: Text('Sevkiyat: ${invoice.shipmentId}'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _uploadAttachment(context),
                icon: _isUploading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_isUploading ? 'Yükleniyor...' : 'PDF Eki Yükle'),
              ),
              if ((invoice.attachmentUrl ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openAttachment(invoice.attachmentUrl!),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF Ekini Aç'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<CustomerModel?>(
            stream: CustomerService.instance.watchCustomer(invoice.customerId),
            builder: (context, customerSnapshot) {
              final customer = customerSnapshot.data;
              if (customerSnapshot.connectionState == ConnectionState.waiting &&
                  customer == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
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
                      _DetailRow(
                        label: 'Şirket',
                        value: customer?.companyName ?? invoice.customerId,
                      ),
                      _DetailRow(
                        label: 'Yetkili',
                        value: customer?.contactPerson ?? '—',
                      ),
                      _DetailRow(
                        label: 'Telefon',
                        value: customer?.phone ?? '—',
                      ),
                      _DetailRow(
                        label: 'E-posta',
                        value: customer?.email ?? '—',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<PaymentModel>>(
            stream: PaymentService.instance.getPaymentsByInvoice(invoice.id),
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Tahsilatlar yüklenirken hata oluştu.\n${paymentSnapshot.error}',
                    ),
                  ),
                );
              }

              if (paymentSnapshot.connectionState == ConnectionState.waiting &&
                  paymentSnapshot.data == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final payments = paymentSnapshot.data ?? <PaymentModel>[];
              final totalPaid = payments.fold<double>(
                0,
                (sum, payment) => sum + payment.amount,
              );
              final remaining = invoice.grandTotal - totalPaid;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tahsilat Özeti',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Toplam Ödenen',
                            value: currencyFormat.format(totalPaid),
                          ),
                          _DetailRow(
                            label: 'Kalan Bakiye',
                            value: currencyFormat.format(remaining),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PaymentEditPage(
                                  args: PaymentEditPageArgs(
                                    invoiceId: invoice.id,
                                    customerId: invoice.customerId,
                                    currency: invoice.currency,
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Yeni Tahsilat'),
                        ),
                        if (isSuperAdmin)
                          FilledButton.icon(
                            onPressed: () => _showStatusDialog(context),
                            icon: const Icon(Icons.sync_alt),
                            label: const Text('Durumu Güncelle'),
                          ),
                        if (isSuperAdmin)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () => _confirmDelete(context),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Sil'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (payments.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Henüz tahsilat yapılmamış.'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payments.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return PaymentCard(
                          payment: payment,
                          customerName: invoice.customerId,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PaymentDetailPage(paymentId: payment.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusDialog(BuildContext context) async {
    final statuses = {
      'unpaid': 'Ödenmemiş',
      'partial': 'Kısmi',
      'paid': 'Ödendi',
      'canceled': 'İptal',
    };

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Durum Seçin'),
        children: statuses.entries
            .map(
              (entry) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(entry.key),
                child: Text(entry.value),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || selected == invoice.status) return;

    try {
      await InvoiceService.instance.markStatus(invoice.id, selected);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fatura durumu güncellendi.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Durum güncellenemedi: $error')));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Faturayı Sil'),
            content: Text(
              '"${invoice.invoiceNo}" numaralı faturayı silmek istediğinize emin misiniz?',
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
      await InvoiceService.instance.deleteInvoice(invoice.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fatura silindi.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fatura silinemedi: $error')));
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.suffix});

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            suffix != null ? '$value$suffix' : value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
