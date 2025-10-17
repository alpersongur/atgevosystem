import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atgevosystem/core/services/customer_service.dart';
import 'package:atgevosystem/modules/crm/pages/crm_dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    CustomerService.setTestInstance(CustomerService(firestore: firestore));

    await firestore.collection('customers').add({
      'company_name': 'Acme Corp',
      'contact_person': 'Jane Doe',
      'customer_type': 'corporate',
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });
  });

  tearDown(() {
    CustomerService.resetTestInstance();
  });

  testWidgets('CrmDashboardPage renders title', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(4000, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CrmDashboardPage()));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('CRM Dashboard'), findsWidgets);
  });
}
