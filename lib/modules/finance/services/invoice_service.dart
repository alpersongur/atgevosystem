import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import '../models/invoice_model.dart';

class InvoiceService with FirestoreTimestamps {
  InvoiceService._(this._firestore);

  factory InvoiceService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return InvoiceService._(firestore);
  }

  static final InvoiceService instance = InvoiceService._(
    FirebaseFirestore.instance,
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('invoices');

  Stream<List<InvoiceModel>> getInvoices() {
    return _collection
        .orderBy('issue_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InvoiceModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<InvoiceModel?> watchInvoice(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return InvoiceModel.fromFirestore(snapshot);
    });
  }

  Future<InvoiceModel?> getInvoiceById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return InvoiceModel.fromFirestore(doc);
  }

  Future<String> addInvoice(Map<String, dynamic> data) async {
    final payload = withCreateTimestamps(data);
    final docRef = await _collection.add(payload);
    return docRef.id;
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> data) {
    final payload = withUpdateTimestamp(data);
    return _collection.doc(id).update(payload);
  }

  Future<void> deleteInvoice(String id) {
    return _collection.doc(id).delete();
  }

  Future<void> markStatus(String id, String status) {
    return _collection.doc(id).update(withUpdateTimestamp({'status': status}));
  }

  Future<void> attachPdf(String id, String url) {
    return _collection
        .doc(id)
        .update(withUpdateTimestamp({'attachment_url': url}));
  }
}
