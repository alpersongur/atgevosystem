import 'package:flutter/material.dart';

class QuoteStatusChip extends StatelessWidget {
  const QuoteStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().trim();
    final info = _statusStyles[normalized] ?? _StatusStyle.fallback;

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: info.border),
      ),
      child: Text(
        info.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: info.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  static _StatusStyle fallback = _StatusStyle(
    label: 'Belirsiz',
    background: Colors.grey.shade100,
    foreground: Colors.grey.shade700,
    border: Colors.grey.shade300,
  );
}

final Map<String, _StatusStyle> _statusStyles = {
  'pending': _StatusStyle(
    label: 'Beklemede',
    background: Colors.orange.shade50,
    foreground: Colors.orange.shade800,
    border: Colors.orange.shade200,
  ),
  'approved': _StatusStyle(
    label: 'Onaylandı',
    background: Colors.green.shade50,
    foreground: Colors.green.shade800,
    border: Colors.green.shade200,
  ),
  'rejected': _StatusStyle(
    label: 'Reddedildi',
    background: Colors.red.shade50,
    foreground: Colors.red.shade800,
    border: Colors.red.shade200,
  ),
  'in_production': _StatusStyle(
    label: 'Üretimde',
    background: Colors.indigo.shade50,
    foreground: Colors.indigo.shade700,
    border: Colors.indigo.shade200,
  ),
};
