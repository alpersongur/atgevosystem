class TopCustomer {
  const TopCustomer({
    required this.customerId,
    this.customerName,
    required this.total,
  });

  final String customerId;
  final String? customerName;
  final double total;

  TopCustomer copyWith({
    String? customerId,
    String? customerName,
    double? total,
  }) {
    return TopCustomer(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      total: total ?? this.total,
    );
  }
}
