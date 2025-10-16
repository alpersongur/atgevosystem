import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class QuotePdfService {
  QuotePdfService._();

  static final QuotePdfService instance = QuotePdfService._();

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

    final customerName = customer['name'] as String? ?? 'Musteri';
    final customerEmail = customer['email'] as String? ?? '-';
    final customerPhone = customer['phone'] as String? ?? '-';
    final customerAddress = customer['address'] as String? ?? '-';

    final tableHeaders = <String>[
      'Urun',
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
          _buildHeader(quoteId, createdAt, dateFormat, customerName),
          pw.SizedBox(height: 24),
          _buildCustomerInfo(
            customerName: customerName,
            email: customerEmail,
            phone: customerPhone,
            address: customerAddress,
          ),
          pw.SizedBox(height: 24),
          _buildItemsTable(tableHeaders, tableData),
          pw.SizedBox(height: 16),
          _buildTotal(total, currencyFormat),
          pw.SizedBox(height: 32),
          _buildSignatureSection(),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(
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
          'Teklif Dokumani',
          style: pw.TextStyle(fontSize: 16),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Teklif No: $quoteId'),
        pw.Text('Olusturma Tarihi: ${dateFormat.format(createdAt)}'),
        pw.Text('Musteri: $customerName'),
      ],
    );
  }

  pw.Widget _buildCustomerInfo({
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
            'Musteri Bilgileri',
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

  pw.Widget _buildItemsTable(
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

  pw.Widget _buildTotal(double total, NumberFormat currencyFormat) {
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

  pw.Widget _buildSignatureSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Yetkili Imza'),
        pw.SizedBox(height: 40),
        pw.Container(
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
