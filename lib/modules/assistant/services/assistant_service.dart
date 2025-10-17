import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/auth_service.dart';
import '../../../modules/ai/services/analytics_service.dart';
import '../../tenant/services/tenant_service.dart';
import '../models/assistant_query_model.dart';

class AssistantService {
  AssistantService._();

  static final AssistantService instance = AssistantService._();

  final AnalyticsService _analyticsService = AnalyticsService.instance;

  FirebaseFirestore get _firestore => TenantService.instance.firestore;

  Future<AssistantResponse> processQuery(
    String question, {
    String? userId,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return const AssistantResponse(
        answer: 'Bir soru yazın, size yardımcı olayım.',
        suggestions: <String>['Örnek: Bu ay kaç yeni müşteri ekledik?'],
      );
    }

    final normalized = trimmed.toLowerCase();
    final tenantId = TenantService.instance.activeTenantId;
    if (tenantId == null) {
      return const AssistantResponse(
        answer: 'Lütfen önce aktif bir firma seçin, ardından tekrar deneyin.',
      );
    }

    String intent = 'general';
    String answer;
    final List<String> suggestions = <String>[];
    final List<AssistantQuickAction> quickActions = <AssistantQuickAction>[];

    if (normalized.contains('müşteri')) {
      intent = 'crm';
      final result = await _handleCustomerQuery(normalized, tenantId);
      answer = result.answer;
      suggestions.addAll(result.suggestions);
      quickActions.add(
        const AssistantQuickAction(
          label: 'CRM Kontrol Paneli',
          payload: '/crm/dashboard',
          type: AssistantQuickActionType.navigation,
        ),
      );
    } else if (normalized.contains('satış') ||
        normalized.contains('ciro') ||
        normalized.contains('gelir')) {
      intent = 'finance';
      final result = await _handleSalesQuery(normalized, tenantId);
      answer = result.answer;
      suggestions.addAll(result.suggestions);
      quickActions.add(
        const AssistantQuickAction(
          label: 'Finans Kontrol Paneli',
          payload: '/finance/dashboard',
          type: AssistantQuickActionType.navigation,
        ),
      );
    } else if (normalized.contains('stok') || normalized.contains('envanter')) {
      intent = 'inventory';
      final result = await _handleInventoryQuery(normalized, tenantId);
      answer = result.answer;
      suggestions.addAll(result.suggestions);
      quickActions.add(
        const AssistantQuickAction(
          label: 'Envanteri Görüntüle',
          payload: '/inventory',
          type: AssistantQuickActionType.navigation,
        ),
      );
    } else if (normalized.contains('tahsil') || normalized.contains('ödeme')) {
      intent = 'collection';
      final result = await _handleCollectionQuery(normalized, tenantId);
      answer = result.answer;
      suggestions.addAll(result.suggestions);
      quickActions.add(
        const AssistantQuickAction(
          label: 'Tahsilat Listesi',
          payload: '/finance/payments',
          type: AssistantQuickActionType.navigation,
        ),
      );
    } else {
      final insight = await _generateGeneralInsight(tenantId);
      answer = insight.answer;
      suggestions.addAll(insight.suggestions);
    }

    final response = AssistantResponse(
      answer: answer,
      intent: intent,
      suggestions: suggestions,
      quickActions: quickActions,
    );

    await _logInteraction(
      tenantId: tenantId,
      question: trimmed,
      response: response,
      userId: userId ?? AuthService.instance.currentUser?.uid,
    );

    return response;
  }

  Future<List<AssistantInsight>> fetchDashboardInsights() async {
    final tenantId = TenantService.instance.activeTenantId;
    if (tenantId == null) {
      return const <AssistantInsight>[
        AssistantInsight(
          title: 'Aktif firma seçilmedi',
          description:
              'Lütfen sol üstten firma seçerek yapay zeka önerilerini görün.',
        ),
      ];
    }

    final analytics = await _analyticsService.loadAnalytics(months: 6);
    final insights = <AssistantInsight>[];

    final salesGrowth = analytics.salesForecast.nextMonthEstimate;
    if (salesGrowth > 0) {
      insights.add(
        AssistantInsight(
          title: 'Satış Tahmini',
          description:
              'Gelecek ay için tahmini satış tutarı ${salesGrowth.toStringAsFixed(0)} ₺ seviyesinde.',
          trendText: 'Pozitif trend',
          trendUp: true,
        ),
      );
    }

    final productionForecast = analytics.productionForecast.forecast;
    if (productionForecast.isNotEmpty) {
      final nextPeriod = productionForecast.first;
      insights.add(
        AssistantInsight(
          title: 'Üretim Yükü',
          description:
              '${_formatMonth(nextPeriod.period)} için ${nextPeriod.value.toStringAsFixed(0)} üretim emri bekleniyor.',
          trendUp:
              nextPeriod.value >=
              (analytics.productionForecast.history.isEmpty
                  ? nextPeriod.value
                  : analytics.productionForecast.history.last.value),
        ),
      );
    }

    final inventoryRisk = analytics.inventoryRisk;
    if (inventoryRisk.hasRisk) {
      final itemName = inventoryRisk.highRiskItemId ?? 'belirsiz ürün';
      insights.add(
        AssistantInsight(
          title: 'Kritik Stok Uyarısı',
          description:
              '$itemName için stok ${inventoryRisk.remainingQuantity.toStringAsFixed(0)} seviyesine düştü. Minimum stok ${inventoryRisk.minStock.toStringAsFixed(0)}.',
          trendText: inventoryRisk.riskScore >= 0.5
              ? 'Yüksek risk'
              : 'Orta risk',
          trendUp: false,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const AssistantInsight(
          title: 'Veri bulunamadı',
          description:
              'Yeterli veri olmadığı için öneri oluşturulamadı. Güncel kayıt eklemeyi deneyin.',
        ),
      );
    }

    return insights;
  }

  Future<void> _logInteraction({
    required String tenantId,
    required String question,
    required AssistantResponse response,
    String? userId,
  }) async {
    try {
      await _firestore.collection('assistant_logs').add({
        'company_id': tenantId,
        'user_id': userId,
        'question': question,
        'answer': response.answer,
        'intent': response.intent,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // log storing is best-effort
    }
  }

  Stream<List<AssistantLogEntry>> watchRecentLogs({int limit = 10}) {
    final tenantId = TenantService.instance.activeTenantId;
    Query<Map<String, dynamic>> query = _firestore
        .collection('assistant_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (tenantId != null) {
      query = query.where('company_id', isEqualTo: tenantId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(AssistantLogEntry.fromSnapshot)
          .toList(growable: false),
    );
  }

  Future<_QueryResult> _handleCustomerQuery(
    String normalized,
    String tenantId,
  ) async {
    final now = DateTime.now();
    DateTime from = DateTime(now.year, now.month, 1);
    DateTime to = now;
    String periodLabel = 'Bu ay';

    if (normalized.contains('geçen ay')) {
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      from = previousMonth;
      to = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
      periodLabel = 'Geçen ay';
    } else if (normalized.contains('hafta')) {
      from = now.subtract(const Duration(days: 7));
      periodLabel = 'Son 7 gün';
    }

    final count = await _countDocuments(
      tenantId,
      collectionPath: 'customers',
      dateField: 'created_at',
      from: from,
      to: to,
    );

    final answer =
        '$periodLabel toplamda $count yeni müşteri kaydı tamamlandı.';
    final suggestions = <String>[
      'Detaylı müşteri listesi için CRM modülünü inceleyebilirsiniz.',
    ];

    return _QueryResult(answer: answer, suggestions: suggestions);
  }

  Future<_QueryResult> _handleSalesQuery(
    String normalized,
    String tenantId,
  ) async {
    final now = DateTime.now();
    DateTime from = DateTime(now.year, now.month, 1);
    DateTime to = now;
    String periodLabel = 'Bu ay';

    if (normalized.contains('geçen ay')) {
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      from = previousMonth;
      to = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
      periodLabel = 'Geçen ay';
    } else if (normalized.contains('bu yıl')) {
      from = DateTime(now.year, 1, 1);
      periodLabel = 'Bu yıl';
    }

    final revenue = await _sumDocuments(
      tenantId,
      collectionPath: 'invoices',
      amountField: 'amount',
      alternativeFields: const ['total', 'grand_total'],
      dateField: 'created_at',
      from: from,
      to: to,
    );

    final count = await _countDocuments(
      tenantId,
      collectionPath: 'quotes',
      dateField: 'created_at',
      from: from,
      to: to,
    );

    final answer =
        '$periodLabel toplam ciro yaklaşık ${_formatCurrency(revenue)} ve aynı dönemde $count satış/teklif kaydı oluşturuldu.';
    final suggestions = <String>[
      'Finans modülünden faturaların detayını inceleyebilirsiniz.',
    ];

    return _QueryResult(answer: answer, suggestions: suggestions);
  }

  Future<_QueryResult> _handleInventoryQuery(
    String normalized,
    String tenantId,
  ) async {
    final snapshot = await _collection(
      tenantId,
      'inventory',
    ).orderBy('quantity', descending: false).limit(5).get();
    final lowStock = snapshot.docs
        .where((doc) {
          final data = doc.data();
          final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
          return quantity < 10;
        })
        .map((doc) => doc.data()['name'] ?? doc.id)
        .take(5)
        .toList();

    final answer = lowStock.isEmpty
        ? 'Stok seviyeleri kritik görünmüyor. Düzenli olarak kontrol etmeye devam edin.'
        : 'Kritik stok seviyesindeki ürünler: ${lowStock.join(', ')}.';
    final suggestions = <String>[
      'Depo ekibine bilgilendirme göndermeyi düşünebilirsiniz.',
    ];

    return _QueryResult(answer: answer, suggestions: suggestions);
  }

  Future<_QueryResult> _handleCollectionQuery(
    String normalized,
    String tenantId,
  ) async {
    final now = DateTime.now();
    DateTime from = DateTime(now.year, now.month, 1);
    if (normalized.contains('geçen ay')) {
      from = DateTime(now.year, now.month - 1, 1);
    }

    final paid = await _sumDocuments(
      tenantId,
      collectionPath: 'payments',
      amountField: 'amount',
      alternativeFields: const ['paid_amount'],
      dateField: 'payment_date',
      from: from,
      to: now,
    );

    final answer =
        '${_formatDateRange(from, now)} döneminde tahsilat toplamı ${_formatCurrency(paid)}.';
    final suggestions = <String>[
      'Geciken tahsilatlar için finans ekibiyle takip yapılabilir.',
    ];

    return _QueryResult(answer: answer, suggestions: suggestions);
  }

  Future<_QueryResult> _generateGeneralInsight(String tenantId) async {
    final insights = await fetchDashboardInsights();
    if (insights.isEmpty) {
      return const _QueryResult(
        answer:
            'Şu anda paylaşabileceğim bir içgörü bulunmuyor. Daha fazla veri ekledikçe öneriler sunacağım.',
        suggestions: <String>[],
      );
    }

    final topInsight = insights.first;
    final answer =
        '${topInsight.title}: ${topInsight.description}${topInsight.trendText != null ? ' (${topInsight.trendText})' : ''}';

    return _QueryResult(
      answer: answer,
      suggestions: const [
        'Detaylı bilgi için yönetim panelindeki AI önerilerini inceleyebilirsiniz.',
      ],
    );
  }

  Future<int> _countDocuments(
    String tenantId, {
    required String collectionPath,
    required String dateField,
    required DateTime from,
    required DateTime to,
  }) async {
    final collection = _collection(tenantId, collectionPath);
    try {
      final snapshot = await collection
          .where(dateField, isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where(dateField, isLessThanOrEqualTo: Timestamp.fromDate(to))
          .get();
      return snapshot.size;
    } catch (_) {
      final fallback = await collection.get();
      return fallback.docs.where((doc) {
        final timestamp = _toDate(doc.data()[dateField]);
        if (timestamp == null) return false;
        return !timestamp.isBefore(from) && !timestamp.isAfter(to);
      }).length;
    }
  }

  Future<double> _sumDocuments(
    String tenantId, {
    required String collectionPath,
    required String amountField,
    required List<String> alternativeFields,
    required String dateField,
    required DateTime from,
    required DateTime to,
  }) async {
    final collection = _collection(tenantId, collectionPath);
    final snapshot = await collection
        .where(dateField, isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where(dateField, isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
    if (snapshot.docs.isEmpty) {
      final fallback = await collection.get();
      return fallback.docs
          .map(
            (doc) => _extractAmount(
              doc.data(),
              amountField,
              alternativeFields,
              dateField,
              from,
              to,
            ),
          )
          .fold<double>(0, (previous, value) => previous + value);
    }
    return snapshot.docs
        .map(
          (doc) => _extractAmount(
            doc.data(),
            amountField,
            alternativeFields,
            dateField,
            from,
            to,
          ),
        )
        .fold<double>(0, (previous, value) => previous + value);
  }

  double _extractAmount(
    Map<String, dynamic> data,
    String amountField,
    List<String> alternatives,
    String dateField,
    DateTime from,
    DateTime to,
  ) {
    final timestamp = _toDate(data[dateField]);
    if (timestamp == null ||
        timestamp.isBefore(from) ||
        timestamp.isAfter(to)) {
      return 0;
    }
    final value =
        data[amountField] ??
        alternatives
            .map((field) => data[field])
            .firstWhere((element) => element != null, orElse: () => 0);
    return (value as num?)?.toDouble() ?? 0.0;
  }

  CollectionReference<Map<String, dynamic>> _collection(
    String tenantId,
    String path,
  ) {
    try {
      return TenantService.instance.tenantCollection(path);
    } catch (_) {
      return _firestore.collection('companies').doc(tenantId).collection(path);
    }
  }

  String _formatCurrency(double value) {
    if (value == 0) return '0 ₺';
    final suffixes = ['₺', 'K ₺', 'M ₺', 'B ₺'];
    int i = 0;
    double scaled = value;
    while (scaled.abs() >= 1000 && i < suffixes.length - 1) {
      scaled /= 1000;
      i++;
    }
    return '${scaled.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDateRange(DateTime from, DateTime to) {
    return '${_formatDate(from)} - ${_formatDate(to)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatMonth(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _QueryResult {
  const _QueryResult({required this.answer, required this.suggestions});

  final String answer;
  final List<String> suggestions;
}
