import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/role_manager.dart';
import '../core/services/push_notification_service.dart';
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
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final granted = await PushNotificationService.instance
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
                        await AuthService.instance.logout();
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
        ),
      ),
    );
  }
}
