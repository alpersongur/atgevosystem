import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../tenant/services/tenant_service.dart';
import '../models/qa_run_model.dart';
import '../services/coverage_parser.dart';
import '../services/qa_service.dart';
import '../widgets/qa_kpi_card.dart';
import '../widgets/qa_trend_chart.dart';
import 'qa_run_detail_page.dart';

class QaDashboardPage extends StatefulWidget {
  const QaDashboardPage({super.key});

  static const routeName = '/qa';

  @override
  State<QaDashboardPage> createState() => _QaDashboardPageState();
}

class _QaDashboardPageState extends State<QaDashboardPage> {
  bool _isUploading = false;
  final NumberFormat _percentFormat = NumberFormat('##0.0');
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  int _daysFilter = 7;

  @override
  Widget build(BuildContext context) {
    final companyId = TenantService.instance.activeTenantId;
    return Scaffold(
      appBar: AppBar(title: const Text('Test ve QA Paneli')),
      body: companyId == null
          ? const Center(child: Text('Önce bir firma seçin.'))
          : StreamBuilder<List<QaRunModel>>(
              stream: QaService.instance.recentRuns(limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final runs = (snapshot.data ?? const <QaRunModel>[])
                    .where(
                      (run) => run.createdAt.isAfter(
                        DateTime.now().subtract(Duration(days: _daysFilter)),
                      ),
                    )
                    .toList();
                final lastRun = runs.isNotEmpty ? runs.first : null;
                final coverageWarning =
                    lastRun != null && lastRun.coveragePct < 70;
                final statusWarning = lastRun != null && lastRun.hasFailures;
                final lastRunCoverageText =
                    lastRun != null ? _percentFormat.format(lastRun.coveragePct) : null;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coverageWarning && lastRunCoverageText != null)
                        _WarningBanner(
                          message:
                              'Kapsama oranı %$lastRunCoverageText. Eşik altı (>= %70).',
                        ),
                      if (statusWarning)
                        const _WarningBanner(
                          message:
                              'Son test çalışmasında başarısız testler mevcut.',
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          DropdownButton<int>(
                            value: _daysFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 7,
                                child: Text('Son 7 gün'),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Text('Son 30 gün'),
                              ),
                              DropdownMenuItem(
                                value: 90,
                                child: Text('Son 90 gün'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _daysFilter = value ?? 7),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: QaKpiCard(
                              title: 'Son Durum',
                              value: lastRun == null
                                  ? '-'
                                  : lastRun.status == QaRunStatus.success
                                  ? 'Başarılı'
                                  : 'Başarısız',
                              subtitle: lastRun == null
                                  ? ''
                                  : _dateFormat.format(lastRun.createdAt),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              icon: Icons.verified_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QaKpiCard(
                              title: 'Kapsama',
                              value: lastRun == null
                                  ? '-'
                                  : '%${_percentFormat.format(lastRun.coveragePct)}',
                              subtitle: 'Eşik: %70',
                              color: coverageWarning
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              icon: Icons.show_chart,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QaKpiCard(
                              title: 'Başarısız Test',
                              value: lastRun?.failed.toString() ?? '-',
                              color: statusWarning
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              icon: Icons.bug_report_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                              child: QaTrendChart(runs: runs),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Card(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Son Çalışmalar',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: _isUploading
                                                    ? null
                                                    : _handleUploadLocal,
                                                icon: const Icon(
                                                  Icons.file_upload_outlined,
                                                ),
                                                label: Text(
                                                  _isUploading
                                                      ? 'Yükleniyor...'
                                                      : 'Yerel Test Yükle',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Expanded(
                                      child: runs.isEmpty
                                          ? const Center(
                                              child: Text('Kayıt bulunamadı.'),
                                            )
                                          : ListView.separated(
                                              itemCount: runs.length,
                                              separatorBuilder: (context, _) =>
                                                  const Divider(height: 1),
                                              itemBuilder: (context, index) {
                                                final run = runs[index];
                                                return ListTile(
                                                  leading: Icon(
                                                    run.status ==
                                                            QaRunStatus.success
                                                        ? Icons
                                                              .check_circle_outline
                                                        : Icons.error_outline,
                                                    color:
                                                        run.status ==
                                                            QaRunStatus.success
                                                        ? Colors.green
                                                        : Colors.redAccent,
                                                  ),
                                                  title: Text(
                                                    '${run.source.name.toUpperCase()} • %${_percentFormat.format(run.coveragePct)}',
                                                  ),
                                                  subtitle: Text(
                                                    '${_dateFormat.format(run.createdAt)} • Geçti: ${run.passed}/${run.total}',
                                                  ),
                                                  trailing: const Icon(
                                                    Icons.chevron_right,
                                                  ),
                                                  onTap: () {
                                                    Navigator.of(
                                                      context,
                                                    ).pushNamed(
                                                      QaRunDetailPage.routeName,
                                                      arguments: run.id,
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _handleUploadLocal() async {
    final companyId = TenantService.instance.activeTenantId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce aktif bir firma seçiniz.')),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'lcov.info seçin',
      );
      if (!mounted) {
        setState(() => _isUploading = false);
        return;
      }
      if (result == null || result.files.single.bytes == null) {
        return;
      }
      final bytes = result.files.single.bytes!;
      final coverage = CoverageParser.parseLcov(bytes);
      if (coverage == null) {
        throw Exception('LCOV dosyasından kapsam hesaplanamadı.');
      }
      final totals = await showDialog<_RunTotals>(
        context: context,
        builder: (context) {
          final totalController = TextEditingController(text: '0');
          final passedController = TextEditingController(text: '0');
          final failedController = TextEditingController(text: '0');
          final skippedController = TextEditingController(text: '0');
          final durationController = TextEditingController(text: '0');
          return AlertDialog(
            title: const Text('Test Sonuçları'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NumberField(label: 'Toplam', controller: totalController),
                _NumberField(label: 'Geçen', controller: passedController),
                _NumberField(label: 'Başarısız', controller: failedController),
                _NumberField(label: 'Atlanan', controller: skippedController),
                _NumberField(
                  label: 'Süre (sn)',
                  controller: durationController,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    _RunTotals(
                      total: int.tryParse(totalController.text) ?? 0,
                      passed: int.tryParse(passedController.text) ?? 0,
                      failed: int.tryParse(failedController.text) ?? 0,
                      skipped: int.tryParse(skippedController.text) ?? 0,
                      durationSec: int.tryParse(durationController.text) ?? 0,
                    ),
                  );
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      );
      if (!mounted) {
        setState(() => _isUploading = false);
        return;
      }
      if (totals == null) return;

      final run = QaRunModel(
        id: '',
        companyId: companyId,
        source: QaRunSource.local,
        status: totals.failed > 0 ? QaRunStatus.fail : QaRunStatus.success,
        total: totals.total,
        passed: totals.passed,
        failed: totals.failed,
        skipped: totals.skipped,
        coveragePct: coverage,
        durationSec: totals.durationSec,
        createdAt: DateTime.now(),
      );
      await QaService.instance.addLocalRun(companyId: companyId, run: run);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yerel test sonucu kaydedildi (%${_percentFormat.format(coverage)})',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Yükleme başarısız: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunTotals {
  const _RunTotals({
    required this.total,
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.durationSec,
  });

  final int total;
  final int passed;
  final int failed;
  final int skipped;
  final int durationSec;
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
