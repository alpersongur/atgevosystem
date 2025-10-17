import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendChartWidget extends StatelessWidget {
  const TrendChartWidget.line({
    super.key,
    required this.labels,
    required this.series,
    this.height = 240,
    this.valueSuffix = '',
  })  : _isLineChart = true,
        barGroups = const [];

  const TrendChartWidget.bar({
    super.key,
    required this.labels,
    required this.barGroups,
    this.height = 240,
    this.valueSuffix = '',
  })  : _isLineChart = false,
        series = const [];

  final List<String> labels;
  final List<FlSpot> series;
  final List<BarChartGroupData> barGroups;
  final double height;
  final String valueSuffix;
  final bool _isLineChart;

  @override
  Widget build(BuildContext context) {
    return _isLineChart
        ? _buildLineChart(context)
        : _buildBarChart(context);
  }

  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(0) + valueSuffix,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: series,
              isCurved: true,
              color: Colors.indigo,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.indigo.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(0) + valueSuffix,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
