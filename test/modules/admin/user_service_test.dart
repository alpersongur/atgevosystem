import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atgevosystem/modules/admin/services/user_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = UserService(firestore: firestore);
  });

  test('addUser creates record with timestamps', () async {
    await service.addUser({
      'email': 'admin@example.com',
      'display_name': 'Admin User',
      'role': 'admin',
      'modules': ['crm'],
    });

    final snapshot = await firestore.collection('users').get();
    expect(snapshot.docs, hasLength(1));
    final data = snapshot.docs.first.data();
    expect(data['email'], equals('admin@example.com'));
    expect(data['created_at'], isNotNull);
    expect(data['updated_at'], isNotNull);
  });

  test('update role and modules persist to Firestore', () async {
    final docRef = await firestore.collection('users').add({
      'uid': 'user-1',
      'display_name': 'User',
      'role': 'sales',
      'modules': ['crm'],
    });

    await service.updateUserRole(docRef.id, 'admin');
    await service.assignModules(docRef.id, ['crm', 'finance']);

    final updated = await docRef.get();
    expect(updated.data()?['role'], equals('admin'));
    expect(updated.data()?['modules'], equals(['crm', 'finance']));
  });

  test('toggleUserActive updates is_active flag', () async {
    final docRef = await firestore.collection('users').add({
      'uid': 'user-2',
      'display_name': 'User',
      'is_active': true,
    });

    await service.toggleUserActive(docRef.id, false);

    final updated = await docRef.get();
    expect(updated.data()?['is_active'], isFalse);
  });
}
