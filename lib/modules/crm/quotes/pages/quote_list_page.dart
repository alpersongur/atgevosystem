import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';
import '../widgets/quote_card.dart';
import 'quote_detail_page.dart';
import 'quote_edit_page.dart';

class QuoteListPage extends StatefulWidget {
  const QuoteListPage({super.key});

  static const routeName = '/crm/quotes';

  @override
  State<QuoteListPage> createState() => _QuoteListPageState();
}

class _QuoteListPageState extends State<QuoteListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teklifler & Fırsatlar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Teklif ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Temizle',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<CustomerModel>>(
                stream: CustomerService().getCustomers(),
                builder: (context, customerSnapshot) {
                  if (customerSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Müşteri verileri alınamadı.\n${customerSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (customerSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customerMap = {
                    for (final customer in customerSnapshot.data ?? [])
                      customer.id: customer.companyName,
                  };

                  return StreamBuilder<List<QuoteModel>>(
                    stream: QuoteService().getQuotes(),
                    builder: (context, quoteSnapshot) {
                      if (quoteSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Teklifler alınırken bir hata oluştu.\n${quoteSnapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (quoteSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final quotes = quoteSnapshot.data ?? <QuoteModel>[];
                      if (quotes.isEmpty) {
                        return const Center(
                          child: Text('Henüz teklif kaydı bulunmuyor.'),
                        );
                      }

                      final filtered = _searchQuery.isEmpty
                          ? quotes
                          : quotes.where(_matchesSearch).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('Arama kriterine uygun teklif bulunamadı.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final quote = filtered[index];
                          final customerName =
                              customerMap[quote.customerId] ?? 'Müşteri';
                          return QuoteCard(
                            quote: quote,
                            customerName: customerName,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => QuoteDetailPage(
                                    quoteId: quote.id,
                                  ),
                                ),
                              );
                            },
                            onEdit: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => QuoteEditPage(
                                    quoteId: quote.id,
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
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(QuoteEditPage.createRoute);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _matchesSearch(QuoteModel quote) {
    if (_searchQuery.isEmpty) return true;
    final formattedAmount = NumberFormat('#,##0.00').format(quote.amount);
    final values = [
      quote.quoteNumber,
      quote.title,
      quote.status,
      formattedAmount,
    ];
    return values
        .where((value) => value.isNotEmpty)
        .map((value) => value.toLowerCase())
        .any((value) => value.contains(_searchQuery));
  }
}
