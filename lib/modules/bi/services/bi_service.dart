import 'package:cloud_functions/cloud_functions.dart';

import '../../tenant/services/tenant_service.dart';

class BiService {
  BiService._();

  static final BiService instance = BiService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<List<Map<String, dynamic>>> queryBQ(
    String sql, {
    Map<String, dynamic> params = const {},
  }) async {
    final tenantId = TenantService.instance.activeTenantId;
    if (tenantId == null) {
      throw StateError('Aktif firma seçilmeden BI sorgusu çalıştırılamaz.');
    }

    final callable = _functions.httpsCallable('runBQQuery');
    final response = await callable.call(<String, dynamic>{
      'sql': sql,
      'params': params,
      'company_id': tenantId,
    });

    final data = response.data as Map<String, dynamic>?;
    final rows = data?['rows'];
    if (rows is List) {
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }
}
