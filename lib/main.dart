import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';
import 'core/auth_guard.dart';
import 'firebase_options.dart';
import 'firebase_options_demo.dart' as demo_options;
import 'modules/crm/pages/add_customer_page.dart';
import 'modules/crm/pages/crm_dashboard.dart';
import 'modules/crm/pages/customer_list_page.dart';
import 'modules/crm/pages/lead_form_page.dart';
import 'modules/crm/pages/lead_list_page.dart';
import 'modules/admin/pages/add_user_page.dart';
import 'modules/admin/pages/user_management_page.dart';
import 'modules/admin/pages/permission_management_page.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool useDemo = const bool.fromEnvironment('USE_DEMO', defaultValue: false);
  final firebaseOptions = useDemo
      ? demo_options.DefaultFirebaseOptions.currentPlatform
      : DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: firebaseOptions);
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
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
        '/admin/users': (context) => const RoleGuard(
              allowedRoles: ['admin'],
              child: UserManagementPage(),
            ),
        '/admin/add-user': (context) => const RoleGuard(
              allowedRoles: ['admin'],
              child: AddUserPage(),
            ),
        '/admin/permissions': (context) => const RoleGuard(
              allowedRoles: ['admin'],
              child: PermissionManagementPage(),
            ),
        CustomersListPage.routeName: (context) => const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: CustomersListPage(),
            ),
        '/crm/customers': (context) => const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: CustomersListPage(),
            ),
        AddCustomerPage.routeName: (context) => const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: AddCustomerPage(),
            ),
        LeadListPage.routeName: (context) => const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: LeadListPage(),
            ),
        LeadFormPage.routeName: (context) => const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: LeadFormPage(),
            ),
        CrmDashboardPage.routeName: (context) => const RoleGuard(
              allowedRoles: ['admin', 'sales', 'production', 'accounting'],
              child: CrmDashboardPage(),
            ),
      },
    );
  }
}
