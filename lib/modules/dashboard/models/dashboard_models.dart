enum DashboardRange { last7Days, last30Days, last6Months }

class DashboardFilter {
  const DashboardFilter({
    this.range = DashboardRange.last6Months,
    this.companyId,
  });

  final DashboardRange range;
  final String? companyId;

  DashboardFilter copyWith({DashboardRange? range, String? companyId}) {
    return DashboardFilter(
      range: range ?? this.range,
      companyId: companyId ?? this.companyId,
    );
  }

  int get bucketCount {
    switch (range) {
      case DashboardRange.last7Days:
        return 7;
      case DashboardRange.last30Days:
        return 30;
      case DashboardRange.last6Months:
        return 6;
    }
  }

  bool get isMonthlyRange => range == DashboardRange.last6Months;

  DateTime startDate(DateTime reference) {
    final today = DateTime(reference.year, reference.month, reference.day);
    switch (range) {
      case DashboardRange.last7Days:
        return today.subtract(const Duration(days: 6));
      case DashboardRange.last30Days:
        return today.subtract(const Duration(days: 29));
      case DashboardRange.last6Months:
        final currentMonthStart = DateTime(reference.year, reference.month, 1);
        return DateTime(currentMonthStart.year, currentMonthStart.month - 5, 1);
    }
  }

  DateTime endDate(DateTime reference) {
    return DateTime(reference.year, reference.month, reference.day, 23, 59, 59);
  }
}

class DashboardSeriesPoint {
  const DashboardSeriesPoint({
    required this.period,
    required this.label,
    required this.sales,
    required this.collection,
  });

  final DateTime period;
  final String label;
  final double sales;
  final double collection;

  Map<String, dynamic> toJson() => {
        'period': period.toIso8601String(),
        'label': label,
        'sales': sales,
        'collection': collection,
      };

  factory DashboardSeriesPoint.fromJson(Map<String, dynamic> json) {
    return DashboardSeriesPoint(
      period: DateTime.parse(json['period'] as String),
      label: json['label'] as String? ?? '',
      sales: (json['sales'] as num?)?.toDouble() ?? 0,
      collection: (json['collection'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.summary,
    required this.series,
    required this.lowStockAlerts,
    required this.generatedAt,
  });

  final Map<String, dynamic> summary;
  final List<DashboardSeriesPoint> series;
  final int lowStockAlerts;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'series': series.map((point) => point.toJson()).toList(),
        'lowStockAlerts': lowStockAlerts,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final seriesRaw = json['series'] as List<dynamic>? ?? <dynamic>[];
    return DashboardSnapshot(
      summary: Map<String, dynamic>.from(json['summary'] as Map? ?? {}),
      series: seriesRaw
          .map(
            (item) => DashboardSeriesPoint.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      lowStockAlerts: (json['lowStockAlerts'] as num?)?.toInt() ?? 0,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}
