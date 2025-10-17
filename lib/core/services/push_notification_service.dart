import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:atgevosystem/services/auth_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _requestPermission();
    await _messaging.setAutoInitEnabled(true);
    FirebaseMessaging.onMessage.listen((message) {
      // Future: integrate local notifications/snackbars if needed.
    });

    _initialized = true;
    await _subscribeToRoleTopics(AuthService.instance.currentUserRole);
  }

  Future<void> refreshRoleSubscriptions() async {
    await _subscribeToRoleTopics(AuthService.instance.currentUserRole);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _subscribeToRoleTopics(String? role) async {
    final normalizedRole = role?.toLowerCase();
    final topics = _topicsForRole(normalizedRole);
    final allTopics = {'sales', 'production', 'admin', 'superadmin'};

    for (final topic in allTopics) {
      if (topics.contains(topic)) {
        await _messaging.subscribeToTopic('role_$topic');
      } else {
        await _messaging.unsubscribeFromTopic('role_$topic');
      }
    }
  }

  Set<String> _topicsForRole(String? role) {
    switch (role) {
      case 'sales':
        return {'sales', 'admin'};
      case 'production':
        return {'production', 'admin'};
      case 'admin':
        return {'admin'};
      case 'superadmin':
        return {'sales', 'production', 'admin', 'superadmin'};
      default:
        return {'admin'};
    }
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // For now, we rely on the default FCM notification handlers.
  // This can be extended with local notification packages if needed.
}
