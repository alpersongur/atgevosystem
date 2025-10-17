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
