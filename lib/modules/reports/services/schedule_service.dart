import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/report_request_model.dart';

class ScheduleService {
  ScheduleService._();

  static final ScheduleService instance = ScheduleService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> requestImmediateReport({
    required String companyId,
    required ReportType reportType,
    required String format,
    required List<String> emails,
    Map<String, dynamic>? filters,
  }) async {
    final callable = _functions.httpsCallable('requestImmediateReport');
    await callable.call({
      'company_id': companyId,
      'report_type': reportType.name,
      'format': format,
      'emails': emails,
      'filters': filters ?? <String, dynamic>{},
    });
  }

  Future<void> createSchedule({
    required String companyId,
    required ReportType reportType,
    required String format,
    required String frequency,
    int? dayOfWeek,
    String time = '06:00',
    List<String> emails = const [],
    Map<String, dynamic>? filters,
  }) {
    final collection = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('report_schedules');
    return collection.add({
      'report_type': reportType.name,
      'format': format,
      'frequency': frequency,
      'dayOfWeek': dayOfWeek,
      'time': time,
      'emails': emails,
      'filters': filters ?? <String, dynamic>{},
      'active': true,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
