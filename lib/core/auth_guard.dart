import 'package:flutter/material.dart';

import 'permission_service.dart';
import 'services/auth_service.dart';
import 'models/user_profile.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.requiredModules,
    this.deniedMessage = 'Yetkiniz yok.',
    this.moduleDeniedMessage = 'Bu modüle erişiminiz bulunmuyor.',
  });

  final List<String> allowedRoles;
  final Widget child;
  final List<String>? requiredModules;
  final String deniedMessage;
  final String moduleDeniedMessage;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    return StreamBuilder<UserProfileState?>(
      stream: authService.profileStream,
      initialData: authService.currentProfile,
      builder: (context, snapshot) {
        final profile = snapshot.data;

        if (profile == null) {
          return const _GuardProgressView(
            message: 'Yetki kontrolü yapılıyor...',
          );
        }

        if (!profile.isActive) {
          return const _GuardInactiveView();
        }

        final role = profile.role;
        if (role == null) {
          return const _GuardProgressView(
            message: 'Rol bilgileriniz güncelleniyor...',
          );
        }

        if (allowedRoles.isNotEmpty && !allowedRoles.contains(role)) {
          return _GuardDeniedView(message: deniedMessage);
        }

        final modules = requiredModules;
        if (modules != null &&
            modules.isNotEmpty &&
            !profile.hasAllModules(modules)) {
          return _GuardDeniedView(message: moduleDeniedMessage);
        }

        final normalizedModules = modules
            ?.map((module) => module.toLowerCase())
            .toSet()
            .toList(growable: false);

        if (normalizedModules != null && normalizedModules.isNotEmpty) {
          return FutureBuilder<List<Map<String, bool>>>(
            future: Future.wait(
              normalizedModules
                  .map(PermissionService.instance.getPermissions),
            ),
            builder: (context, permissionSnapshot) {
              if (permissionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const _GuardProgressView(
                  message: 'Yetki verileri yükleniyor...',
                );
              }
              if (permissionSnapshot.hasError) {
                return const _GuardDeniedView(
                  message:
                      'Yetki verileri alınırken bir hata oluştu. Lütfen tekrar deneyin.',
                );
              }
              return child;
            },
          );
        }

        return child;
      },
    );
  }
}

class SuperAdminGuard extends StatelessWidget {
  const SuperAdminGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const ['superadmin'],
      deniedMessage: 'Bu alana sadece superadmin erişebilir.',
      child: child,
    );
  }
}

class _GuardProgressView extends StatelessWidget {
  const _GuardProgressView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardDeniedView extends StatelessWidget {
  const _GuardDeniedView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yetki Gerekli')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/main', (route) => route.isFirst);
                },
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuardInactiveView extends StatelessWidget {
  const _GuardInactiveView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Hesabınız pasifleştirilmiştir. Lütfen sistem yöneticinizle iletişime geçin.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  AuthService.instance.logout();
                },
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
