import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:atgevosystem/core/models/user_profile.dart';
import 'package:atgevosystem/core/permission_service.dart';
import 'package:atgevosystem/core/services/auth_service.dart';
import 'package:atgevosystem/core/services/push_notification_service.dart';
import 'package:atgevosystem/modules/admin/pages/admin_dashboard_page.dart';
import 'package:atgevosystem/modules/admin/pages/module_access_page.dart';
import 'package:atgevosystem/modules/admin/pages/permission_management_page.dart';
import 'package:atgevosystem/modules/admin/pages/role_list_page.dart';
import 'package:atgevosystem/modules/admin/pages/system_settings_page.dart';
import 'package:atgevosystem/modules/admin/pages/user_list_page.dart';
import 'package:atgevosystem/modules/admin/pages/api_keys_page.dart';
import 'package:atgevosystem/modules/ai/pages/predictive_dashboard_page.dart';
import 'package:atgevosystem/modules/crm/pages/crm_dashboard_page.dart';
import 'package:atgevosystem/modules/crm/pages/customer_list_page.dart';
import 'package:atgevosystem/modules/crm/pages/lead_form_page.dart';
import 'package:atgevosystem/modules/crm/pages/lead_list_page.dart';
import 'package:atgevosystem/modules/crm/quotes/pages/quote_list_page.dart';
import 'package:atgevosystem/modules/dashboard/pages/notification_list_page.dart';
import 'package:atgevosystem/modules/dashboard/pages/system_dashboard_page.dart';
import 'package:atgevosystem/modules/finance/pages/finance_dashboard_page.dart';
import 'package:atgevosystem/modules/finance/pages/invoice_list_page.dart';
import 'package:atgevosystem/modules/finance/pages/payment_list_page.dart';
import 'package:atgevosystem/modules/inventory/pages/inventory_list_page.dart';
import 'package:atgevosystem/modules/monitoring/pages/monitoring_dashboard_page.dart';
import 'package:atgevosystem/modules/production/pages/production_dashboard_page.dart';
import 'package:atgevosystem/modules/production/pages/production_list_page.dart';
import 'package:atgevosystem/modules/purchasing/pages/bill_list_page.dart';
import 'package:atgevosystem/modules/purchasing/pages/grn_list_page.dart';
import 'package:atgevosystem/modules/purchasing/pages/po_list_page.dart';
import 'package:atgevosystem/modules/purchasing/pages/purchasing_dashboard_page.dart';
import 'package:atgevosystem/modules/purchasing/pages/supplier_list_page.dart';
import 'package:atgevosystem/modules/shipment/pages/shipment_list_page.dart';
import 'package:atgevosystem/modules/assistant/pages/assistant_dashboard_page.dart';
import 'package:atgevosystem/modules/bi/pages/bi_dashboard_page.dart';
import 'package:atgevosystem/modules/reports/pages/reports_hub_page.dart';
import 'package:atgevosystem/modules/qa/pages/qa_dashboard_page.dart';
import 'package:atgevosystem/modules/tenant/pages/tenant_list_page.dart';
import 'package:atgevosystem/modules/tenant/models/tenant_model.dart';
import 'package:atgevosystem/modules/licensing/pages/license_management_page.dart';

class DrawerMenuItem {
  const DrawerMenuItem({
    required this.label,
    required this.route,
    required this.icon,
    this.requiredModules = const [],
    this.allowedRoles,
  });

  final String label;
  final String route;
  final IconData icon;
  final List<String> requiredModules;
  final List<String>? allowedRoles;

  bool isVisible(String? role, List<String> modules) {
    final normalizedRole = role?.toLowerCase();
    if (allowedRoles != null &&
        (normalizedRole == null || !allowedRoles!.contains(normalizedRole))) {
      return false;
    }
    if (requiredModules.isEmpty) return true;
    return requiredModules.every(modules.contains);
  }
}

class DrawerSection {
  const DrawerSection({this.title, required this.items});

  final String? title;
  final List<DrawerMenuItem> items;

  bool isVisible(String? role, List<String> modules) {
    return items.any((item) => item.isVisible(role, modules));
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const List<DrawerSection> _sections = [
    DrawerSection(
      title: 'Genel',
      items: [
        DrawerMenuItem(
          label: '📊 Genel Kontrol Paneli',
          route: SystemDashboardPage.routeName,
          icon: Icons.insights_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['admin', 'superadmin'],
        ),
        DrawerMenuItem(
          label: '🔮 Tahmin Paneli',
          route: PredictiveDashboardPage.routeName,
          icon: Icons.auto_graph_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['admin', 'superadmin'],
        ),
        DrawerMenuItem(
          label: 'Bildirimler',
          route: NotificationListPage.routeName,
          icon: Icons.notifications_outlined,
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
        ),
      ],
    ),
    DrawerSection(
      title: 'CRM',
      items: [
        DrawerMenuItem(
          label: 'CRM Kontrol Paneli',
          route: CrmDashboardPage.routeName,
          icon: Icons.dashboard_outlined,
          requiredModules: ['crm'],
          allowedRoles: ['admin', 'sales', 'production', 'accounting'],
        ),
        DrawerMenuItem(
          label: 'Müşteriler',
          route: CustomerListPage.routeName,
          icon: Icons.people_outline,
          requiredModules: ['crm'],
          allowedRoles: ['admin', 'sales'],
        ),
        DrawerMenuItem(
          label: 'Teklifler',
          route: QuoteListPage.routeName,
          icon: Icons.request_quote_outlined,
          requiredModules: ['crm'],
          allowedRoles: ['admin', 'sales'],
        ),
        DrawerMenuItem(
          label: 'Potansiyel Listesi',
          route: LeadListPage.routeName,
          icon: Icons.timeline_outlined,
          requiredModules: ['crm'],
          allowedRoles: ['admin', 'sales'],
        ),
        DrawerMenuItem(
          label: 'Potansiyel Oluştur',
          route: LeadFormPage.routeName,
          icon: Icons.note_add_outlined,
          requiredModules: ['crm'],
          allowedRoles: ['admin', 'sales'],
        ),
      ],
    ),
    DrawerSection(
      title: 'Üretim',
      items: [
        DrawerMenuItem(
          label: 'Üretim Talimatları',
          route: ProductionListPage.routeName,
          icon: Icons.factory_outlined,
          requiredModules: ['production'],
          allowedRoles: ['admin', 'sales', 'production'],
        ),
        DrawerMenuItem(
          label: 'Üretim Kontrol Paneli',
          route: ProductionDashboardPage.routeName,
          icon: Icons.dashboard_customize_outlined,
          requiredModules: ['production'],
          allowedRoles: ['admin', 'sales', 'production'],
        ),
      ],
    ),
    DrawerSection(
      title: 'Depo & Sevkiyat',
      items: [
        DrawerMenuItem(
          label: 'Depo & Envanter',
          route: InventoryListPage.routeName,
          icon: Icons.warehouse_outlined,
          requiredModules: ['inventory'],
          allowedRoles: ['admin', 'sales', 'production', 'warehouse'],
        ),
        DrawerMenuItem(
          label: 'Sevkiyatlar',
          route: ShipmentListPage.routeName,
          icon: Icons.local_shipping_outlined,
          requiredModules: ['shipment'],
          allowedRoles: [
            'admin',
            'sales',
            'production',
            'warehouse',
            'logistics',
          ],
        ),
      ],
    ),
    DrawerSection(
      title: 'Satınalma',
      items: [
        DrawerMenuItem(
          label: 'Satınalma Kontrol Paneli',
          route: PurchasingDashboardPage.routeName,
          icon: Icons.dashboard_outlined,
          requiredModules: ['purchasing'],
          allowedRoles: ['admin', 'superadmin', 'purchasing'],
        ),
        DrawerMenuItem(
          label: 'Tedarikçiler',
          route: SupplierListPage.routeName,
          icon: Icons.store_outlined,
          requiredModules: ['purchasing'],
          allowedRoles: ['admin', 'superadmin', 'purchasing'],
        ),
        DrawerMenuItem(
          label: 'Satınalma Emirleri',
          route: POListPage.routeName,
          icon: Icons.assignment_outlined,
          requiredModules: ['purchasing'],
          allowedRoles: ['admin', 'superadmin', 'purchasing'],
        ),
        DrawerMenuItem(
          label: 'Mal Kabul (GRN)',
          route: GRNListPage.routeName,
          icon: Icons.inventory_2_outlined,
          requiredModules: ['purchasing'],
          allowedRoles: ['admin', 'superadmin', 'purchasing', 'warehouse'],
        ),
        DrawerMenuItem(
          label: 'Tedarikçi Faturaları',
          route: BillListPage.routeName,
          icon: Icons.receipt_outlined,
          requiredModules: ['purchasing'],
          allowedRoles: ['admin', 'superadmin', 'purchasing', 'accounting'],
        ),
      ],
    ),
    DrawerSection(
      title: 'Finans',
      items: [
        DrawerMenuItem(
          label: 'Finans Kontrol Paneli',
          route: FinanceDashboardPage.routeName,
          icon: Icons.assessment_outlined,
          requiredModules: ['finance'],
          allowedRoles: ['admin', 'superadmin', 'accounting'],
        ),
        DrawerMenuItem(
          label: 'Faturalar',
          route: InvoiceListPage.routeName,
          icon: Icons.receipt_long_outlined,
          requiredModules: ['finance'],
          allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
        ),
        DrawerMenuItem(
          label: 'Tahsilatlar',
          route: PaymentListPage.routeName,
          icon: Icons.payments_outlined,
          requiredModules: ['finance'],
          allowedRoles: ['admin', 'superadmin', 'sales', 'accounting'],
        ),
      ],
    ),
    DrawerSection(
      title: '🛠 Yönetim',
      items: [
        DrawerMenuItem(
          label: 'Yönetim Paneli',
          route: AdminDashboardPage.routeName,
          icon: Icons.dashboard_customize_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'Firmalar',
          route: TenantListPage.routeName,
          icon: Icons.apartment_outlined,
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'Lisans Yönetimi',
          route: LicenseManagementPage.routeName,
          icon: Icons.verified_user_outlined,
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'AI Asistanı',
          route: AssistantDashboardPage.routeName,
          icon: Icons.bolt_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin', 'admin'],
        ),
        DrawerMenuItem(
          label: 'BI Kontrol Paneli',
          route: BiDashboardPage.routeName,
          icon: Icons.bar_chart_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin', 'admin'],
        ),
        DrawerMenuItem(
          label: 'Raporlama',
          route: ReportsHubPage.routeName,
          icon: Icons.insert_drive_file_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin', 'admin'],
        ),
        DrawerMenuItem(
          label: 'Test ve QA',
          route: QaDashboardPage.routeName,
          icon: Icons.build_circle_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin', 'admin'],
        ),
        DrawerMenuItem(
          label: 'Sistem Sağlığı',
          route: MonitoringDashboardPage.routeName,
          icon: Icons.monitor_heart_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'Kullanıcılar',
          route: UserListPage.routeName,
          icon: Icons.manage_accounts_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'Roller',
          route: RoleListPage.routeName,
          icon: Icons.rule_folder_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'Modül Erişimleri',
          route: ModuleAccessPage.routeName,
          icon: Icons.toggle_on_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'Sistem Ayarları',
          route: SystemSettingsPage.routeName,
          icon: Icons.settings_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'Yetki Yönetimi',
          route: PermissionManagementPage.routeName,
          icon: Icons.security_outlined,
          requiredModules: ['admin'],
          allowedRoles: ['superadmin'],
        ),
        DrawerMenuItem(
          label: 'API Anahtarları',
          route: ApiKeysPage.routeName,
          icon: Icons.vpn_key_outlined,
          allowedRoles: ['superadmin'],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final tenant = context.watch<TenantModel?>();
    return Drawer(
      child: SafeArea(
        child: StreamBuilder<UserProfileState?>(
          stream: auth.profileStream,
          initialData: auth.currentProfile,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final role = profile.role?.toLowerCase();
            final modules = profile.modules
                .map((m) => m.toLowerCase())
                .toList();

            final visibleSections = _sections
                .where((section) => section.isVisible(role, modules))
                .toList(growable: false);

            return Column(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.indigo),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName ?? profile.email ?? profile.uid,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rol: ${(role ?? 'belirtilmemiş').toUpperCase()}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aktif Firma: ${tenant?.companyName ?? 'Seçilmedi'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: visibleSections.fold<int>(
                      0,
                      (count, section) =>
                          count +
                          section.items
                              .where((item) => item.isVisible(role, modules))
                              .length +
                          (section.title?.isNotEmpty == true ? 1 : 0),
                    ),
                    itemBuilder: (context, index) {
                      int offset = 0;
                      for (final section in visibleSections) {
                        final visibleItems = section.items
                            .where((item) => item.isVisible(role, modules))
                            .toList(growable: false);
                        if (visibleItems.isEmpty) continue;

                        final hasTitle = section.title?.isNotEmpty == true;
                        if (hasTitle) {
                          if (index == offset) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: Text(
                                section.title!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }
                          offset += 1;
                        }

                        final itemIndex = index - offset;
                        if (itemIndex >= 0 && itemIndex < visibleItems.length) {
                          final item = visibleItems[itemIndex];
                          return ListTile(
                            leading: Icon(item.icon),
                            title: Text(item.label),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(item.route);
                            },
                          );
                        }

                        offset += visibleItems.length;
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final granted = await PushNotificationService
                                .instance
                                .requestPermissionFromUserGesture();
                            if (!navigator.mounted) return;
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  granted
                                      ? 'Bildirim izinleri etkinleştirildi.'
                                      : 'Bildirim izni reddedildi.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Bildirimleri etkinleştir'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await auth.logout();
                            PermissionService.instance.clearCache();
                            await PushNotificationService.instance
                                .refreshRoleSubscriptions();
                            if (navigator.mounted) {
                              navigator.pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Çıkış Yap'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
