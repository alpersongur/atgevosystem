import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// SystemHealthService, altyapı bileşenlerinden sağlık metriklerini toplamak
/// için temel bir arayüz sunar.
class SystemHealthService {
  SystemHealthService._();

  static final SystemHealthService instance = SystemHealthService._();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  Map<String, dynamic>? _lastSnapshot;

  Map<String, dynamic>? get lastSnapshot => _lastSnapshot;

  Future<void> refreshMetrics() async {
    try {
      final callable = _functions.httpsCallable('getSystemMetrics');
      final response = await callable.call();
      _lastSnapshot =
          Map<String, dynamic>.from(response.data as Map? ?? const {});
    } catch (error, stackTrace) {
      debugPrint('Sistem metrikleri alınamadı: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
