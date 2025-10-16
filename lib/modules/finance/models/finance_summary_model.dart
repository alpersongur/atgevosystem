class FinanceSummary {
  const FinanceSummary({
    required this.invoiced,
    required this.collected,
    required this.outstanding,
    required this.dso,
  });

  final double invoiced;
  final double collected;
  final double outstanding;
  final double dso;

  static const FinanceSummary empty = FinanceSummary(
    invoiced: 0,
    collected: 0,
    outstanding: 0,
    dso: 0,
  );

  FinanceSummary copyWith({
    double? invoiced,
    double? collected,
    double? outstanding,
    double? dso,
  }) {
    return FinanceSummary(
      invoiced: invoiced ?? this.invoiced,
      collected: collected ?? this.collected,
      outstanding: outstanding ?? this.outstanding,
      dso: dso ?? this.dso,
    );
  }
}
