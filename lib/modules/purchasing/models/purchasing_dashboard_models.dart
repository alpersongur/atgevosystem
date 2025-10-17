class PurchasingSummary {
  const PurchasingSummary({
    required this.totalPOs,
    required this.openPOs,
    required this.delayedPOs,
    required this.avgLeadTimeDays,
  });

  final int totalPOs;
  final int openPOs;
  final int delayedPOs;
  final double avgLeadTimeDays;
}

class SupplierPerformance {
  const SupplierPerformance({
    required this.supplierId,
    required this.onTime,
    required this.late,
    this.supplierName,
  });

  final String supplierId;
  final int onTime;
  final int late;
  final String? supplierName;

  SupplierPerformance copyWith({String? supplierName, int? onTime, int? late}) {
    return SupplierPerformance(
      supplierId: supplierId,
      supplierName: supplierName ?? this.supplierName,
      onTime: onTime ?? this.onTime,
      late: late ?? this.late,
    );
  }
}

class MonthlySpendPoint {
  const MonthlySpendPoint({required this.ym, required this.total});

  final String ym;
  final double total;
}
