import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import '../models/customer_model.dart';

class CustomerService with FirestoreTimestamps {
  CustomerService._internal(this._firestore);

  factory CustomerService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return CustomerService._internal(firestore);
  }

  static final CustomerService instance = CustomerService._internal(
    FirebaseFirestore.instance,
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('customers');

  Stream<List<CustomerModel>> watchCustomers({String? searchTerm}) {
    return _collection.orderBy('created_at', descending: true).snapshots().map((
      snapshot,
    ) {
      final customers = snapshot.docs
          .map(CustomerModel.fromDocument)
          .toList(growable: false);
      if (searchTerm == null || searchTerm.trim().isEmpty) {
        return customers;
      }
      return customers
          .where((customer) => customer.matchesSearch(searchTerm))
          .toList(growable: false);
    });
  }

  Stream<List<CustomerModel>> getCustomers() => watchCustomers();

  Stream<CustomerModel?> watchCustomer(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return CustomerModel.fromDocument(snapshot);
    });
  }

  Future<CustomerModel?> fetchCustomer(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return CustomerModel.fromDocument(doc);
  }

  Future<CustomerModel?> getCustomerById(String id) => fetchCustomer(id);

  Future<String> createCustomer(CustomerInput input) async {
    final payload = withCreateTimestamps(input.toMap());
    final ref = await _collection.add(payload);
    return ref.id;
  }

  Future<void> updateCustomer(String id, CustomerInput input) {
    final payload = input.toMap(includeUpdatedAt: true);
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteCustomer(String id) {
    return _collection.doc(id).delete();
  }
}
