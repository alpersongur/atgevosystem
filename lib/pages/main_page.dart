import 'package:flutter/material.dart';

import '../core/services/notification_service.dart';
import '../core/services/push_notification_service.dart';
import '../modules/admin/pages/admin_dashboard_page.dart';
import '../modules/admin/pages/module_access_page.dart';
import '../modules/admin/pages/system_settings_page.dart';
import '../modules/admin/pages/user_list_page.dart';
import '../modules/admin/pages/role_list_page.dart';
import '../modules/crm/pages/crm_dashboard_page.dart';
import '../modules/crm/pages/customer_list_page.dart';
import '../modules/crm/quotes/pages/quote_list_page.dart';
import '../modules/dashboard/pages/notification_list_page.dart';
import '../modules/dashboard/pages/system_dashboard_page.dart';
import '../modules/ai/pages/predictive_dashboard_page.dart';
import '../modules/monitoring/pages/monitoring_dashboard_page.dart';
import '../modules/finance/pages/finance_dashboard_page.dart';
import '../modules/finance/pages/invoice_list_page.dart';
import '../modules/finance/pages/payment_list_page.dart';
import '../modules/inventory/pages/inventory_list_page.dart';
import '../modules/production/pages/production_dashboard_page.dart';
import '../modules/production/pages/production_list_page.dart';
import '../modules/purchasing/pages/bill_list_page.dart';
import '../modules/purchasing/pages/grn_list_page.dart';
import '../modules/purchasing/pages/po_list_page.dart';
import '../modules/purchasing/pages/purchasing_dashboard_page.dart';
import '../modules/purchasing/pages/supplier_list_page.dart';
import '../modules/shipment/pages/shipment_list_page.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static const routeName = '/main';

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await PushNotificationService.instance.initialize();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // close drawer if open
    await AuthService.instance.logout();
    await PushNotificationService.instance.refreshRoleSubscriptions();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginPage.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final isSuperAdmin = role == 'superadmin';
    final canAccessSystemDashboard =
        role != null && ['admin', 'superadmin'].contains(role);
    final canAccessPredictiveDashboard = canAccessSystemDashboard;
    final canAccessFinanceDashboard =
        role != null && ['superadmin', 'admin', 'accounting'].contains(role);
    final canAccessSuppliers =
        role != null && ['superadmin', 'admin', 'purchasing'].contains(role);
    final canAccessPOs = canAccessSuppliers;
    final canAccessBills =
        role != null &&
        ['superadmin', 'admin', 'purchasing', 'accounting'].contains(role);
    final canAccessGRN =
        role != null &&
        ['superadmin', 'admin', 'purchasing', 'warehouse'].contains(role);
    final hasPurchasingSection =
        canAccessSuppliers || canAccessPOs || canAccessBills || canAccessGRN;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ATG EVO System'),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.instance.streamUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return IconButton(
                tooltip: 'Bildirimler',
                onPressed: () {
                  Navigator.of(context).pushNamed(NotificationListPage.routeName);
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_outlined),
                    if (count > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.indigo),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'CRM Menüsü',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (canAccessSystemDashboard)
                ListTile(
                  leading: const Icon(Icons.insights_outlined),
                  title: const Text('📊 Genel Dashboard'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pushNamed(SystemDashboardPage.routeName);
                  },
                ),
              if (canAccessPredictiveDashboard)
                ListTile(
                  leading: const Icon(Icons.auto_graph_outlined),
                  title: const Text('🔮 Tahmin Paneli'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context)
                        .pushNamed(PredictiveDashboardPage.routeName);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('CRM Dashboard'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(CrmDashboardPage.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Müşteriler'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(CustomerListPage.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.request_quote_outlined),
                title: const Text('Teklifler'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(QuoteListPage.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.factory_outlined),
                title: const Text('Üretim Talimatları'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(ProductionListPage.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Üretim Paneli'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pushNamed(ProductionDashboardPage.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.warehouse_outlined),
                title: const Text('Depo & Envanter'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(InventoryListPage.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Sevkiyatlar'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(ShipmentListPage.routeName);
                },
              ),
              if (hasPurchasingSection)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Satınalma',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              if (canAccessSuppliers || canAccessBills)
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Satınalma Dashboard'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pushNamed(PurchasingDashboardPage.routeName);
                  },
                ),
              if (canAccessSuppliers)
                ListTile(
                  leading: const Icon(Icons.store_outlined),
                  title: const Text('Tedarikçiler'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(SupplierListPage.routeName);
                  },
                ),
              if (canAccessPOs)
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Satınalma Emirleri'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(POListPage.routeName);
                  },
                ),
              if (canAccessGRN)
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Mal Kabul (GRN)'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(GRNListPage.routeName);
                  },
                ),
              if (canAccessBills)
                ListTile(
                  leading: const Icon(Icons.receipt_outlined),
                  title: const Text('Vendor Faturaları'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(BillListPage.routeName);
                  },
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Ön Muhasebe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              if (canAccessFinanceDashboard)
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Finance Dashboard'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pushNamed(FinanceDashboardPage.routeName);
                  },
                ),
              if (isSuperAdmin)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    '🛠 Yönetim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              if (isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: const Text('Yönetim Paneli'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pushNamed(AdminDashboardPage.routeName);
                  },
                ),
              if (isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: const Text('System Health'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context)
                        .pushNamed(MonitoringDashboardPage.routeName);
                  },
                ),
              if (isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Kullanıcılar'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(UserListPage.routeName);
                  },
                ),
              if (isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.rule_folder_outlined),
                  title: const Text('Roller'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(RoleListPage.routeName);
                  },
                ),
              if (isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.toggle_on_outlined),
                  title: const Text('Modül Erişimleri'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(ModuleAccessPage.routeName);
                  },
                ),
              if (isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Sistem Ayarları'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pushNamed(SystemSettingsPage.routeName);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Faturalar'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(InvoiceListPage.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Tahsilatlar'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(PaymentListPage.routeName);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Çıkış Yap'),
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Text('ATG EVO System Dashboard', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
