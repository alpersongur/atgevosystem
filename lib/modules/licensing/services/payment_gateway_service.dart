import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/timestamp_helper.dart';
import '../../tenant/services/tenant_service.dart';
import '../models/payment_record_model.dart';

class PaymentIntentResult {
  const PaymentIntentResult({
    required this.intentId,
    required this.amount,
    required this.currency,
    required this.clientSecret,
  });

  final String intentId;
  final num amount;
  final String currency;
  final String clientSecret;
}

class PaymentGatewayService with FirestoreTimestamps {
  PaymentGatewayService._();

  static final PaymentGatewayService instance = PaymentGatewayService._();

  FirebaseFirestore get _firestore => TenantService.instance.firestore;

  CollectionReference<Map<String, dynamic>> _paymentsCollection(
    String companyId,
  ) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('payments');
  }

  Future<PaymentIntentResult> createPaymentIntent(
    num amount,
    String currency,
  ) async {
    final randomId = _mockTransactionId();
    return PaymentIntentResult(
      intentId: randomId,
      amount: amount,
      currency: currency,
      clientSecret: 'mock_$randomId',
    );
  }

  Future<bool> confirmPayment({
    required String intentId,
    required String paymentMethod,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return paymentMethod != 'declined';
  }

  Future<String> recordPaymentToFirestore(
    String companyId,
    Map<String, dynamic> data,
  ) async {
    final payload = withCreateTimestamps(data);
    final docRef = await _paymentsCollection(companyId).add(payload);
    return docRef.id;
  }

  Stream<List<PaymentRecordModel>> getPaymentHistory(
    String companyId,
    String licenseId,
  ) {
    return _paymentsCollection(companyId)
        .where('license_id', isEqualTo: licenseId)
        .orderBy('payment_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PaymentRecordModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  String _mockTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = random.nextInt(9999).toString().padLeft(4, '0');
    return 'PI-$timestamp-$suffix';
  }
}
