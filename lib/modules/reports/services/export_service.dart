import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_request_model.dart';

class ExportService {
  ExportService._();

  static final ExportService instance = ExportService._();

  Future<Uint8List> exportPdf(
    ReportData data, {
    required String title,
    Map<String, dynamic>? filters,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          if (filters != null && filters.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                'Filtreler: ${filters.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
              ),
            ),
          pw.TableHelper.fromTextArray(
            headers: data.columns.map((c) => c.label).toList(),
            data: data.rows
                .map((row) => row.map((value) => '$value').toList())
                .toList(),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> exportCsv(ReportData data) async {
    final buffer = StringBuffer();
    buffer.writeln(data.columns.map((c) => '"${c.label}"').join(','));
    for (final row in data.rows) {
      buffer.writeln(row.map((value) => '"$value"').join(','));
    }
    final bytes = utf8.encode(buffer.toString());
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> exportXlsx(ReportData data) async {
    final workbook = Excel.createExcel();
    final sheet = workbook.sheets.values.first;
    sheet.appendRow(
      data.columns.map((c) => TextCellValue(c.label)).toList(),
    );
    for (final row in data.rows) {
      sheet.appendRow(
        row.map((value) => TextCellValue(value?.toString() ?? '')).toList(),
      );
    }
    final bytes = workbook.save();
    return Uint8List.fromList(bytes!);
  }
}
