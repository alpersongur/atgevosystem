import 'package:flutter/material.dart';

import '../../assistant/widgets/insight_card.dart';
import '../../assistant/models/assistant_query_model.dart';
import '../../assistant/services/assistant_service.dart';
import '../services/bi_service.dart';

class BiDashboardPage extends StatefulWidget {
  const BiDashboardPage({super.key});

  static const routeName = '/bi/dashboard';

  @override
  State<BiDashboardPage> createState() => _BiDashboardPageState();
}

class _BiDashboardPageState extends State<BiDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BiRange _range = BiRange.last6;
  bool _loading = false;
  List<Map<String, dynamic>> _salesRows = const [];
  List<Map<String, dynamic>> _opsRows = const [];
  List<Map<String, dynamic>> _purchRows = const [];
  List<Map<String, dynamic>> _inventoryRows = const [];
  List<AssistantInsight> _assistantInsights = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final months = _range == BiRange.last6 ? 6 : 12;
      final sales = await BiService.instance.queryBQ(
        'SELECT company_id, month_start, ym, invoiced_total, collected_total, outstanding_total '
        'FROM atg_erp.mz_fin_monthly '
        'WHERE month_start >= DATE_SUB(CURRENT_DATE(), INTERVAL @months MONTH) '
        'ORDER BY month_start ASC',
        params: {'months': months},
      );

      final ops = await BiService.instance.queryBQ(
        'SELECT company_id, kpi_date, open_quotes, active_prod_orders, pending_shipments '
        'FROM atg_erp.mz_ops_kpis '
        'WHERE kpi_date >= DATE_SUB(CURRENT_DATE(), INTERVAL @months MONTH) '
        'ORDER BY kpi_date DESC',
        params: {'months': months},
      );

      final purch = await BiService.instance.queryBQ(
        'SELECT company_id, DATE(created_at) AS po_date, status, total_amount '
        'FROM atg_erp.raw_purchase_orders '
        'WHERE DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL @months MONTH) '
        'ORDER BY po_date DESC',
        params: {'months': months},
      );

      final inventory = await BiService.instance.queryBQ(
        'SELECT company_id, item_id, name, quantity, valuation, updated_at '
        'FROM atg_erp.raw_inventory '
        'ORDER BY quantity ASC LIMIT 50',
      );

      final insights = await AssistantService.instance.fetchDashboardInsights();

      setState(() {
        _salesRows = sales;
        _opsRows = ops;
        _purchRows = purch;
        _inventoryRows = inventory;
        _assistantInsights = insights;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BI Kontrol Paneli'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Satış & Tahsilat'),
            Tab(text: 'Operasyon'),
            Tab(text: 'Satınalma'),
            Tab(text: 'Envanter'),
          ],
        ),
        actions: [
          DropdownButton<BiRange>(
            value: _range,
            underline: const SizedBox.shrink(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _range = value);
              _fetchAll();
            },
            items: const [
              DropdownMenuItem(value: BiRange.last6, child: Text('Son 6 Ay')),
              DropdownMenuItem(value: BiRange.last12, child: Text('Son 12 Ay')),
            ],
          ),
          IconButton(
            onPressed: _loading ? null : _fetchAll,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _fetchAll)
          : Column(
              children: [
                if (_assistantInsights.isNotEmpty)
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => SizedBox(
                        width: 280,
                        child: InsightCard(insight: _assistantInsights[index]),
                      ),
                      separatorBuilder: (context, _) =>
                          const SizedBox(width: 12),
                      itemCount: _assistantInsights.length,
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _DataTableView(
                        rows: _salesRows,
                        emptyLabel: 'Finans verisi bulunamadı.',
                      ),
                      _DataTableView(
                        rows: _opsRows,
                        emptyLabel: 'Operasyon verisi bulunamadı.',
                      ),
                      _DataTableView(
                        rows: _purchRows,
                        emptyLabel: 'Satınalma verisi bulunamadı.',
                      ),
                      _DataTableView(
                        rows: _inventoryRows,
                        emptyLabel: 'Envanter verisi bulunamadı.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DataTableView extends StatelessWidget {
  const _DataTableView({required this.rows, required this.emptyLabel});

  final List<Map<String, dynamic>> rows;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(child: Text(emptyLabel));
    }

    final columns = rows.first.keys.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        columns: columns
            .map((column) => DataColumn(label: Text(column)))
            .toList(growable: false),
        rows: rows
            .map(
              (row) => DataRow(
                cells: columns
                    .map((column) => DataCell(Text('${row[column]}')))
                    .toList(growable: false),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

enum BiRange { last6, last12 }
