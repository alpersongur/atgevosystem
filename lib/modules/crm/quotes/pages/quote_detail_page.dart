import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:atgevosystem/core/services/auth_service.dart';

import 'package:atgevosystem/core/models/customer.dart';
import 'package:atgevosystem/core/services/customer_service.dart';
import 'package:atgevosystem/core/models/quote.dart';
import '../services/email_service.dart';
import '../services/quote_pdf_service.dart';
import '../services/quote_service.dart';
import '../widgets/quote_status_chip.dart';
import '../../../production/services/production_service.dart';
import '../../../finance/pages/invoice_edit_page.dart';
import 'quote_edit_page.dart';

class QuoteDetailPage extends StatelessWidget {
  const QuoteDetailPage({super.key, required this.quoteId});

  static const routeName = '/crm/quotes/detail';

  final String quoteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teklif Detayı')),
      body: StreamBuilder<QuoteModel?>(
        stream: QuoteService().watchQuote(quoteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Teklif bilgileri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final quote = snapshot.data;
          if (quote == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Teklif bulunamadı veya silinmiş olabilir.'),
              ),
            );
          }

          return _QuoteDetailContent(quote: quote);
        },
      ),
    );
  }
}

class QuoteDetailPageArgs {
  const QuoteDetailPageArgs(this.quoteId);

  final String quoteId;
}

class _QuoteDetailContent extends StatelessWidget {
  const _QuoteDetailContent({required this.quote});

  final QuoteModel quote;

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final canDelete = role == 'superadmin';
    final canCreateProduction =
        (role == 'superadmin' || role == 'sales') && quote.status == 'approved';
    final canCreateInvoice =
        role == 'superadmin' || role == 'admin' || role == 'sales';
    final amountFormat = NumberFormat.currency(
      symbol: quote.currency,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd.MM.yyyy');

    CustomerModel? currentCustomer;

    final customerSection = StreamBuilder<CustomerModel?>(
      stream: CustomerService.instance.watchCustomer(quote.customerId),
      builder: (context, customerSnapshot) {
        if (customerSnapshot.connectionState == ConnectionState.waiting) {
          return const _SectionCard(
            title: 'Müşteri',
            child: Center(child: CircularProgressIndicator()),
          );
        }

        currentCustomer = customerSnapshot.data;

        if (currentCustomer == null) {
          return const _SectionCard(
            title: 'Müşteri',
            child: Text('Müşteri bilgisi bulunamadı.'),
          );
        }

        final customer = currentCustomer!;
        return _SectionCard(
          title: 'Müşteri',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Şirket', value: customer.companyName),
              _DetailRow(
                label: 'Yetkili',
                value: customer.contactPerson ?? 'Belirtilmemiş',
              ),
              _DetailRow(
                label: 'E-posta',
                value: customer.email ?? 'Belirtilmemiş',
              ),
              _DetailRow(
                label: 'Telefon',
                value: customer.phone ?? 'Belirtilmemiş',
              ),
              _DetailRow(
                label: 'Şehir',
                value: customer.city ?? 'Belirtilmemiş',
              ),
            ],
          ),
        );
      },
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Teklif Bilgileri',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Teklif No', value: quote.quoteNumber),
                _DetailRow(label: 'Başlık', value: quote.title),
                _DetailRow(
                  label: 'Tutar',
                  value: amountFormat.format(quote.amount),
                ),
                _DetailRow(
                  label: 'Durum',
                  valueWidget: QuoteStatusChip(status: quote.status),
                ),
                _DetailRow(
                  label: 'Geçerlilik',
                  value: quote.validUntil != null
                      ? dateFormat.format(quote.validUntil!)
                      : 'Belirtilmemiş',
                ),
                if (quote.createdBy != null && quote.createdBy!.isNotEmpty)
                  _DetailRow(label: 'Oluşturan', value: quote.createdBy!),
                if ((quote.notes ?? '').isNotEmpty)
                  _DetailRow(
                    label: 'Notlar',
                    value: quote.notes!,
                    multiline: true,
                  ),
                const SizedBox(height: 12),
                Text(
                  'Oluşturulma: ${_formatDateTime(quote.createdAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  'Son Güncelleme: ${_formatDateTime(quote.updatedAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          customerSection,
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuoteEditPage(quoteId: quote.id),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Düzenle'),
              ),
              ElevatedButton.icon(
                onPressed: () => _generatePdf(context, currentCustomer),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF Oluştur ve İndir'),
              ),
              ElevatedButton.icon(
                onPressed: () => _sendEmail(context, currentCustomer),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Mail Gönder'),
              ),
              if (canCreateInvoice)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      InvoiceEditPage.createRoute,
                      arguments: InvoiceEditPageArgs(
                        quoteId: quote.id,
                        customerId: quote.customerId,
                        currency: quote.currency,
                        amount: quote.amount,
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Fatura Oluştur'),
                ),
              if (canCreateProduction)
                ElevatedButton.icon(
                  onPressed: () =>
                      _createProductionOrder(context, currentCustomer),
                  icon: const Icon(Icons.factory_outlined),
                  label: const Text('Üretim Talimatı Oluştur'),
                ),
              if (canDelete)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => _deleteQuote(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Sil'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    CustomerModel? customer,
  ) async {
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Müşteri bilgileri yüklenirken bekleyin.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      final pdfData = await QuotePdfService.instance.generateQuotePdf(
        quote,
        customer,
      );
      await Printing.layoutPdf(onLayout: (format) async => pdfData);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $error')),
      );
    }
  }

  Future<void> _sendEmail(BuildContext context, CustomerModel? customer) async {
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Müşteri bilgileri yüklenirken bekleyin.'),
        ),
      );
      return;
    }

    final email = customer.email?.trim();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müşterinin e-posta adresi bulunamadı.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      final pdfData = await QuotePdfService.instance.generateQuotePdf(
        quote,
        customer,
      );
      await EmailService.instance.sendQuoteEmail(
        recipientEmail: email,
        subject: 'Yeni Teklifiniz (${quote.quoteNumber})',
        body:
            'Sayın ${customer.contactPerson ?? customer.companyName},\nEk\'te teklifinizi bulabilirsiniz.\n\nSaygılarımızla,\nATG Makina ERP',
        pdfAttachment: pdfData,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Teklif e-postası ${customer.companyName} için gönderildi.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('E-posta gönderilemedi: $error')),
      );
    }
  }

  Future<void> _createProductionOrder(
    BuildContext context,
    CustomerModel? customer,
  ) async {
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müşteri yüklenirken bekleyin.')),
      );
      return;
    }

    try {
      await ProductionService.instance.addOrder({
        'quote_id': quote.id,
        'customer_id': customer.id,
        'status': 'waiting',
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Üretim talimatı oluşturuldu.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Talimat oluşturulamadı: $error')));
    }
  }

  Future<void> _deleteQuote(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Teklif Sil'),
            content: Text(
              '"${quote.quoteNumber}" numaralı teklifi silmek istediğinize emin misiniz?',
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
      await QuoteService().deleteQuote(quote.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teklif silindi')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme sırasında hata oluştu: $error')),
      );
    }
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) return 'Bilinmiyor';
    return DateFormat('dd.MM.yyyy HH:mm').format(value);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.multiline = false,
  }) : assert(
         value != null || valueWidget != null,
         'Either value or valueWidget must be provided',
       );

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                valueWidget ??
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
          ),
        ],
      ),
    );
  }
}
