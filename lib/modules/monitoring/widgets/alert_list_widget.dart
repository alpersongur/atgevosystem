import 'package:flutter/material.dart';

class AlertItem {
  const AlertItem({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final AlertSeverity severity;
}

enum AlertSeverity { info, warning, critical }

class AlertListWidget extends StatelessWidget {
  const AlertListWidget({
    super.key,
    required this.alerts,
  });

  final List<AlertItem> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Aktif uyarı bulunmuyor.'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final color = _colorForSeverity(alert.severity, context);
        final icon = _iconForSeverity(alert.severity);
        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            alert.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(alert.message),
        );
      },
    );
  }

  Color _colorForSeverity(AlertSeverity severity, BuildContext context) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.redAccent;
      case AlertSeverity.warning:
        return Colors.orangeAccent;
      case AlertSeverity.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _iconForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.dangerous_outlined;
      case AlertSeverity.warning:
        return Icons.warning_amber_outlined;
      case AlertSeverity.info:
        return Icons.info_outline;
    }
  }
}
