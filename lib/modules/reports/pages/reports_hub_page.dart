import 'package:flutter/material.dart';

import '../../assistant/widgets/insight_card.dart';
import '../../assistant/services/assistant_service.dart';
import '../../assistant/models/assistant_query_model.dart';
import '../../tenant/services/tenant_service.dart';
import '../models/report_request_model.dart';
import '../services/report_service.dart';
import '../widgets/report_card.dart';
import 'report_filters_widget.dart';
import 'report_preview_page.dart';

class ReportsHubPage extends StatefulWidget {
  const ReportsHubPage({super.key});

  static const routeName = '/reports';

  @override
  State<ReportsHubPage> createState() => _ReportsHubPageState();
}

class _ReportsHubPageState extends State<ReportsHubPage> {
  ReportType? _selectedType;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  Map<String, dynamic> _extraFilters = const {};
  List<AssistantInsight> _insights = const [];

  final _cards = const [
    (
      ReportType.crmQuotesSummary,
      'CRM Teklif Özeti',
      'Müşteri ve aya göre teklif toplamları.',
    ),
    (
      ReportType.finInvoiceAging,
      'Finans - Fatura Yaşlandırma',
      'Ödenmeyen faturaların yaş dağılımı.',
    ),
    (
      ReportType.finSalesVsCollections,
      'Finans - Satış vs Tahsilat',
      'Aylık fatura vs tahsilat karşılaştırması.',
    ),
    (
      ReportType.prodOrdersByStatus,
      'Üretim - Sipariş Durumları',
      'Üretim emirlerinin statü dağılımı.',
    ),
    (
      ReportType.invLowStock,
      'Envanter - Düşük Stok',
      'Minimum stok altındaki ürün listesi.',
    ),
    (
      ReportType.purPurchaseOrdersAging,
      'Satınalma - PO Yaşlandırma',
      'Açık satınalma emirlerinin gecikme analizi.',
    ),
    (
      ReportType.shpDeliveriesMonthly,
      'Sevkiyat - Aylık Teslimatlar',
      'Aylık bazda teslimat sayısı.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final insights = await AssistantService.instance.fetchDashboardInsights();
    if (mounted) {
      setState(() => _insights = insights);
    }
  }

  void _handleFiltersChanged(ReportFilterResult result) {
    setState(() {
      _from = result.from;
      _to = result.to;
      _extraFilters = result.extra;
    });
  }

  Future<void> _openPreview() async {
    if (_selectedType == null) return;
    final companyId = TenantService.instance.activeTenantId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce aktif bir firma seçmelisiniz.')),
      );
      return;
    }
    final request = ReportRequest(
      companyId: companyId,
      type: _selectedType!,
      dateFrom: _from,
      dateTo: _to,
      filters: _extraFilters,
    );
    final report = await ReportService.instance.fetchReport(request);
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      ReportPreviewPage.routeName,
      arguments: {'request': request, 'data': report},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlama Merkezi')),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cards.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final (type, title, description) = _cards[index];
                return ReportCard(
                  type: type,
                  title: title,
                  description: description,
                  onSelect: () {
                    setState(() => _selectedType = type);
                    _openPreview();
                  },
                );
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportFiltersWidget(
                    initialFrom: _from,
                    initialTo: _to,
                    onChanged: _handleFiltersChanged,
                  ),
                  const SizedBox(height: 16),
                  if (_insights.isNotEmpty)
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _insights.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) => SizedBox(
                          width: 240,
                          child: InsightCard(insight: _insights[index]),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton.icon(
                      onPressed: _selectedType == null ? null : _openPreview,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Raporu Önizle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
