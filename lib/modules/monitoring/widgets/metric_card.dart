import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.threshold,
    this.warningValue,
  });

  final String title;
  final String value;
  final IconData icon;
  final double? threshold;
  final double? warningValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = warningValue != null && threshold != null
        ? warningValue! >= threshold!
        : false;

    final color = warning
        ? Colors.redAccent
        : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (warning)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠ Kritik seviyeye ulaştı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
