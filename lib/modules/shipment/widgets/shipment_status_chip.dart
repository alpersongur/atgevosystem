import 'package:flutter/material.dart';

class ShipmentStatusChip extends StatelessWidget {
  const ShipmentStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final info = _statusStyles[status] ?? _StatusStyle.fallback;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(999),
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
  });

  final String label;
  final Color background;
  final Color foreground;

  static final fallback = _StatusStyle(
    label: 'Bilinmiyor',
    background: Colors.grey.shade200,
    foreground: Colors.grey.shade600,
  );
}

final Map<String, _StatusStyle> _statusStyles = {
  'preparing': _StatusStyle(
    label: 'Hazırlanıyor',
    background: Colors.orange.shade50,
    foreground: Colors.orange.shade800,
  ),
  'on_the_way': _StatusStyle(
    label: 'Yolda',
    background: Colors.indigo.shade50,
    foreground: Colors.indigo.shade700,
  ),
  'delivered': _StatusStyle(
    label: 'Teslim Edildi',
    background: Colors.green.shade50,
    foreground: Colors.green.shade700,
  ),
};
