import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardPieChart extends StatelessWidget {
  const DashboardPieChart({
    super.key,
    required this.data,
    this.height = 240,
    this.showLegend = true,
    this.colorPalette,
    this.percentDigits = 0,
  });

  final Map<String, double> data;
  final double height;
  final bool showLegend;
  final List<Color>? colorPalette;
  final int percentDigits;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.values.every((value) => value <= 0)) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Dağılım için yeterli veri yok.')),
      );
    }

    final theme = Theme.of(context);
    final total = data.values.fold<double>(0, (sum, value) => sum + value);
    final colors =
        colorPalette ??
        [
          Colors.indigoAccent,
          Colors.deepPurpleAccent,
          Colors.orangeAccent,
          Colors.teal,
          Colors.redAccent,
          Colors.blueGrey,
        ];

    final sections = <PieChartSectionData>[];
    final legendItems = <_LegendItem>[];
    var index = 0;
    for (final entry in data.entries) {
      final value = entry.value;
      if (value <= 0) continue;
      final percentage = (value / total) * 100;
      final color = colors[index % colors.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '${percentage.toStringAsFixed(percentDigits)}%',
          radius: 70,
          titleStyle: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      legendItems.add(
        _LegendItem(
          color: color,
          label:
              '${entry.key}: ${NumberFormat.compact(locale: 'tr_TR').format(value)}',
        ),
      );
      index++;
    }

    if (sections.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Dağılım için yeterli veri yok.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: sections,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        if (showLegend)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: legendItems.map((item) => item.build(context)).toList(),
            ),
          ),
      ],
    );
  }
}

class _LegendItem {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
