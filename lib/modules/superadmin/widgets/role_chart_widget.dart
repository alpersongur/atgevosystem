import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RoleChartWidget extends StatelessWidget {
  const RoleChartWidget({
    super.key,
    required this.roleDistribution,
  });

  final Map<String, int> roleDistribution;

  @override
  Widget build(BuildContext context) {
    if (roleDistribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Rol verisi bulunmuyor.'),
        ),
      );
    }

    final total = roleDistribution.values.fold<int>(0, (acc, value) => acc + value);
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
    ];
    int colorIndex = 0;

    final sections = roleDistribution.entries.map((entry) {
      final percentage = total == 0 ? 0 : entry.value / total * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rol Dağılımı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
