import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../tenant/services/tenant_service.dart';
import '../models/qa_run_model.dart';
import 'coverage_parser.dart';

class QaService {
  QaService._();

  static final QaService instance = QaService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _qaCollection =>
      _firestore.collection('qa_runs');

  Stream<List<QaRunModel>> recentRuns({int limit = 20}) {
    final companyId = TenantService.instance.activeTenantId;
    if (companyId == null) {
      return const Stream.empty();
    }
    return _qaCollection
        .where('company_id', isEqualTo: companyId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(QaRunModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  Future<void> ingestRun({
    required String companyId,
    required QaRunModel run,
  }) async {
    final callable = _functions.httpsCallable('ingestQaRun');
    await callable.call({
      'company_id': companyId,
      'source': run.source.name.toUpperCase(),
      'status': run.status.name,
      'total': run.total,
      'passed': run.passed,
      'failed': run.failed,
      'skipped': run.skipped,
      'coveragePct': run.coveragePct,
      'durationSec': run.durationSec,
      'artifacts': run.artifacts,
      'failures': run.failures,
      'created_at': run.createdAt.toIso8601String(),
    });
  }

  Future<void> addLocalRun({
    required String companyId,
    required QaRunModel run,
  }) async {
    await ingestRun(companyId: companyId, run: run);
  }

  Future<double?> parseCoverageFromLcov(List<int> bytes) async {
    return CoverageParser.parseLcov(bytes);
  }

  Future<QaRunModel?> fetchRun(String id) async {
    final companyId = TenantService.instance.activeTenantId;
    if (companyId == null) return null;
    final doc = await _qaCollection.doc(id).get();
    if (!doc.exists) return null;
    final run = QaRunModel.fromSnapshot(doc);
    if (run.companyId != companyId) return null;
    return run;
  }

  Future<Map<String, double>> computeKpis(List<QaRunModel> runs) async {
    if (runs.isEmpty) {
      return const {'coverage': 0.0, 'passRate': 0.0};
    }
    final last = runs.first;
    final coverage = last.coveragePct;
    final total = runs
        .map((run) => run.total)
        .fold<int>(0, (previous, element) => previous + element);
    final passed = runs
        .map((run) => run.passed)
        .fold<int>(0, (previous, element) => previous + element);
    final passRate = total == 0 ? 0.0 : (passed / total) * 100;
    return {'coverage': coverage, 'passRate': passRate};
  }

  double coverageThreshold(List<QaRunModel> runs) {
    if (runs.isEmpty) return 0;
    return runs.first.coveragePct;
  }
}
