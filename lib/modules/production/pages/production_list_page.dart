import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../crm/models/customer_model.dart';
import '../../crm/quotes/models/quote_model.dart';
import '../../crm/quotes/services/quote_service.dart';
import '../../crm/services/customer_service.dart';
import '../models/production_order_model.dart';
import '../services/production_service.dart';
import '../widgets/production_card.dart';
import 'production_detail_page.dart';
import 'production_edit_page.dart';

class ProductionListPage extends StatelessWidget {
  const ProductionListPage({super.key});

  static const routeName = '/production/orders';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üretim Talimatları'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProductionEditPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ProductionOrderModel>>(
        stream: ProductionService.instance.getOrdersStream(),
        builder: (context, ordersSnapshot) {
          if (ordersSnapshot.hasError) {
            return Center(
              child: Text(
                'Üretim talimatları yüklenirken hata oluştu.\n${ordersSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (ordersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = ordersSnapshot.data ?? <ProductionOrderModel>[];
          if (orders.isEmpty) {
            return const Center(
              child: Text('Henüz üretim talimatı oluşturulmamış.'),
            );
          }

          return StreamBuilder<List<CustomerModel>>(
            stream: CustomerService.instance.getCustomers(),
            builder: (context, customerSnapshot) {
              if (customerSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final customers = <String, CustomerModel>{
                for (final customer in customerSnapshot.data ?? [])
                  customer.id: customer,
              };

              return StreamBuilder<List<QuoteModel>>(
                stream: QuoteService().getQuotes(),
                builder: (context, quoteSnapshot) {
                  if (quoteSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final quotes = <String, QuoteModel>{
                    for (final quote in quoteSnapshot.data ?? [])
                      quote.id: quote,
                  };

                  return _ProductionOrdersTable(
                    orders: orders,
                    customers: customers,
                    quotes: quotes,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductionOrdersTable extends StatelessWidget {
  const _ProductionOrdersTable({
    required this.orders,
    required this.customers,
    required this.quotes,
  });

  final List<ProductionOrderModel> orders;
  final Map<String, CustomerModel> customers;
  final Map<String, QuoteModel> quotes;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return ProductionCard(
                order: order,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductionDetailPage(orderId: order.id),
                    ),
                  );
                },
                onEdit: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductionDetailPage(orderId: order.id),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Teklif')),
                  DataColumn(label: Text('Müşteri')),
                  DataColumn(label: Text('Durum')),
                  DataColumn(label: Text('Başlangıç')),
                  DataColumn(label: Text('Tahmini Bitiş')),
                ],
                rows: orders.map((order) {
                  final quote = quotes[order.quoteId];
                  final customer = customers[order.customerId];
                  final start = order.startDate != null
                      ? dateFormat.format(order.startDate!)
                      : '—';
                  final eta = order.estimatedCompletion != null
                      ? dateFormat.format(order.estimatedCompletion!)
                      : '—';
                  return DataRow(
                    cells: [
                      DataCell(Text(quote?.quoteNumber ?? order.quoteId)),
                      DataCell(Text(customer?.companyName ?? '—')),
                      DataCell(ProductionStatusChip(status: order.status)),
                      DataCell(Text(start)),
                      DataCell(Text(eta)),
                    ],
                    onSelectChanged: (_) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductionDetailPage(orderId: order.id),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
