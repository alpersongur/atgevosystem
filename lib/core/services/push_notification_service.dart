import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:atgevosystem/core/models/user_profile.dart';
import 'package:atgevosystem/core/services/auth_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  bool _messagingSupported = true;
  StreamSubscription<UserProfileState?>? _profileSubscription;
  String? _lastSyncedRole;

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      try {
        _messagingSupported = await _messaging.isSupported();
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to check Firebase Messaging support on web: $error\n$stackTrace',
        );
        _messagingSupported = false;
      }
      if (!_messagingSupported) {
        debugPrint(
          'Firebase Messaging is not supported in this browser. Skipping push notification setup.',
        );
        _initialized = true;
        return;
      }
    } else {
      await _requestPermission();
    }

    _initialized = true;
    await _messaging.setAutoInitEnabled(true);
    FirebaseMessaging.onMessage.listen((message) {
      // Future: integrate local notifications/snackbars if needed.
    });

    _profileSubscription ??= AuthService.instance.profileStream.listen((
      profile,
    ) {
      if (!_initialized || !_messagingSupported) return;
      if (profile == null) return;
      if (_lastSyncedRole == profile.role) return;
      _lastSyncedRole = profile.role;
      unawaited(_subscribeToRoleTopics(profile));
    });

    await _subscribeToRoleTopics(AuthService.instance.currentProfile);
  }

  Future<void> refreshRoleSubscriptions() async {
    await _subscribeToRoleTopics(AuthService.instance.currentProfile);
  }

  Future<bool> requestPermissionFromUserGesture() async {
    final settings = await _requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (granted) {
      await _messaging.setAutoInitEnabled(true);
      await _subscribeToRoleTopics(AuthService.instance.currentProfile);
    }
    return granted;
  }

  Future<NotificationSettings> _requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _subscribeToRoleTopics(UserProfileState? profile) async {
    if (!_messagingSupported) {
      return;
    }

    if (kIsWeb) {
      debugPrint(
        'Firebase Messaging topic subscriptions are not supported on web. Skipping role topic sync.',
      );
      return;
    }

    final normalizedRole = profile?.role?.toLowerCase();
    final topics = _topicsForRole(normalizedRole);
    final allTopics = {'sales', 'production', 'admin', 'superadmin'};

    for (final topic in allTopics) {
      try {
        if (topics.contains(topic)) {
          await _messaging.subscribeToTopic('role_$topic');
        } else {
          await _messaging.unsubscribeFromTopic('role_$topic');
        }
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to update Firebase Messaging topic "$topic": $error\n$stackTrace',
        );
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
