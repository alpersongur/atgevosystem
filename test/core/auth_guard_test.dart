import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atgevosystem/core/auth_guard.dart';
import 'package:atgevosystem/core/models/user_profile.dart';
import 'package:atgevosystem/core/permission_service.dart';
import 'package:atgevosystem/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final mockAuth = MockFirebaseAuth();
    final fakeStore = FakeFirebaseFirestore();
    AuthService.setTestInstance(
      AuthService.test(auth: mockAuth, firestore: fakeStore),
    );
    await AuthService.instance.debugClearProfile();
    PermissionService.setTestInstance(
      PermissionService.test(firestore: fakeStore),
    );
    PermissionService.instance.clearCache();
  });

  tearDown(() {
    PermissionService.resetTestInstance();
    AuthService.resetTestInstance();
  });

  testWidgets('RoleGuard allows access for authorized role',
      (WidgetTester tester) async {
    AuthService.instance.debugSetProfile(
      UserProfileState(
        uid: 'user-1',
        email: 'admin@example.com',
        displayName: 'Admin',
        role: 'admin',
        department: 'sales',
        modules: const ['crm'],
        isActive: true,
        lastSyncedAt: DateTime.now(),
        source: ProfileDataSource.api,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: RoleGuard(
          allowedRoles: ['admin'],
          child: Text('Protected content'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Protected content'), findsOneWidget);
  });

  testWidgets('RoleGuard denies access for unauthorized role',
      (WidgetTester tester) async {
    AuthService.instance.debugSetProfile(
      UserProfileState(
        uid: 'user-2',
        email: 'sales@example.com',
        displayName: 'Sales',
        role: 'sales',
        department: 'sales',
        modules: const ['crm'],
        isActive: true,
        lastSyncedAt: DateTime.now(),
        source: ProfileDataSource.api,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: RoleGuard(
          allowedRoles: ['admin'],
          child: Text('Protected content'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Yetki Gerekli'), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);
  });
}
