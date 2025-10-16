import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';
import 'core/auth_guard.dart';
import 'firebase_options.dart';
import 'firebase_options_demo.dart' as demo_options;
import 'modules/crm/pages/crm_dashboard_page.dart';
import 'modules/crm/pages/customer_detail_page.dart';
import 'modules/crm/pages/customer_edit_page.dart';
import 'modules/crm/pages/customer_list_page.dart';
import 'modules/crm/pages/lead_form_page.dart';
import 'modules/crm/pages/lead_list_page.dart';
import 'modules/crm/quotes/pages/quote_detail_page.dart';
import 'modules/crm/quotes/pages/quote_edit_page.dart';
import 'modules/crm/quotes/pages/quote_list_page.dart';
import 'modules/finance/pages/invoice_detail_page.dart';
import 'modules/finance/pages/invoice_edit_page.dart';
import 'modules/finance/pages/invoice_list_page.dart';
import 'modules/finance/pages/finance_dashboard_page.dart';
import 'modules/finance/pages/payment_detail_page.dart';
import 'modules/finance/pages/payment_edit_page.dart';
import 'modules/finance/pages/payment_list_page.dart';
import 'modules/production/pages/production_detail_page.dart';
import 'modules/production/pages/production_list_page.dart';
import 'modules/production/pages/production_dashboard_page.dart';
import 'modules/inventory/pages/inventory_list_page.dart';
import 'modules/inventory/pages/inventory_detail_page.dart';
import 'modules/shipment/pages/shipment_list_page.dart';
import 'modules/shipment/pages/shipment_detail_page.dart';
import 'modules/shipment/pages/shipment_edit_page.dart';
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
        '/admin/add-user': (context) =>
            const RoleGuard(allowedRoles: ['admin'], child: AddUserPage()),
        '/admin/permissions': (context) => const RoleGuard(
          allowedRoles: ['admin'],
          child: PermissionManagementPage(),
        ),
        '/crm/customers': (context) => const RoleGuard(
          allowedRoles: ['admin', 'sales'],
          child: CustomerListPage(),
        ),
        CustomerDetailPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final customerId = args is CustomerDetailPageArgs
              ? args.customerId
              : args is String
              ? args
              : null;
          if (customerId == null) {
            return const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: _RouteErrorPage(
                message: 'CustomerDetailPage için müşteri kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: ['admin', 'sales'],
            child: CustomerDetailPage(customerId: customerId),
          );
        },
        CustomerEditPage.createRoute: (context) => const RoleGuard(
          allowedRoles: ['admin', 'sales'],
          child: CustomerEditPage(),
        ),
        CustomerEditPage.editRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final customerId = args is CustomerEditPageArgs
              ? args.customerId
              : args is String
              ? args
              : null;
          if (customerId == null) {
            return const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: _RouteErrorPage(
                message: 'CustomerEditPage için müşteri kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: ['admin', 'sales'],
            child: CustomerEditPage(customerId: customerId),
          );
        },
        QuoteListPage.routeName: (context) => const RoleGuard(
          allowedRoles: ['admin', 'sales'],
          child: QuoteListPage(),
        ),
        QuoteDetailPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final quoteId = args is QuoteDetailPageArgs
              ? args.quoteId
              : args is String
              ? args
              : null;
          if (quoteId == null) {
            return const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: _RouteErrorPage(
                message: 'QuoteDetailPage için teklif kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: ['admin', 'sales'],
            child: QuoteDetailPage(quoteId: quoteId),
          );
        },
        QuoteEditPage.createRoute: (context) => const RoleGuard(
          allowedRoles: ['admin', 'sales'],
          child: QuoteEditPage(),
        ),
        QuoteEditPage.editRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final quoteId = args is QuoteEditPageArgs
              ? args.quoteId
              : args is String
              ? args
              : null;
          if (quoteId == null) {
            return const RoleGuard(
              allowedRoles: ['admin', 'sales'],
              child: _RouteErrorPage(
                message: 'QuoteEditPage için teklif kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: ['admin', 'sales'],
            child: QuoteEditPage(quoteId: quoteId),
          );
        },
        ProductionListPage.routeName: (context) => const RoleGuard(
          allowedRoles: ['admin', 'sales', 'production'],
          child: ProductionListPage(),
        ),
        ProductionDashboardPage.routeName: (context) => const RoleGuard(
          allowedRoles: ['admin', 'sales', 'production'],
          child: ProductionDashboardPage(),
        ),
        ProductionDetailPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final orderId = args is ProductionDetailPageArgs
              ? args.orderId
              : args is String
              ? args
              : null;
          if (orderId == null) {
            return const RoleGuard(
              allowedRoles: ['admin', 'sales', 'production'],
              child: _RouteErrorPage(
                message: 'ProductionDetailPage için talimat kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: ['admin', 'sales', 'production'],
            child: ProductionDetailPage(orderId: orderId),
          );
        },
        InventoryListPage.routeName: (context) => const RoleGuard(
          allowedRoles: ['admin', 'sales', 'production', 'warehouse'],
          child: InventoryListPage(),
        ),
        InventoryDetailPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final itemId = args is InventoryDetailPageArgs
              ? args.itemId
              : args is String
              ? args
              : null;
          if (itemId == null) {
            return const RoleGuard(
              allowedRoles: ['admin', 'sales', 'production', 'warehouse'],
              child: _RouteErrorPage(
                message: 'InventoryDetailPage için kayıt kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: ['admin', 'sales', 'production', 'warehouse'],
            child: InventoryDetailPage(itemId: itemId),
          );
        },
        ShipmentListPage.routeName: (context) => const RoleGuard(
          allowedRoles: [
            'admin',
            'sales',
            'production',
            'warehouse',
            'logistics',
          ],
          child: ShipmentListPage(),
        ),
        ShipmentDetailPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final shipmentId = args is ShipmentDetailPageArgs
              ? args.shipmentId
              : args is String
              ? args
              : null;
          if (shipmentId == null) {
            return const RoleGuard(
              allowedRoles: [
                'admin',
                'sales',
                'production',
                'warehouse',
                'logistics',
              ],
              child: _RouteErrorPage(
                message: 'ShipmentDetailPage için sevkiyat kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: [
              'admin',
              'sales',
              'production',
              'warehouse',
              'logistics',
            ],
            child: ShipmentDetailPage(shipmentId: shipmentId),
          );
        },
        ShipmentEditPage.routeName: (context) => const RoleGuard(
          allowedRoles: [
            'admin',
            'sales',
            'production',
            'warehouse',
            'logistics',
          ],
          child: ShipmentEditPage(),
        ),
        InvoiceListPage.routeName: (context) => const RoleGuard(
          allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
          child: InvoiceListPage(),
        ),
        InvoiceDetailPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final invoiceId = args is InvoiceDetailPageArgs
              ? args.invoiceId
              : args is String
              ? args
              : null;
          if (invoiceId == null) {
            return const RoleGuard(
              allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
              child: _RouteErrorPage(
                message: 'InvoiceDetailPage için fatura kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
            child: InvoiceDetailPage(invoiceId: invoiceId),
          );
        },
        InvoiceEditPage.createRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final editArgs = args is InvoiceEditPageArgs ? args : null;
          return RoleGuard(
            allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
            child: InvoiceEditPage(
              invoiceId: editArgs?.invoiceId,
              args: editArgs,
            ),
          );
        },
        PaymentListPage.routeName: (context) => const RoleGuard(
          allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
          child: PaymentListPage(),
        ),
        PaymentDetailPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final paymentId = args is PaymentDetailPageArgs
              ? args.paymentId
              : args is String
              ? args
              : null;
          if (paymentId == null) {
            return const RoleGuard(
              allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
              child: _RouteErrorPage(
                message: 'PaymentDetailPage için tahsilat kimliği gerekli.',
              ),
            );
          }
          return RoleGuard(
            allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
            child: PaymentDetailPage(paymentId: paymentId),
          );
        },
        PaymentEditPage.createRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final editArgs = args is PaymentEditPageArgs ? args : null;
          return RoleGuard(
            allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
            child: PaymentEditPage(
              paymentId: editArgs?.paymentId,
              args: editArgs,
            ),
          );
        },
        FinanceDashboardPage.routeName: (context) => const RoleGuard(
          allowedRoles: ['admin', 'superadmin', 'accounting'],
          child: FinanceDashboardPage(),
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

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yönlendirme Hatası')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
