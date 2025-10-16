import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/customer_model.dart';
import '../models/quote_model.dart';

class QuotePdfService {
  QuotePdfService._();

  static final QuotePdfService instance = QuotePdfService._();

  Future<Uint8List> generateQuotePdf(
    QuoteModel quote,
    CustomerModel customer,
  ) async {
    final regularFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansSemiBold();
    final doc = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(quote, dateFormat, boldFont),
              pw.SizedBox(height: 20),
              _buildCustomerSection(customer, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildQuoteSummary(quote, customer, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildFooter(regularFont),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Legacy helper retained for internal service compatibility.
  Future<Uint8List> createQuotePdf({
    required String quoteId,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> products,
    required double total,
    required DateTime createdAt,
  }) async {
    final doc = pw.Document();
    final currencyFormat =
        NumberFormat.currency(symbol: 'TL', decimalDigits: 2);
    final dateFormat = DateFormat('dd.MM.yyyy');

    final customerName = customer['name'] as String? ?? 'Müşteri';
    final customerEmail = customer['email'] as String? ?? '-';
    final customerPhone = customer['phone'] as String? ?? '-';
    final customerAddress = customer['address'] as String? ?? '-';

    final tableHeaders = <String>[
      'Ürün',
      'Adet',
      'Birim Fiyat',
      'Ara Toplam',
    ];

    final tableData = products.map((product) {
      final quantity =
          (product['quantity'] as num?)?.toDouble() ?? 0;
      final price = (product['price'] as num?)?.toDouble() ?? 0;
      final lineTotal = quantity * price;

      return <String>[
        (product['name'] as String?) ?? '-',
        quantity.toStringAsFixed(2),
        currencyFormat.format(price),
        currencyFormat.format(lineTotal),
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _legacyHeader(quoteId, createdAt, dateFormat, customerName),
          pw.SizedBox(height: 24),
          _legacyCustomerInfo(
            customerName: customerName,
            email: customerEmail,
            phone: customerPhone,
            address: customerAddress,
          ),
          pw.SizedBox(height: 24),
          _legacyItemsTable(tableHeaders, tableData),
          pw.SizedBox(height: 16),
          _legacyTotal(total, currencyFormat),
          pw.SizedBox(height: 32),
          _legacySignatureSection(),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(
    QuoteModel quote,
    DateFormat dateFormat,
    pw.Font boldFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 100,
          height: 40,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'LOGO',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Teklif No: ${quote.quoteNumber}',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.Text(
              'Tarih: ${dateFormat.format(quote.createdAt ?? DateTime.now())}',
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerSection(
    CustomerModel customer,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Müşteri Bilgileri',
            style: pw.TextStyle(font: bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Şirket: ${customer.companyName}', style: pw.TextStyle(font: regular)),
          pw.Text('Yetkili: ${customer.contactPerson ?? '-'}', style: pw.TextStyle(font: regular)),
          pw.Text('E-posta: ${customer.email ?? '-'}', style: pw.TextStyle(font: regular)),
          pw.Text('Telefon: ${customer.phone ?? '-'}', style: pw.TextStyle(font: regular)),
          pw.Text('Adres: ${customer.address ?? '-'}', style: pw.TextStyle(font: regular)),
          pw.Text('Şehir: ${customer.city ?? '-'}', style: pw.TextStyle(font: regular)),
        ],
      ),
    );
  }

  pw.Widget _buildQuoteSummary(
    QuoteModel quote,
    CustomerModel customer,
    pw.Font regular,
    pw.Font bold,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: quote.currency,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd.MM.yyyy');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Teklif Özeti',
            style: pw.TextStyle(font: bold, fontSize: 14),
          ),
          pw.SizedBox(height: 12),
          _infoRow('Başlık', quote.title, regular, bold),
          _infoRow('Tutar', currencyFormat.format(quote.amount), regular, bold),
          _infoRow('Durum', quote.status, regular, bold),
          _infoRow(
            'Geçerlilik',
            quote.validUntil != null
                ? dateFormat.format(quote.validUntil!)
                : 'Belirtilmemiş',
            regular,
            bold,
          ),
          if ((quote.notes ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Notlar',
              style: pw.TextStyle(font: bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              quote.notes!,
              style: pw.TextStyle(font: regular, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Font regular) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Generated by ATG System CRM',
        style: pw.TextStyle(
          font: regular,
          fontSize: 10,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  pw.Widget _infoRow(
    String label,
    String value,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: regular, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Legacy helper widgets
  pw.Widget _legacyHeader(
    String quoteId,
    DateTime createdAt,
    DateFormat dateFormat,
    String customerName,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ATG ERP Sistemleri',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Teklif Dokümanı',
          style: pw.TextStyle(fontSize: 16),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Teklif No: $quoteId'),
        pw.Text('Oluşturma Tarihi: ${dateFormat.format(createdAt)}'),
        pw.Text('Müşteri: $customerName'),
      ],
    );
  }

  pw.Widget _legacyCustomerInfo({
    required String customerName,
    required String email,
    required String phone,
    required String address,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Müşteri Bilgileri',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Ad Soyad: $customerName'),
          pw.Text('E-posta: $email'),
          pw.Text('Telefon: $phone'),
          pw.Text('Adres: $address'),
        ],
      ),
    );
  }

  pw.Widget _legacyItemsTable(
    List<String> headers,
    List<List<String>> data,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
      ),
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.5,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 4,
      ),
    );
  }

  pw.Widget _legacyTotal(double total, NumberFormat currencyFormat) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Text(
          'Genel Toplam: ${currencyFormat.format(total)}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _legacySignatureSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Yetkili İmza'),
        pw.SizedBox(height: 40),
        pw.SizedBox(
          width: 150,
          child: pw.Divider(
            color: PdfColors.grey400,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
