import 'package:flutter/material.dart';

import '../models/assistant_query_model.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final AssistantInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = insight.trendUp == true;
    final trendColor = isPositive
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    insight.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (insight.trendText != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, color: trendColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        insight.trendText!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
