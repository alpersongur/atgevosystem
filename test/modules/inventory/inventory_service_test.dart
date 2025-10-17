import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atgevosystem/modules/inventory/services/inventory_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late InventoryService service;
  late String itemId;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = InventoryService(firestore: firestore);
    final docRef = await firestore.collection('inventory').add({
      'product_name': 'Widget',
      'quantity': 10,
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });
    itemId = docRef.id;
  });

  test('adjustStock increases quantity when operation is increase', () async {
    await service.adjustStock(itemId, 5, 'increase');

    final doc = await firestore.collection('inventory').doc(itemId).get();
    expect(doc.data()?['quantity'], equals(15));
  });

  test('adjustStock decreases quantity without going negative', () async {
    await service.adjustStock(itemId, 5, 'decrease');

    final doc = await firestore.collection('inventory').doc(itemId).get();
    expect(doc.data()?['quantity'], equals(5));
  });

  test('adjustStock throws when resulting quantity negative', () async {
    expect(
      () => service.adjustStock(itemId, 20, 'decrease'),
      throwsStateError,
    );
  });
}
