import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSeriesPoint {
  const TimeSeriesPoint({required this.period, required this.value});

  final DateTime period;
  final double value;
}

class ForecastInterval {
  const ForecastInterval({required this.lower, required this.upper});

  final double lower;
  final double upper;
}

class SalesForecast {
  const SalesForecast({
    required this.history,
    required this.forecast,
    required this.intervals,
    required this.nextMonthEstimate,
  });

  final List<TimeSeriesPoint> history;
  final List<TimeSeriesPoint> forecast;
  final List<ForecastInterval> intervals;
  final double nextMonthEstimate;
}

class ProductionForecast {
  const ProductionForecast({
    required this.history,
    required this.forecast,
    required this.intervals,
  });

  final List<TimeSeriesPoint> history;
  final List<TimeSeriesPoint> forecast;
  final List<ForecastInterval> intervals;
}

class InventoryRisk {
  const InventoryRisk({
    required this.highRiskItemId,
    required this.riskScore,
    required this.remainingQuantity,
    required this.minStock,
  });

  final String? highRiskItemId;
  final double riskScore;
  final double remainingQuantity;
  final double minStock;

  bool get hasRisk => highRiskItemId != null && riskScore > 0;
}

class PredictiveAnalyticsResult {
  const PredictiveAnalyticsResult({
    required this.salesForecast,
    required this.productionForecast,
    required this.inventoryRisk,
  });

  final SalesForecast salesForecast;
  final ProductionForecast productionForecast;
  final InventoryRisk inventoryRisk;
}

class AnalyticsService {
  AnalyticsService._(this._firestore);

  factory AnalyticsService({FirebaseFirestore? firestore}) {
    if (firestore == null) return instance;
    return AnalyticsService._(firestore);
  }

  static final AnalyticsService instance =
      AnalyticsService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

  Future<PredictiveAnalyticsResult> loadAnalytics({int months = 12}) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);

    final salesFuture = _fetchMonthlySales(startDate, now);
    final productionFuture = _fetchProductionUsage(startDate, now);
    final inventoryFuture = _fetchInventorySnapshot();

    final monthlySales = await salesFuture;
    final productionData = await productionFuture;
    final inventoryData = await inventoryFuture;

    final salesForecast = _buildSalesForecast(monthlySales);
    final productionForecast = _buildProductionForecast(productionData);
    final inventoryRisk = _evaluateInventoryRisk(inventoryData);

    return PredictiveAnalyticsResult(
      salesForecast: salesForecast,
      productionForecast: productionForecast,
      inventoryRisk: inventoryRisk,
    );
  }

  Future<List<TimeSeriesPoint>> _fetchMonthlySales(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('quotes')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final totals = <DateTime, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = _toDate(data['created_at']);
      if (createdAt == null) continue;
      final amount = (data['amount'] as num?)?.toDouble() ??
          (data['grand_total'] as num?)?.toDouble() ??
          0.0;
      final monthKey = DateTime(createdAt.year, createdAt.month);
      totals[monthKey] = (totals[monthKey] ?? 0) + amount;
    }

    final sortedKeys = totals.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return sortedKeys
        .map((date) => TimeSeriesPoint(period: date, value: totals[date]!))
        .toList(growable: false);
  }

  Future<List<TimeSeriesPoint>> _fetchProductionUsage(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('production_orders')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final counts = <DateTime, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = _toDate(data['created_at']) ??
          _toDate(data['start_date']) ??
          _toDate(data['startDate']);
      if (createdAt == null) continue;
      final monthKey = DateTime(createdAt.year, createdAt.month);
      counts[monthKey] = (counts[monthKey] ?? 0) + 1;
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return sortedKeys
        .map((date) => TimeSeriesPoint(period: date, value: counts[date]!))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchInventorySnapshot() async {
    final snapshot = await _firestore.collection('inventory').get();
    return snapshot.docs.map((doc) => doc.data()).toList(growable: false);
  }

  SalesForecast _buildSalesForecast(List<TimeSeriesPoint> history) {
    if (history.isEmpty) {
      return SalesForecast(
        history: const [],
        forecast: const [],
        intervals: const [],
        nextMonthEstimate: 0,
      );
    }

    final sortedHistory = history.toList()
      ..sort((a, b) => a.period.compareTo(b.period));

    final values = sortedHistory.map((point) => point.value).toList();
    final forecastValue = _movingAverage(values, window: 3);
    final stdDev = _standardDeviation(values);
    final upper = forecastValue + stdDev;
    final lower = max(0, forecastValue - stdDev).toDouble();

    final nextMonth =
        DateTime(sortedHistory.last.period.year, sortedHistory.last.period.month + 1);

    return SalesForecast(
      history: sortedHistory,
      forecast: [
        TimeSeriesPoint(period: nextMonth, value: forecastValue),
        TimeSeriesPoint(
          period: DateTime(nextMonth.year, nextMonth.month + 1),
          value: forecastValue * 1.02,
        ),
      ],
      intervals: [
        ForecastInterval(lower: lower, upper: upper),
        ForecastInterval(
          lower: max(0, lower * 0.95).toDouble(),
          upper: upper * 1.05,
        ),
      ],
      nextMonthEstimate: forecastValue,
    );
  }

  ProductionForecast _buildProductionForecast(List<TimeSeriesPoint> history) {
    if (history.isEmpty) {
      return ProductionForecast(
        history: const [],
        forecast: const [],
        intervals: const [],
      );
    }

    final sortedHistory = history.toList()
      ..sort((a, b) => a.period.compareTo(b.period));
    final values = sortedHistory.map((point) => point.value).toList();
    final forecastValue = _linearTrendForecast(values);
    final stdDev = _standardDeviation(values);
    final nextPeriod = DateTime(
      sortedHistory.last.period.year,
      sortedHistory.last.period.month + 1,
    );

    return ProductionForecast(
      history: sortedHistory,
      forecast: [
        TimeSeriesPoint(period: nextPeriod, value: forecastValue),
      ],
      intervals: [
        ForecastInterval(
          lower: max(0, forecastValue - stdDev).toDouble(),
          upper: forecastValue + stdDev,
        ),
      ],
    );
  }

  InventoryRisk _evaluateInventoryRisk(List<Map<String, dynamic>> inventory) {
    String? riskItem;
    double highestRisk = 0;
    double remainingQuantity = 0;
    double minStock = 0;

    for (final item in inventory) {
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
      final min = (item['min_stock'] as num?)?.toDouble() ?? 0;
      if (min <= 0) continue;
      final ratio = quantity / min;
      if (ratio < highestRisk || riskItem == null) {
        riskItem = item['sku'] as String? ?? item['id'] as String?;
        highestRisk = ratio;
        remainingQuantity = quantity;
        minStock = min;
      }
    }

    if (riskItem == null) {
      return const InventoryRisk(
        highRiskItemId: null,
        riskScore: 0,
        remainingQuantity: 0,
        minStock: 0,
      );
    }

    return InventoryRisk(
      highRiskItemId: riskItem,
      riskScore: highestRisk,
      remainingQuantity: remainingQuantity,
      minStock: minStock,
    );
  }

  double _movingAverage(List<double> values, {int window = 3}) {
    if (values.isEmpty) return 0;
    final start = max(0, values.length - window);
    final recent = values.sublist(start);
    final sum = recent.fold<double>(0, (prev, value) => prev + value);
    return sum / recent.length;
  }

  double _linearTrendForecast(List<double> values) {
    if (values.isEmpty) return 0;
    final n = values.length;
    final xValues = List<double>.generate(n, (index) => index.toDouble());
    final xMean = xValues.reduce((a, b) => a + b) / n;
    final yMean = values.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;
    for (var i = 0; i < n; i++) {
      numerator += (xValues[i] - xMean) * (values[i] - yMean);
      denominator += pow(xValues[i] - xMean, 2);
    }

    final slope = denominator == 0 ? 0 : numerator / denominator;
    final intercept = yMean - slope * xMean;
    final nextX = n.toDouble();
    final forecast = intercept + slope * nextX;
    return max(0, forecast).toDouble();
  }

  double _standardDeviation(List<double> values) {
    if (values.length < 2) return values.isEmpty ? 0 : values.first * 0.1;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((value) => pow(value - mean, 2))
        .reduce((a, b) => a + b) /
        (values.length - 1);
    return sqrt(variance);
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
