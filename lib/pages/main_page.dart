import 'package:flutter/material.dart';

import '../modules/crm/pages/customer_list_page.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static const routeName = '/main';

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // close drawer if open
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginPage.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATG EVO System'),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.indigo,
                ),
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
                leading: const Icon(Icons.people_alt_outlined),
                title: const Text('Customers'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(CustomersListPage.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.request_quote_outlined),
                title: const Text('Quotes'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quotes sayfası yakında eklenecek.'),
                    ),
                  );
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
        child: Text(
          'ATG EVO System Dashboard',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
