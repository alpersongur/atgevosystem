import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../crm/models/customer_model.dart';
import '../../crm/services/customer_service.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';
import '../widgets/invoice_card.dart';
import 'invoice_detail_page.dart';
import 'invoice_edit_page.dart';

class InvoiceListPage extends StatelessWidget {
  const InvoiceListPage({super.key});

  static const routeName = '/finance/invoices';

  @override
  Widget build(BuildContext context) {
    final invoiceStream = InvoiceService.instance.getInvoices();

    return Scaffold(
      appBar: AppBar(title: const Text('Faturalar')),
      body: StreamBuilder<List<InvoiceModel>>(
        stream: invoiceStream,
        builder: (context, invoiceSnapshot) {
          if (invoiceSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Faturalar yüklenirken bir hata oluştu.\n${invoiceSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (invoiceSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoices = invoiceSnapshot.data ?? <InvoiceModel>[];

          if (invoices.isEmpty) {
            return const Center(child: Text('Henüz fatura kaydı bulunmuyor.'));
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

              final dateFormat = DateFormat('dd.MM.yyyy');
              final currencyFormat = NumberFormat.currency(
                symbol: '',
                decimalDigits: 2,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 720) {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: invoices.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        final customerName =
                            customerMap[invoice.customerId]?.companyName ??
                            invoice.customerId;
                        return InvoiceCard(
                          invoice: invoice,
                          customerName: customerName,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    InvoiceDetailPage(invoiceId: invoice.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Fatura No')),
                            DataColumn(label: Text('Müşteri')),
                            DataColumn(label: Text('Düzenlenme')),
                            DataColumn(label: Text('Vade')),
                            DataColumn(label: Text('Tutar')),
                            DataColumn(label: Text('Durum')),
                          ],
                          rows: invoices
                              .map(
                                (invoice) => DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        invoice.invoiceNo.isEmpty
                                            ? invoice.id
                                            : invoice.invoiceNo,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        customerMap[invoice.customerId]
                                                ?.companyName ??
                                            invoice.customerId,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        invoice.issueDate != null
                                            ? dateFormat.format(
                                                invoice.issueDate!,
                                              )
                                            : '—',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        invoice.dueDate != null
                                            ? dateFormat.format(
                                                invoice.dueDate!,
                                              )
                                            : '—',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${invoice.currency} ${currencyFormat.format(invoice.grandTotal)}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(invoice.status.toUpperCase()),
                                    ),
                                  ],
                                  onSelectChanged: (_) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => InvoiceDetailPage(
                                          invoiceId: invoice.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(InvoiceEditPage.createRoute);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
