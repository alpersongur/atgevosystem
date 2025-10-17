import 'package:flutter/material.dart';

class ModuleOverviewCard extends StatelessWidget {
  const ModuleOverviewCard({
    super.key,
    required this.modules,
    required this.onToggle,
  });

  final List<Map<String, dynamic>> modules;
  final void Function(String moduleId, bool active) onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modül Durumu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (modules.isEmpty)
              const Text('Modül bulunamadı.')
            else
              ...modules.map((module) {
                final name = module['name'] as String? ?? 'Adsız';
                final code = module['code'] as String? ?? '-';
                final description = module['description'] as String? ?? '';
                final active = module['active'] == true;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name),
                  subtitle: Text(
                    'Kod: $code${description.isEmpty ? '' : ' • $description'}',
                  ),
                  trailing: Switch(
                    value: active,
                    onChanged: (value) =>
                        onToggle(module['id'] as String, value),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
