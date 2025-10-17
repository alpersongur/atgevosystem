import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';
import 'package:atgevosystem/core/models/user_profile.dart';
import 'package:atgevosystem/core/services/auth_service.dart';
import 'package:atgevosystem/modules/tenant/services/tenant_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: TenantService.instance.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final authService = AuthService.instance;
          return StreamBuilder<UserProfileState?>(
            stream: authService.profileStream,
            initialData: authService.currentProfile,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting &&
                  profileSnapshot.data == null) {
                return const _AuthProgressIndicator(
                  message: 'Kullanıcı profiliniz yükleniyor...',
                );
              }

              final profile = profileSnapshot.data;
              if (profile == null) {
                return const _AuthProgressIndicator(
                  message: 'Rol bilgileriniz alınıyor...',
                );
              }

              if (!profile.isActive) {
                return const _InactiveAccountView();
              }

              return const MainPage();
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}

class _AuthProgressIndicator extends StatelessWidget {
  const _AuthProgressIndicator({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
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

class _InactiveAccountView extends StatelessWidget {
  const _InactiveAccountView();

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
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
