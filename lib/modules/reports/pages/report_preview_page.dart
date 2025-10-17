import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../tenant/services/tenant_service.dart';
import '../models/report_request_model.dart';
import '../services/export_service.dart';
import '../widgets/report_result_table.dart';
import '../services/schedule_service.dart';

class ReportPreviewPage extends StatefulWidget {
  const ReportPreviewPage({
    super.key,
    required this.request,
    required this.data,
  });

  static const routeName = '/reports/preview';

  final ReportRequest request;
  final ReportData data;

  @override
  State<ReportPreviewPage> createState() => _ReportPreviewPageState();
}

class _ReportPreviewPageState extends State<ReportPreviewPage> {
  bool _sending = false;

  Future<void> _download(String format) async {
    late Uint8List bytes;
    switch (format) {
      case 'pdf':
        bytes = await ExportService.instance.exportPdf(
          widget.data,
          title: widget.request.type.name,
          filters: widget.request.filters,
        );
        break;
      case 'csv':
        bytes = await ExportService.instance.exportCsv(widget.data);
        break;
      case 'xlsx':
        bytes = await ExportService.instance.exportXlsx(widget.data);
        break;
      default:
        return;
    }
    final xFile = XFile.fromData(
      bytes,
      mimeType: _mimeType(format),
      name: 'report.${format.toLowerCase()}',
    );
    await Share.shareXFiles([xFile]);
  }

  Future<void> _sendEmail() async {
    final companyId = widget.request.companyId;
    final emailsController = TextEditingController();
    final emails = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-posta ile gönder'),
        content: TextField(
          controller: emailsController,
          decoration: const InputDecoration(
            labelText: 'E-posta adresleri (virgülle)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              emailsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (emails == null || emails.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ScheduleService.instance.requestImmediateReport(
        companyId: companyId,
        reportType: widget.request.type,
        format: 'pdf',
        emails: emails,
        filters: widget.request.filters,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-posta gönderme isteği alındı.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('E-posta gönderilemedi: $error')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _mimeType(String format) {
    switch (format) {
      case 'pdf':
        return 'application/pdf';
      case 'csv':
        return 'text/csv';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantName =
        TenantService.instance.activeTenant?.companyName ??
        widget.request.companyId;
    return Scaffold(
      appBar: AppBar(title: Text('Rapor Önizleme - $tenantName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.request.type.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(child: ReportResultTable(data: widget.data)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => _download('pdf'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF İndir'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _download('csv'),
                  icon: const Icon(Icons.table_rows_outlined),
                  label: const Text('CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _download('xlsx'),
                  icon: const Icon(Icons.grid_on_outlined),
                  label: const Text('Excel'),
                ),
                OutlinedButton.icon(
                  onPressed: _sending ? null : _sendEmail,
                  icon: const Icon(Icons.send_outlined),
                  label: _sending
                      ? const Text('Gönderiliyor...')
                      : const Text('E-posta Gönder'),
                ),
                OutlinedButton.icon(
                  onPressed: _sending ? null : _scheduleReport,
                  icon: const Icon(Icons.schedule_outlined),
                  label: const Text('Zamanla'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleReport() async {
    final companyId = widget.request.companyId;
    final format = await showDialog<String>(
      context: context,
      builder: (context) {
        String selectedFormat = 'pdf';
        String frequency = 'DAILY';
        int dayOfWeek = 1;
        final timeController = TextEditingController(text: '06:00');
        final emailsController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Raporu Zamanla'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedFormat,
                    decoration: const InputDecoration(labelText: 'Format'),
                    items: const [
                      DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      DropdownMenuItem(value: 'csv', child: Text('CSV')),
                      DropdownMenuItem(value: 'xlsx', child: Text('Excel')),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedFormat = value ?? 'pdf'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: frequency,
                    decoration: const InputDecoration(labelText: 'Frekans'),
                    items: const [
                      DropdownMenuItem(value: 'DAILY', child: Text('Günlük')),
                      DropdownMenuItem(
                        value: 'WEEKLY',
                        child: Text('Haftalık'),
                      ),
                      DropdownMenuItem(value: 'MONTHLY', child: Text('Aylık')),
                    ],
                    onChanged: (value) =>
                        setState(() => frequency = value ?? 'DAILY'),
                  ),
                  if (frequency == 'WEEKLY')
                    DropdownButtonFormField<int>(
                      initialValue: dayOfWeek,
                      decoration: const InputDecoration(
                        labelText: 'Haftanın günü',
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Pazartesi')),
                        DropdownMenuItem(value: 2, child: Text('Salı')),
                        DropdownMenuItem(value: 3, child: Text('Çarşamba')),
                        DropdownMenuItem(value: 4, child: Text('Perşembe')),
                        DropdownMenuItem(value: 5, child: Text('Cuma')),
                        DropdownMenuItem(value: 6, child: Text('Cumartesi')),
                        DropdownMenuItem(value: 7, child: Text('Pazar')),
                      ],
                      onChanged: (value) =>
                          setState(() => dayOfWeek = value ?? 1),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Saat (HH:MM)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailsController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta adresleri (virgülle)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    '$selectedFormat|$frequency|$dayOfWeek|${timeController.text}|${emailsController.text}',
                  );
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );

    if (format == null) return;
    final parts = format.split('|');
    final selectedFormat = parts[0];
    final frequency = parts[1];
    final dayOfWeek = int.tryParse(parts[2]) ?? 1;
    final time = parts.length > 3 ? parts[3] : '06:00';
    final emails = parts.length > 4
        ? parts[4]
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    try {
      await ScheduleService.instance.createSchedule(
        companyId: companyId,
        reportType: widget.request.type,
        format: selectedFormat,
        frequency: frequency,
        dayOfWeek: frequency == 'WEEKLY' ? dayOfWeek : null,
        time: time,
        emails: emails,
        filters: widget.request.filters,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zamanlanmış rapor kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Zamanlama başarısız: $error')));
    }
  }
}
