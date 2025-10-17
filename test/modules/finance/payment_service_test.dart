import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atgevosystem/modules/finance/services/payment_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PaymentService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = PaymentService(firestore: firestore);

    await firestore.collection('invoices').doc('inv-1').set({
      'grand_total': 1000.0,
      'status': 'unpaid',
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });
  });

  test('addPayment recalculates invoice balance to partial', () async {
    await service.addPayment({
      'invoice_id': 'inv-1',
      'amount': 250.0,
      'payment_date': DateTime.now(),
    });

    final invoice = await firestore.collection('invoices').doc('inv-1').get();
    expect(invoice.data()?['status'], equals('partial'));
  });

  test('updatePayment updates invoice status after amount change', () async {
    final paymentId = await service.addPayment({
      'invoice_id': 'inv-1',
      'amount': 250.0,
      'payment_date': DateTime.now(),
    });

    await service.updatePayment(paymentId, {'amount': 1000.0});

    final invoice = await firestore.collection('invoices').doc('inv-1').get();
    expect(invoice.data()?['status'], equals('paid'));
  });

  test('deletePayment restores outstanding balance to unpaid', () async {
    final paymentId = await service.addPayment({
      'invoice_id': 'inv-1',
      'amount': 1000.0,
      'payment_date': DateTime.now(),
    });

    await service.deletePayment(paymentId);

    final invoice = await firestore.collection('invoices').doc('inv-1').get();
    expect(invoice.data()?['status'], equals('unpaid'));
  });
}
