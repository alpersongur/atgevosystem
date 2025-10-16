class MonthlyPoint {
  const MonthlyPoint({
    required this.ym,
    required this.invoiced,
    required this.collected,
  });

  final String ym;
  final double invoiced;
  final double collected;

  MonthlyPoint copyWith({String? ym, double? invoiced, double? collected}) {
    return MonthlyPoint(
      ym: ym ?? this.ym,
      invoiced: invoiced ?? this.invoiced,
      collected: collected ?? this.collected,
    );
  }
}
