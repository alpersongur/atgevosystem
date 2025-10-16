import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/role_manager.dart';
import '../services/auth_service.dart';

class UserRoleNotifier extends ChangeNotifier {
  String? _role;

  String? get role => _role;

  void updateRole(String? newRole) {
    if (_role == newRole) return;
    _role = newRole;
    notifyListeners();
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<UserRoleNotifier>().role ?? 'sales';
    final allowedRoutes = RoleManager.menus[userRole] ?? [];

    return Drawer(
      child: SafeArea(
        child: Column(  
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Rol: ${userRole.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allowedRoutes.length,
                itemBuilder: (context, index) {
                  final route = allowedRoutes[index];
                  return ListTile(
                    title: Text(route),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(route);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await AuthService.instance.logout();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
