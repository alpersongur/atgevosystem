import 'package:flutter/material.dart';

class QaKpiCard extends StatelessWidget {
  const QaKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.color,
    this.icon,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cardColor =
        color ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    final onCardColor = Theme.of(context).colorScheme.onSurface;
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null)
                  Icon(icon, color: onCardColor.withValues(alpha: 0.8)),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onCardColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: onCardColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onCardColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
