import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import '../models/payment_model.dart';

class PaymentService with FirestoreTimestamps {
  PaymentService._(this._firestore);

  factory PaymentService({FirebaseFirestore? firestore}) {
    if (firestore == null) {
      return instance;
    }
    return PaymentService._(firestore);
  }

  static final PaymentService instance = PaymentService._(
    FirebaseFirestore.instance,
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('payments');

  Stream<List<PaymentModel>> getPaymentsByInvoice(String invoiceId) {
    return _collection
        .where('invoice_id', isEqualTo: invoiceId)
        .orderBy('payment_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PaymentModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<PaymentModel>> getPaymentsStream() {
    return _collection
        .orderBy('payment_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PaymentModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<PaymentModel?> getPaymentById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return PaymentModel.fromFirestore(doc);
  }

  Stream<PaymentModel?> watchPayment(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return PaymentModel.fromFirestore(snapshot);
    });
  }

  Future<String> addPayment(Map<String, dynamic> data) async {
    final invoiceId = (data['invoice_id'] as String? ?? '').trim();
    if (invoiceId.isEmpty) {
      throw ArgumentError('invoice_id is required');
    }

    final payload = withCreateTimestamps(data);
    final docRef = await _collection.add(payload);

    await _recalculateInvoiceBalance(invoiceId);

    return docRef.id;
  }

  Future<void> updatePayment(String id, Map<String, dynamic> data) async {
    final payment = await getPaymentById(id);
    if (payment == null) {
      throw StateError('Payment not found');
    }

    final payload = withUpdateTimestamp(data);

    await _collection.doc(id).update(payload);
    await _recalculateInvoiceBalance(payment.invoiceId);
  }

  Future<void> deletePayment(String id) async {
    final payment = await getPaymentById(id);
    if (payment == null) {
      throw StateError('Payment not found');
    }
    await _collection.doc(id).delete();
    await _recalculateInvoiceBalance(payment.invoiceId);
  }

  Future<void> _recalculateInvoiceBalance(String invoiceId) async {
    final invoiceRef = _firestore.collection('invoices').doc(invoiceId);

    await _firestore.runTransaction((transaction) async {
      final invoiceSnapshot = await transaction.get(invoiceRef);
      if (!invoiceSnapshot.exists) return;

      final invoiceData = invoiceSnapshot.data() ?? <String, dynamic>{};
      final grandTotal =
          (invoiceData['grand_total'] as num?)?.toDouble() ?? 0.0;

      final paymentsSnapshot = await _collection
          .where('invoice_id', isEqualTo: invoiceId)
          .get();

      final totalPaid = paymentsSnapshot.docs.fold<double>(
        0,
        (runningTotal, doc) =>
            runningTotal + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
      );

      final remaining = grandTotal - totalPaid;
      String newStatus;
      if (remaining <= 0) {
        newStatus = 'paid';
      } else if (remaining >= grandTotal) {
        newStatus = 'unpaid';
      } else {
        newStatus = 'partial';
      }

      transaction.update(
        invoiceRef,
        withUpdateTimestamp({'status': newStatus}),
      );
    });
  }
}
