import 'package:flutter/material.dart';

import '../models/assistant_query_model.dart';
import '../services/assistant_service.dart';
import '../widgets/insight_card.dart';
import 'assistant_chat_page.dart';

class AssistantDashboardPage extends StatefulWidget {
  const AssistantDashboardPage({super.key});

  static const routeName = '/assistant/dashboard';

  @override
  State<AssistantDashboardPage> createState() => _AssistantDashboardPageState();
}

class _AssistantDashboardPageState extends State<AssistantDashboardPage> {
  late Future<List<AssistantInsight>> _insightFuture;

  @override
  void initState() {
    super.initState();
    _insightFuture = AssistantService.instance.fetchDashboardInsights();
  }

  Future<void> _refresh() async {
    setState(() {
      _insightFuture = AssistantService.instance.fetchDashboardInsights();
    });
    await _insightFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ERP Asistanı')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AssistantChatPage.routeName);
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('ERP Asistanı ile Sohbet Et'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Akıllı Öneriler',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<AssistantInsight>>(
                future: _insightFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _DashboardError(
                      message:
                          'İçgörüler yüklenirken hata oluştu. Lütfen tekrar deneyin.\n${snapshot.error}',
                      onRetry: _refresh,
                    );
                  }
                  final insights = snapshot.data ?? const <AssistantInsight>[];
                  if (insights.isEmpty) {
                    return const _DashboardEmpty();
                  }
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: insights
                        .map(
                          (insight) => SizedBox(
                            width: 320,
                            child: InsightCard(insight: insight),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Son Sorular',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _RecentQueriesList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentQueriesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AssistantLogEntry>>(
      stream: AssistantService.instance.watchRecentLogs(limit: 6),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? const <AssistantLogEntry>[];
        if (logs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Henüz kayıtlı bir asistan konuşması yok.'),
            ),
          );
        }
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: const Icon(Icons.history_toggle_off_outlined),
                title: Text(log.question),
                subtitle: Text(log.answer),
                trailing: Text(
                  _formatDate(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Henüz öneri bulunmuyor.'),
            SizedBox(height: 8),
            Text(
              'Sistem verileri arttıkça ERP asistanı öneriler üretmeye başlayacak.',
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime timestamp) {
  return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year}';
}
