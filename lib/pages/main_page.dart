import 'package:flutter/material.dart';

import '../modules/crm/pages/crm_dashboard_page.dart';
import '../modules/crm/pages/customer_list_page.dart';
import '../modules/crm/quotes/pages/quote_list_page.dart';
import '../modules/inventory/pages/inventory_list_page.dart';
import '../modules/production/pages/production_list_page.dart';
import '../modules/production/pages/production_dashboard_page.dart';
import '../modules/shipment/pages/shipment_list_page.dart';
import '../modules/finance/pages/invoice_list_page.dart';
import '../modules/finance/pages/payment_list_page.dart';
import '../modules/finance/pages/finance_dashboard_page.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static const routeName = '/main';

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // close drawer if open
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginPage.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final canAccessFinanceDashboard =
        role != null && ['superadmin', 'admin', 'accounting'].contains(role);

    return Scaffold(
      appBar: AppBar(title: const Text('ATG EVO System')),
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
