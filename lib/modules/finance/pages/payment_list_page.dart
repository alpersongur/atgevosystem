import 'package:flutter/material.dart';

import '../../crm/models/customer_model.dart';
import '../../crm/services/customer_service.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../services/invoice_service.dart';
import '../services/payment_service.dart';
import '../widgets/payment_card.dart';
import 'payment_detail_page.dart';
import 'payment_edit_page.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  static const routeName = '/finance/payments';

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _dateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initialRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  bool _matchesFilters(PaymentModel payment) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      final matchesQuery =
          payment.invoiceId.toLowerCase().contains(query) ||
          payment.customerId.toLowerCase().contains(query) ||
          (payment.txnRef ?? '').toLowerCase().contains(query);
      if (!matchesQuery) return false;
    }

    if (_dateRange != null) {
      final date = payment.paymentDate;
      if (date == null) return false;
      final start = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );
      final end = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
        23,
        59,
        59,
      );
      if (date.isBefore(start) || date.isAfter(end)) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tahsilatlar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Fatura / Müşteri / Referans',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Tarih Aralığı Seç',
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_month),
                ),
                if (_dateRange != null)
                  IconButton(
                    tooltip: 'Filtreyi Temizle',
                    onPressed: () => setState(() => _dateRange = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PaymentModel>>(
              stream: PaymentService.instance.getPaymentsStream(),
              builder: (context, paymentSnapshot) {
                if (paymentSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Tahsilatlar yüklenirken bir hata oluştu.\n${paymentSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (paymentSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    paymentSnapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = paymentSnapshot.data ?? <PaymentModel>[];
                final filtered = payments.where(_matchesFilters).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Filtre kriterlerine uygun tahsilat bulunamadı.',
                    ),
                  );
                }

                return StreamBuilder<List<InvoiceModel>>(
                  stream: InvoiceService.instance.getInvoices(),
                  builder: (context, invoiceSnapshot) {
                    final invoiceMap = <String, InvoiceModel>{};
                    if (invoiceSnapshot.hasData) {
                      for (final invoice in invoiceSnapshot.data!) {
                        invoiceMap[invoice.id] = invoice;
                      }
                    }

                    return StreamBuilder<List<CustomerModel>>(
                      stream: CustomerService.instance.getCustomers(),
                      builder: (context, customerSnapshot) {
                        final customerMap = <String, CustomerModel>{};
                        if (customerSnapshot.hasData) {
                          for (final customer in customerSnapshot.data!) {
                            customerMap[customer.id] = customer;
                          }
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final payment = filtered[index];
                            final invoice = invoiceMap[payment.invoiceId];
                            final customer = customerMap[payment.customerId];

                            return PaymentCard(
                              payment: payment,
                              invoiceNo: invoice?.invoiceNo,
                              customerName: customer?.companyName,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PaymentDetailPage(
                                      paymentId: payment.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(PaymentEditPage.createRoute);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
