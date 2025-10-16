class AgingBuckets {
  const AgingBuckets({
    required this.b0_30,
    required this.b31_60,
    required this.b61_90,
    required this.b90p,
  });

  final double b0_30;
  final double b31_60;
  final double b61_90;
  final double b90p;

  static const AgingBuckets empty = AgingBuckets(
    b0_30: 0,
    b31_60: 0,
    b61_90: 0,
    b90p: 0,
  );

  AgingBuckets copyWith({
    double? b0_30,
    double? b31_60,
    double? b61_90,
    double? b90p,
  }) {
    return AgingBuckets(
      b0_30: b0_30 ?? this.b0_30,
      b31_60: b31_60 ?? this.b31_60,
      b61_90: b61_90 ?? this.b61_90,
      b90p: b90p ?? this.b90p,
    );
  }
}
