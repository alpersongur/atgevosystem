import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum QaRunSource { ci, local }

enum QaRunStatus { success, fail }

class QaRunModel extends Equatable {
  const QaRunModel({
    required this.id,
    required this.companyId,
    required this.source,
    required this.status,
    required this.total,
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.coveragePct,
    required this.durationSec,
    required this.createdAt,
    this.artifacts = const <String, dynamic>{},
    this.failures = const <String>[],
  });

  final String id;
  final String companyId;
  final QaRunSource source;
  final QaRunStatus status;
  final int total;
  final int passed;
  final int failed;
  final int skipped;
  final double coveragePct;
  final int durationSec;
  final DateTime createdAt;
  final Map<String, dynamic> artifacts;
  final List<String> failures;

  bool get hasFailures => failed > 0 || failures.isNotEmpty;

  factory QaRunModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return QaRunModel(
      id: snap.id,
      companyId: data['company_id'] as String? ?? '',
      source: _parseSource(data['source'] as String? ?? 'CI'),
      status: _parseStatus(data['status'] as String? ?? 'success'),
      total: (data['total'] as num?)?.toInt() ?? 0,
      passed: (data['passed'] as num?)?.toInt() ?? 0,
      failed: (data['failed'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      coveragePct: (data['coveragePct'] as num?)?.toDouble() ?? 0,
      durationSec: (data['durationSec'] as num?)?.toInt() ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      artifacts: Map<String, dynamic>.from(data['artifacts'] as Map? ?? {}),
      failures:
          (data['failures'] as List?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  QaRunModel copyWith({
    String? id,
    String? companyId,
    QaRunSource? source,
    QaRunStatus? status,
    int? total,
    int? passed,
    int? failed,
    int? skipped,
    double? coveragePct,
    int? durationSec,
    DateTime? createdAt,
    Map<String, dynamic>? artifacts,
    List<String>? failures,
  }) {
    return QaRunModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      source: source ?? this.source,
      status: status ?? this.status,
      total: total ?? this.total,
      passed: passed ?? this.passed,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
      coveragePct: coveragePct ?? this.coveragePct,
      durationSec: durationSec ?? this.durationSec,
      createdAt: createdAt ?? this.createdAt,
      artifacts: artifacts ?? this.artifacts,
      failures: failures ?? this.failures,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'source': source.name.toUpperCase(),
      'status': status.name,
      'total': total,
      'passed': passed,
      'failed': failed,
      'skipped': skipped,
      'coveragePct': coveragePct,
      'durationSec': durationSec,
      'created_at': createdAt,
      'artifacts': artifacts,
      'failures': failures,
    };
  }

  static QaRunSource _parseSource(String value) {
    switch (value.toUpperCase()) {
      case 'LOCAL':
        return QaRunSource.local;
      default:
        return QaRunSource.ci;
    }
  }

  static QaRunStatus _parseStatus(String value) {
    switch (value.toLowerCase()) {
      case 'fail':
        return QaRunStatus.fail;
      default:
        return QaRunStatus.success;
    }
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    source,
    status,
    total,
    passed,
    failed,
    skipped,
    coveragePct,
    durationSec,
    createdAt,
  ];
}
