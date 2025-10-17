import 'package:flutter/material.dart';

import '../models/report_request_model.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.onSelect,
  });

  final ReportType type;
  final String title;
  final String description;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(description),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FilledButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.bar_chart_outlined),
                  label: const Text('Oluştur'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
