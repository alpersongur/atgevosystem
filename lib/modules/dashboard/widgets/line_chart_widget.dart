import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardLineChart extends StatelessWidget {
  const DashboardLineChart({
    super.key,
    required this.salesData,
    required this.paymentData,
    required this.labels,
    this.height = 260,
    this.valueFormatter,
    this.salesColor = Colors.indigo,
    this.paymentColor = Colors.green,
  });

  final List<double> salesData;
  final List<double> paymentData;
  final List<String> labels;
  final double height;
  final NumberFormat? valueFormatter;
  final Color salesColor;
  final Color paymentColor;

  @override
  Widget build(BuildContext context) {
    final effectiveLength = min(
      labels.length,
      min(salesData.length, paymentData.length),
    );

    if (effectiveLength == 0) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Grafik verisi bulunamadı.')),
      );
    }

    final theme = Theme.of(context);

    final salesSpots = <FlSpot>[];
    final paymentSpots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < effectiveLength; i++) {
      final sales = salesData[i];
      final payment = paymentData[i];
      salesSpots.add(FlSpot(i.toDouble(), sales));
      paymentSpots.add(FlSpot(i.toDouble(), payment));
      maxY = max(maxY, max(sales, payment));
    }

    final interval = _computeInterval(maxY);
    final effectiveInterval = interval <= 0 ? 1.0 : interval;
    final effectiveMaxY = maxY == 0
        ? effectiveInterval
        : maxY + effectiveInterval;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: effectiveMaxY,
          gridData: FlGridData(
            show: true,
            horizontalInterval: effectiveInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= effectiveLength) {
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: effectiveInterval,
                reservedSize: 60,
                getTitlesWidget: (value, _) {
                  if (value == 0) return const Text('0');
                  final formatter =
                      valueFormatter ??
                      NumberFormat.compactCurrency(
                        locale: Intl.defaultLocale ?? 'tr_TR',
                        symbol: '₺',
                        decimalDigits: 0,
                      );
                  return Text(
                    formatter.format(value),
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  theme.colorScheme.surface.withValues(alpha: 0.92),
              getTooltipItems: (touchedSpots) {
                final baseStyle =
                    theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 12);
                return touchedSpots
                    .map((spot) {
                      final index = spot.x.toInt();
                      final label = index >= 0 && index < effectiveLength
                          ? labels[index]
                          : '';
                      final formatter =
                          valueFormatter ??
                          NumberFormat.currency(
                            locale: Intl.defaultLocale ?? 'tr_TR',
                            symbol: '₺',
                            decimalDigits: 0,
                          );
                      final valueLabel = formatter.format(spot.y);
                      final name = spot.barIndex == 0 ? 'Satış' : 'Tahsilat';
                      return LineTooltipItem(
                        '$label\n$name: $valueLabel',
                        baseStyle.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    })
                    .toList(growable: false);
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: salesSpots,
              isCurved: true,
              color: salesColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: salesColor.withValues(alpha: 0.12),
              ),
            ),
            LineChartBarData(
              spots: paymentSpots,
              isCurved: true,
              color: paymentColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: paymentColor.withValues(alpha: 0.1),
              ),
            ),
          ],
          extraLinesData: maxY == 0
              ? ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0,
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ],
                )
              : const ExtraLinesData(horizontalLines: []),
        ),
      ),
    );
  }

  double _computeInterval(double maxValue) {
    if (maxValue <= 0) return 0;
    final rawInterval = maxValue / 4;
    if (rawInterval == 0) return 0;
    final magnitude = pow(10, (log(rawInterval) / log(10)).floor()).toDouble();
    final normalized = rawInterval / magnitude;

    double rounded;
    if (normalized < 1.5) {
      rounded = 1;
    } else if (normalized < 3) {
      rounded = 2;
    } else if (normalized < 7) {
      rounded = 5;
    } else {
      rounded = 10;
    }
    return rounded * magnitude;
  }
}
