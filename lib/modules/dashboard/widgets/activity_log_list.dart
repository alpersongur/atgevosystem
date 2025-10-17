import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:atgevosystem/modules/dashboard/services/system_dashboard_service.dart';

class ActivityLogList extends StatelessWidget {
  const ActivityLogList({
    super.key,
    this.limit = 10,
    this.emptyMessage = 'Henüz log kaydı bulunmuyor.',
    this.onErrorRetry,
  });

  final int limit;
  final String emptyMessage;
  final VoidCallback? onErrorRetry;

  @override
  Widget build(BuildContext context) {
    final service = SystemDashboardService.instance;
    final stream = service.watchRecentSystemLogs(limit: limit);
    final dateFormatter = DateFormat('dd MMM HH:mm', 'tr_TR');

    return StreamBuilder<List<SystemLogEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _ErrorContent(error: snapshot.error, onRetry: onErrorRetry);
        }

        final logs = snapshot.data ?? const <SystemLogEntry>[];
        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(emptyMessage),
          );
        }

        return ListView.separated(
          itemCount: logs.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = logs[index];
            final subtitleParts = <String>[];
            if (log.module != null && log.module!.isNotEmpty) {
              subtitleParts.add(log.module!);
            }
            if (log.actorName != null && log.actorName!.isNotEmpty) {
              subtitleParts.add(log.actorName!);
            }
            if (log.timestamp != null) {
              subtitleParts.add(dateFormatter.format(log.timestamp!));
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                foregroundColor: Colors.indigo,
                child: const Icon(Icons.event_note_outlined),
              ),
              title: Text(
                log.message.isNotEmpty ? log.message : 'Sistem kaydı',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: subtitleParts.isEmpty
                  ? null
                  : Text(
                      subtitleParts.join(' • '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
            );
          },
        );
      },
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Log verileri yüklenemedi: $error',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ],
      ),
    );
  }
}
