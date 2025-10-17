import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';
import 'core/auth_guard.dart';
import 'modules/admin/pages/admin_dashboard_page.dart';
import 'modules/admin/pages/module_access_page.dart';
import 'modules/admin/pages/permission_management_page.dart';
import 'modules/admin/pages/role_list_page.dart';
import 'modules/admin/pages/system_settings_page.dart';
import 'modules/admin/pages/user_edit_page.dart';
import 'modules/admin/pages/user_list_page.dart';
import 'modules/admin/pages/api_keys_page.dart';
import 'modules/ai/pages/predictive_dashboard_page.dart';
import 'modules/crm/pages/crm_dashboard_page.dart';
import 'modules/crm/pages/customer_detail_page.dart';
import 'modules/crm/pages/customer_edit_page.dart';
import 'modules/crm/pages/customer_list_page.dart';
import 'modules/crm/pages/lead_form_page.dart';
import 'modules/crm/pages/lead_list_page.dart';
import 'modules/crm/quotes/pages/quote_detail_page.dart';
import 'modules/crm/quotes/pages/quote_edit_page.dart';
import 'modules/crm/quotes/pages/quote_list_page.dart';
import 'modules/dashboard/pages/notification_list_page.dart';
import 'modules/dashboard/pages/system_dashboard_page.dart';
import 'modules/finance/pages/finance_dashboard_page.dart';
import 'modules/finance/pages/invoice_detail_page.dart';
import 'modules/finance/pages/invoice_edit_page.dart';
import 'modules/finance/pages/invoice_list_page.dart';
import 'modules/finance/pages/payment_detail_page.dart';
import 'modules/finance/pages/payment_edit_page.dart';
import 'modules/finance/pages/payment_list_page.dart';
import 'modules/inventory/pages/inventory_detail_page.dart';
import 'modules/inventory/pages/inventory_list_page.dart';
import 'modules/monitoring/pages/monitoring_dashboard_page.dart';
import 'modules/production/pages/production_dashboard_page.dart';
import 'modules/production/pages/production_detail_page.dart';
import 'modules/production/pages/production_list_page.dart';
import 'modules/purchasing/pages/bill_list_page.dart';
import 'modules/purchasing/pages/grn_list_page.dart';
import 'modules/purchasing/pages/po_list_page.dart';
import 'modules/purchasing/pages/purchasing_dashboard_page.dart';
import 'modules/purchasing/pages/supplier_list_page.dart';
import 'modules/shipment/pages/shipment_detail_page.dart';
import 'modules/shipment/pages/shipment_edit_page.dart';
import 'modules/shipment/pages/shipment_list_page.dart';
import 'modules/tenant/models/tenant_model.dart';
import 'modules/tenant/pages/tenant_detail_page.dart';
import 'modules/tenant/pages/tenant_edit_page.dart';
import 'modules/tenant/pages/tenant_list_page.dart';
import 'modules/licensing/pages/license_detail_page.dart';
import 'modules/licensing/pages/license_edit_page.dart';
import 'modules/licensing/pages/license_list_page.dart';
import 'modules/licensing/pages/license_management_page.dart';
import 'modules/assistant/pages/assistant_dashboard_page.dart';
import 'modules/assistant/pages/assistant_chat_page.dart';
import 'modules/bi/pages/bi_dashboard_page.dart';
import 'modules/reports/models/report_request_model.dart';
import 'modules/reports/pages/reports_hub_page.dart';
import 'modules/reports/pages/report_preview_page.dart';
import 'modules/qa/pages/qa_dashboard_page.dart';
import 'modules/qa/pages/qa_run_detail_page.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';

class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> routes = {
    '/': (_) => const AuthGate(),
    LoginPage.routeName: (_) => const LoginPage(),
    MainPage.routeName: (_) => const MainPage(),
    AdminDashboardPage.routeName: (_) =>
        const SuperAdminGuard(child: AdminDashboardPage()),
    UserListPage.routeName: (_) => const SuperAdminGuard(child: UserListPage()),
    UserEditPage.routeName: (_) => const SuperAdminGuard(child: UserEditPage()),
    PermissionManagementPage.routeName: (_) =>
        const SuperAdminGuard(child: PermissionManagementPage()),
    ModuleAccessPage.routeName: (_) =>
        const SuperAdminGuard(child: ModuleAccessPage()),
    RoleListPage.routeName: (_) => const SuperAdminGuard(child: RoleListPage()),
    SystemSettingsPage.routeName: (_) =>
        const SuperAdminGuard(child: SystemSettingsPage()),
    ApiKeysPage.routeName: (_) => const SuperAdminGuard(child: ApiKeysPage()),
    TenantListPage.routeName: (_) =>
        const SuperAdminGuard(child: TenantListPage()),
    TenantEditPage.routeName: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final resolvedArgs = args is TenantEditPageArgs
          ? args
          : args is TenantModel
          ? TenantEditPageArgs(editTenant: args)
          : null;
      return SuperAdminGuard(child: TenantEditPage(args: resolvedArgs));
    },
    TenantDetailPage.routeName: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final resolvedArgs = args is TenantDetailPageArgs
          ? args
          : args is String
          ? TenantDetailPageArgs(tenantId: args)
          : null;
      if (resolvedArgs == null) {
        return const SuperAdminGuard(
          child: _RouteErrorPage(
            message: 'Firma detay sayfası için bir kimlik gereklidir.',
          ),
        );
      }
      return SuperAdminGuard(
        child: TenantDetailPage(tenantId: resolvedArgs.tenantId),
      );
    },
    LicenseManagementPage.routeName: (_) =>
        const SuperAdminGuard(child: LicenseManagementPage()),
    LicenseListPage.routeName: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! LicenseListPageArgs) {
        return const SuperAdminGuard(
          child: _RouteErrorPage(
            message: 'Lisans listesi için firma kimliği gerekli.',
          ),
        );
      }
      return SuperAdminGuard(
        child: LicenseListPage(
          companyId: args.companyId,
          companyName: args.companyName,
        ),
      );
    },
    LicenseEditPage.routeName: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! LicenseEditPageArgs) {
        return const SuperAdminGuard(
          child: _RouteErrorPage(
            message: 'Lisans düzenleme için firma kimliği gerekli.',
          ),
        );
      }
      return SuperAdminGuard(child: LicenseEditPage(args: args));
    },
    LicenseDetailPage.routeName: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! LicenseDetailPageArgs) {
        return const SuperAdminGuard(
          child: _RouteErrorPage(
            message: 'Lisans detayı için firma ve lisans kimliği zorunlu.',
          ),
        );
      }
      return SuperAdminGuard(
        child: LicenseDetailPage(
          companyId: args.companyId,
          licenseId: args.licenseId,
          companyName: args.companyName,
        ),
      );
    },
    AssistantDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin'],
      requiredModules: ['admin'],
      child: AssistantDashboardPage(),
    ),
    AssistantChatPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin'],
      requiredModules: ['admin'],
      child: AssistantChatPage(),
    ),
    BiDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin'],
      requiredModules: ['admin'],
      child: BiDashboardPage(),
    ),
    ReportsHubPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin'],
      requiredModules: ['admin'],
      child: ReportsHubPage(),
    ),
    ReportPreviewPage.routeName: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! Map<String, dynamic>) {
        return const RoleGuard(
          allowedRoles: ['admin', 'superadmin'],
          requiredModules: ['admin'],
          child: _RouteErrorPage(message: 'Rapor verisi bulunamadı.'),
        );
      }
      final request = args['request'] as ReportRequest?;
      final data = args['data'] as ReportData?;
      if (request == null || data == null) {
        return const RoleGuard(
          allowedRoles: ['admin', 'superadmin'],
          requiredModules: ['admin'],
          child: _RouteErrorPage(message: 'Rapor verisi bulunamadı.'),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'superadmin'],
        requiredModules: const ['admin'],
        child: ReportPreviewPage(request: request, data: data),
      );
    },
    QaDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin'],
      requiredModules: ['admin'],
      child: QaDashboardPage(),
    ),
    QaRunDetailPage.routeName: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final runId = args is String ? args : null;
      if (runId == null) {
        return const RoleGuard(
          allowedRoles: ['admin', 'superadmin'],
          requiredModules: ['admin'],
          child: _RouteErrorPage(message: 'Test kaydı bulunamadı.'),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'superadmin'],
        requiredModules: const ['admin'],
        child: QaRunDetailPage(runId: runId),
      );
    },
    SystemDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin'],
      requiredModules: ['admin'],
      child: SystemDashboardPage(),
    ),
    NotificationListPage.routeName: (_) => const RoleGuard(
      allowedRoles: [
        'admin',
        'superadmin',
        'sales',
        'production',
        'accounting',
        'purchasing',
        'warehouse',
        'logistics',
      ],
      child: NotificationListPage(),
    ),
    PredictiveDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin'],
      requiredModules: ['admin'],
      child: PredictiveDashboardPage(),
    ),
    MonitoringDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin'],
      requiredModules: ['admin'],
      child: MonitoringDashboardPage(),
    ),
    '/crm/customers': (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales'],
      requiredModules: ['crm'],
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
          requiredModules: ['crm'],
          child: _RouteErrorPage(
            message: 'CustomerDetailPage için müşteri kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'sales'],
        requiredModules: const ['crm'],
        child: CustomerDetailPage(customerId: customerId),
      );
    },
    CustomerEditPage.createRoute: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales'],
      requiredModules: ['crm'],
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
          requiredModules: ['crm'],
          child: _RouteErrorPage(
            message: 'CustomerEditPage için müşteri kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'sales'],
        requiredModules: const ['crm'],
        child: CustomerEditPage(customerId: customerId),
      );
    },
    QuoteListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales'],
      requiredModules: ['crm'],
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
          requiredModules: ['crm'],
          child: _RouteErrorPage(
            message: 'QuoteDetailPage için teklif kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'sales'],
        requiredModules: const ['crm'],
        child: QuoteDetailPage(quoteId: quoteId),
      );
    },
    QuoteEditPage.createRoute: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales'],
      requiredModules: ['crm'],
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
          requiredModules: ['crm'],
          child: _RouteErrorPage(
            message: 'QuoteEditPage için teklif kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'sales'],
        requiredModules: const ['crm'],
        child: QuoteEditPage(quoteId: quoteId),
      );
    },
    ProductionListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales', 'production'],
      requiredModules: ['production'],
      child: ProductionListPage(),
    ),
    ProductionDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales', 'production'],
      requiredModules: ['production'],
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
          requiredModules: ['production'],
          child: _RouteErrorPage(
            message: 'ProductionDetailPage için talimat kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'sales', 'production'],
        requiredModules: const ['production'],
        child: ProductionDetailPage(orderId: orderId),
      );
    },
    InventoryListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales', 'production', 'warehouse'],
      requiredModules: ['inventory'],
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
          requiredModules: ['inventory'],
          child: _RouteErrorPage(
            message: 'InventoryDetailPage için kayıt kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'sales', 'production', 'warehouse'],
        requiredModules: const ['inventory'],
        child: InventoryDetailPage(itemId: itemId),
      );
    },
    ShipmentListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales', 'production', 'warehouse', 'logistics'],
      requiredModules: ['shipment'],
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
          requiredModules: ['shipment'],
          child: _RouteErrorPage(
            message: 'ShipmentDetailPage için sevkiyat kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const [
          'admin',
          'sales',
          'production',
          'warehouse',
          'logistics',
        ],
        requiredModules: const ['shipment'],
        child: ShipmentDetailPage(shipmentId: shipmentId),
      );
    },
    ShipmentEditPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales', 'production', 'warehouse', 'logistics'],
      requiredModules: ['shipment'],
      child: ShipmentEditPage(),
    ),
    InvoiceListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
      requiredModules: ['finance'],
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
          requiredModules: ['finance'],
          child: _RouteErrorPage(
            message: 'InvoiceDetailPage için fatura kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'superadmin', 'sales', 'accounting'],
        requiredModules: const ['finance'],
        child: InvoiceDetailPage(invoiceId: invoiceId),
      );
    },
    InvoiceEditPage.createRoute: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final editArgs = args is InvoiceEditPageArgs ? args : null;
      return RoleGuard(
        allowedRoles: const ['admin', 'superadmin', 'sales', 'accounting'],
        requiredModules: const ['finance'],
        child: InvoiceEditPage(invoiceId: editArgs?.invoiceId, args: editArgs),
      );
    },
    PaymentListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
      requiredModules: ['finance'],
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
          requiredModules: ['finance'],
          child: _RouteErrorPage(
            message: 'PaymentDetailPage için tahsilat kimliği gerekli.',
          ),
        );
      }
      return RoleGuard(
        allowedRoles: const ['admin', 'superadmin', 'sales', 'accounting'],
        requiredModules: const ['finance'],
        child: PaymentDetailPage(paymentId: paymentId),
      );
    },
    PaymentEditPage.createRoute: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final editArgs = args is PaymentEditPageArgs ? args : null;
      return RoleGuard(
        allowedRoles: const ['admin', 'superadmin', 'sales', 'accounting'],
        requiredModules: const ['finance'],
        child: PaymentEditPage(paymentId: editArgs?.paymentId, args: editArgs),
      );
    },
    FinanceDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin', 'accounting'],
      requiredModules: ['finance'],
      child: FinanceDashboardPage(),
    ),
    PurchasingDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin', 'purchasing'],
      requiredModules: ['purchasing'],
      child: PurchasingDashboardPage(),
    ),
    SupplierListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin', 'purchasing'],
      requiredModules: ['purchasing'],
      child: SupplierListPage(),
    ),
    POListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin', 'purchasing'],
      requiredModules: ['purchasing'],
      child: POListPage(),
    ),
    GRNListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin', 'purchasing', 'warehouse'],
      requiredModules: ['purchasing'],
      child: GRNListPage(),
    ),
    BillListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'superadmin', 'purchasing', 'accounting'],
      requiredModules: ['purchasing'],
      child: BillListPage(),
    ),
    LeadListPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales'],
      requiredModules: ['crm'],
      child: LeadListPage(),
    ),
    LeadFormPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales'],
      requiredModules: ['crm'],
      child: LeadFormPage(),
    ),
    CrmDashboardPage.routeName: (_) => const RoleGuard(
      allowedRoles: ['admin', 'sales', 'production', 'accounting'],
      requiredModules: ['crm'],
      child: CrmDashboardPage(),
    ),
  };

  static Route<dynamic> unknownRoute(RouteSettings settings) {
    final name = settings.name ?? 'bilinmeyen rota';
    return MaterialPageRoute(
      builder: (_) => _RouteErrorPage(
        message: 'Beklenmeyen bir rotaya erişmeye çalıştınız: $name.',
      ),
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
