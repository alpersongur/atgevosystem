import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/qa_run_model.dart';
import '../services/qa_service.dart';
import '../widgets/qa_failures_list.dart';

class QaRunDetailPage extends StatelessWidget {
  const QaRunDetailPage({super.key, required this.runId});

  static const routeName = '/qa/run';

  final String runId;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Test Çalışma Detayı')),
      body: FutureBuilder<QaRunModel?>(
        future: QaService.instance.fetchRun(runId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final run = snapshot.data;
          if (run == null) {
            return const Center(child: Text('Kayıt bulunamadı.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Kaynak'),
                  subtitle: Text(run.source.name.toUpperCase()),
                ),
                ListTile(
                  title: const Text('Durum'),
                  subtitle: Text(
                    run.status == QaRunStatus.success
                        ? 'Başarılı'
                        : 'Başarısız',
                  ),
                ),
                ListTile(
                  title: const Text('Tarih'),
                  subtitle: Text(formatter.format(run.createdAt)),
                ),
                ListTile(
                  title: const Text('Test Sonuçları'),
                  subtitle: Text(
                    'Toplam: ${run.total}\nGeçti: ${run.passed}\nBaşarısız: ${run.failed}\nAtlanan: ${run.skipped}',
                  ),
                ),
                ListTile(
                  title: const Text('Kapsama'),
                  subtitle: Text('%${run.coveragePct.toStringAsFixed(2)}'),
                ),
                ListTile(
                  title: const Text('Süre'),
                  subtitle: Text('${run.durationSec} sn'),
                ),
                if (run.artifacts.isNotEmpty)
                  ListTile(
                    title: const Text('Artefaktlar'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: run.artifacts.entries
                          .map((entry) => Text('${entry.key}: ${entry.value}'))
                          .toList(growable: false),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Başarısız Testler',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                QaFailuresList(failures: run.failures),
              ],
            ),
          );
        },
      ),
    );
  }
}
