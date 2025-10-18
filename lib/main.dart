import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'core/localization/tr_strings.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';
import 'firebase_options_demo.dart' as demo_options;
import 'modules/tenant/models/tenant_model.dart';
import 'modules/tenant/services/tenant_service.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tenantService = TenantService.instance;
  await tenantService.initialize();
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';
  bool useDemo = const bool.fromEnvironment('USE_DEMO', defaultValue: false);
  final firebaseOptions = useDemo
      ? demo_options.DefaultFirebaseOptions.currentPlatform
      : DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: firebaseOptions);
  await tenantService.ensureTenantAppInitialized();
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

  runApp(MyApp(useDemo: useDemo, tenantService: tenantService));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.useDemo, TenantService? tenantService})
      : tenantService = tenantService ?? TenantService.instance;

  final bool useDemo;
  final TenantService tenantService;

  @override
  Widget build(BuildContext context) {
    return StreamProvider<TenantModel?>.value(
      value: tenantService.activeTenantStream,
      initialData: tenantService.activeTenant,
      child: MaterialApp(
        title: useDemo ? tr['app_name_demo']! : tr['app_name']!,
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
      ),
    );
  }
}
