import 'package:flutter/material.dart';

import 'package:atgevosystem/core/models/customer.dart';
import 'package:atgevosystem/core/services/customer_service.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_filter_bar.dart';
import 'customer_detail_page.dart';
import 'customer_edit_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  static const routeName = '/crm/customers';

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final CustomerService _service = CustomerService.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final stream = _service.watchCustomers();

    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomerFilterBar(
              initialQuery: _searchQuery,
              onQueryChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              trailing: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(CustomerEditPage.createRoute);
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Müşteri'),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CustomerModel>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Veriler alınırken bir hata oluştu.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = snapshot.data ?? <CustomerModel>[];
                final filtered = _searchQuery.trim().isEmpty
                    ? customers
                    : customers
                          .where(
                            (customer) => customer.matchesSearch(_searchQuery),
                          )
                          .toList(growable: false);

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Henüz müşteri kaydı bulunmuyor.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => CustomerDetailPage(
                                    customerId: customer.id,
                                  ),
                                ),
                              )
                              .then((deleted) {
                                if (deleted == true && mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Müşteri silindi'),
                                    ),
                                  );
                                }
                              });
                        },
                        child: CustomerCard(
                          customer: customer,
                          onTap: null,
                          onEdit: () {
                            Navigator.of(context).pushNamed(
                              CustomerEditPage.editRoute,
                              arguments: CustomerEditPageArgs(
                                customerId: customer.id,
                              ),
                            );
                          },
                          onDelete: () => _confirmDelete(context, customer),
                        ),
                      ),
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
          Navigator.of(context).pushNamed(CustomerEditPage.createRoute);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerModel customer,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Müşteri Sil'),
            content: Text(
              '"${customer.companyName}" kaydını silmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    try {
      await _service.deleteCustomer(customer.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Müşteri silindi')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme sırasında bir hata oluştu: $error')),
      );
    }
  }
}
