import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atgevosystem/core/models/customer.dart';
import 'package:atgevosystem/core/services/customer_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CustomerService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = CustomerService(firestore: firestore);
  });

  test('createCustomer writes document with timestamps', () async {
    final id = await service.createCustomer(
      CustomerInput(
        companyName: 'Acme Corp',
        contactPerson: 'Jane Doe',
        email: 'contact@acme.test',
      ),
    );

    final doc = await firestore.collection('customers').doc(id).get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['company_name'], equals('Acme Corp'));
    expect(doc.data()?['created_at'], isNotNull);
    expect(doc.data()?['updated_at'], isNotNull);
  });

  test('updateCustomer updates selective fields and timestamp', () async {
    final docRef = await firestore.collection('customers').add({
      'company_name': 'Old Name',
      'contact_person': 'Initial',
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });

    await service.updateCustomer(
      docRef.id,
      CustomerInput(
        companyName: 'New Name',
        contactPerson: 'Updated Contact',
      ),
    );

    final updated = await docRef.get();
    expect(updated.data()?['company_name'], equals('New Name'));
    expect(updated.data()?['contact_person'], equals('Updated Contact'));
    expect(updated.data()?['updated_at'], isNotNull);
  });

  test('deleteCustomer removes document', () async {
    final docRef = await firestore.collection('customers').add({
      'company_name': 'Temp',
    });

    await service.deleteCustomer(docRef.id);

    final doc = await docRef.get();
    expect(doc.exists, isFalse);
  });
}
