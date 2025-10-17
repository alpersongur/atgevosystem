import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:atgevosystem/core/services/customer_service.dart';
import 'package:atgevosystem/core/services/quote_reader_service.dart';
import 'package:atgevosystem/modules/inventory/services/inventory_service.dart';
import 'package:atgevosystem/modules/production/pages/production_dashboard_page.dart';
import 'package:atgevosystem/modules/production/services/production_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;

  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    ProductionService.setTestInstance(ProductionService(firestore: firestore));
    CustomerService.setTestInstance(CustomerService(firestore: firestore));
    QuoteReaderService.setTestInstance(QuoteReaderService(firestore: firestore));
    InventoryService.setTestInstance(InventoryService(firestore: firestore));

    final customer = await firestore.collection('customers').add({
      'company_name': 'Mega Industries',
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });

    final quote = await firestore.collection('quotes').add({
      'customer_id': customer.id,
      'quote_number': 'Q-1001',
      'status': 'approved',
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });

    await firestore.collection('production_orders').add({
      'quote_id': quote.id,
      'customer_id': customer.id,
      'status': 'in_progress',
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });
  });

  tearDown(() {
    ProductionService.resetTestInstance();
    CustomerService.resetTestInstance();
    QuoteReaderService.resetTestInstance();
    InventoryService.resetTestInstance();
  });

  testWidgets('ProductionDashboardPage shows title', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(4000, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ProductionDashboardPage()));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('Üretim Takip Paneli'), findsWidgets);
  });
}
