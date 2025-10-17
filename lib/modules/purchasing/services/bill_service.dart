import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import '../models/bill_model.dart';

class BillService with FirestoreTimestamps {
  BillService._(this._firestore);

  factory BillService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return BillService._(firestore);
  }

  static final BillService instance = BillService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('bills');

  Stream<List<BillModel>> getBills() {
    return _collection
        .orderBy('issue_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(BillModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<BillModel?> watchBill(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return BillModel.fromFirestore(snapshot);
    });
  }

  Future<BillModel?> getBillById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return BillModel.fromFirestore(doc);
  }

  Future<String> addBill(Map<String, dynamic> data) async {
    final payload = withCreateTimestamps(data);
    final ref = await _collection.add(payload);
    return ref.id;
  }

  Future<void> updateBill(String id, Map<String, dynamic> data) {
    final payload = withUpdateTimestamp(data);
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteBill(String id) {
    return _collection.doc(id).delete();
  }

  Future<void> markBillStatus(String id, String status) {
    return _collection.doc(id).update(withUpdateTimestamp({'status': status}));
  }
}
