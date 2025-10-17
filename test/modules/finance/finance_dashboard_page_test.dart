import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:atgevosystem/core/services/customer_service.dart';
import 'package:atgevosystem/modules/finance/pages/finance_dashboard_page.dart';
import 'package:atgevosystem/modules/finance/services/finance_dashboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;

  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    FinanceDashboardService.setTestInstance(
      FinanceDashboardService(firestore: firestore),
    );
    CustomerService.setTestInstance(CustomerService(firestore: firestore));

    await firestore.collection('customers').doc('cust-1').set({
      'company_name': 'Finance Corp',
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });

    await firestore.collection('invoices').add({
      'customer_id': 'cust-1',
      'grand_total': 1500.0,
      'issue_date': DateTime.now(),
      'status': 'unpaid',
    });
  });

  tearDown(() {
    FinanceDashboardService.resetTestInstance();
    CustomerService.resetTestInstance();
  });

  testWidgets('FinanceDashboardPage renders title',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(4000, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: FinanceDashboardPage()));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('Finance Dashboard'), findsWidgets);
  });
}
