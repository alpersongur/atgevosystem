import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class UsageDetailModal extends StatelessWidget {
  const UsageDetailModal({
    super.key,
    required this.dailyStats,
    required this.moduleDistribution,
    required this.logs,
  });

  final Map<String, Map<String, num>> dailyStats; // date -> {read, write, delete}
  final Map<String, num> moduleDistribution; // module -> usage count
  final List<Map<String, dynamic>> logs; // {message, timestamp}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Günlük İşlem Grafiği', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: _buildLineChart()),
            const SizedBox(height: 24),
            Text('Modül Kullanım Dağılımı', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: _buildPieChart()),
            const SizedBox(height: 24),
            Text('Son Loglar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildLogsList(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (dailyStats.isEmpty) {
      return const Center(child: Text('Grafik verisi bulunmuyor.'));
    }

    final sortedKeys = dailyStats.keys.toList()..sort();
    final readSpots = <FlSpot>[];
    final writeSpots = <FlSpot>[];
    final deleteSpots = <FlSpot>[];

    for (var i = 0; i < sortedKeys.length; i++) {
      final stats = Map<String, num>.from(dailyStats[sortedKeys[i]] ?? {});
      readSpots.add(FlSpot(i.toDouble(), (stats['read'] ?? 0).toDouble()));
      writeSpots.add(FlSpot(i.toDouble(), (stats['write'] ?? 0).toDouble()));
      deleteSpots.add(FlSpot(i.toDouble(), (stats['delete'] ?? 0).toDouble()));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedKeys.length) {
                  return const SizedBox.shrink();
                }
                final label = sortedKeys[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 1, verticalInterval: 1),
        lineBarsData: [
          LineChartBarData(
            spots: readSpots,
            color: Colors.indigo,
            barWidth: 2,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: writeSpots,
            color: Colors.teal,
            barWidth: 2,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: deleteSpots,
            color: Colors.redAccent,
            barWidth: 2,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
        minX: 0,
        maxX: (sortedKeys.length - 1).toDouble(),
      ),
    );
  }

  Widget _buildPieChart() {
    if (moduleDistribution.isEmpty) {
      return const Center(child: Text('Modül dağılımı bulunmuyor.'));
    }

    final total = moduleDistribution.values.fold<num>(0, (sum, value) => sum + value);
    if (total == 0) {
      return const Center(child: Text('Modül dağılımı bulunmuyor.'));
    }

    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
    ];
    int colorIndex = 0;

    final sections = moduleDistribution.entries.map((entry) {
      final value = entry.value;
      final percentage = (value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: value.toDouble(),
        color: color,
        title: '${entry.key.toUpperCase()}\n${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildLogsList() {
    if (logs.isEmpty) {
      return const Text('Log kaydı bulunmuyor.');
    }

    return Column(
      children: logs.take(10).map((log) {
        final message = log['message']?.toString() ?? 'Log mesajı yok';
        final timestamp = log['timestamp'];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(message),
          subtitle: Text(timestamp?.toString() ?? ''),
        );
      }).toList(),
    );
  }
}
