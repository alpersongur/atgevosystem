import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/qa_run_model.dart';

class QaTrendChart extends StatelessWidget {
  const QaTrendChart({super.key, required this.runs});

  final List<QaRunModel> runs;

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) {
      return const Center(child: Text('Veri bulunmuyor.'));
    }
    final sorted = runs.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final coverageSpots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      coverageSpots.add(FlSpot(i.toDouble(), sorted[i].coveragePct));
    }
    final maxCoverage = coverageSpots
        .map((spot) => spot.y)
        .fold<double>(0, (prev, value) => value > prev ? value : prev);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxCoverage < 100 ? 100 : maxCoverage,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sorted.length) {
                  return const SizedBox.shrink();
                }
                final run = sorted[index];
                return Text(
                  '${run.createdAt.month}/${run.createdAt.day}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
            ),
          ),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 10),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: coverageSpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
