import 'package:cloud_functions/cloud_functions.dart';

/// Service responsible for triggering privileged Firebase project operations
/// via backend Cloud Functions or server-side APIs.
///
/// The actual project creation, configuration and rules deployment are
/// expected to be handled by trusted infrastructure (e.g. a callable Cloud
/// Function that wraps Firebase CLI commands). This client simply invokes
/// those endpoints and surfaces success or failure states.
class FirebaseProjectService {
  FirebaseProjectService._();

  static final FirebaseProjectService instance = FirebaseProjectService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> createFirebaseProject(String name) {
    return _callFunction('superadmin-createFirebaseProject', {
      'projectName': name,
    });
  }

  Future<String> generateFirebaseOptionsFile(String projectId) async {
    final result = await _callFunction('superadmin-generateFirebaseOptions', {
      'projectId': projectId,
    });
    return (result.data as Map?)?['content'] as String? ?? '';
  }

  Future<void> deployDefaultRules(String projectId) {
    return _callFunction('superadmin-deployDefaultRules', {
      'projectId': projectId,
    });
  }

  Future<HttpsCallableResult<dynamic>> _callFunction(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final callable = _functions.httpsCallable(name);
    return callable.call(payload);
  }
}
