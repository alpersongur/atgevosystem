import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';
import 'firebase_options_demo.dart' as demo_options;
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool useDemo = const bool.fromEnvironment('USE_DEMO', defaultValue: false);
  final firebaseOptions = useDemo
      ? demo_options.DefaultFirebaseOptions.currentPlatform
      : DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: firebaseOptions);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await AuthService.instance.initialize();
  await PushNotificationService.instance.initialize();
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (error) {
    debugPrint('Firestore persistence unavailable: $error');
  }
  debugPrint(
    'Connected to Firebase project: ${firebaseOptions.projectId} '
    '(${useDemo ? 'DEMO' : 'MAIN'})',
  );

  runApp(MyApp(useDemo: useDemo));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.useDemo});

  final bool useDemo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: useDemo ? 'ATG CRM (Demo)' : 'ATG CRM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: '/',
      builder: (context, child) {
        if (!useDemo || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return Banner(
          message: 'DEMO',
          location: BannerLocation.topStart,
          color: Colors.redAccent,
          child: child,
        );
      },
      routes: AppRouter.routes,
      onUnknownRoute: AppRouter.unknownRoute,
    );
  }
}
