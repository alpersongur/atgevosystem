import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'quote_pdf_service.dart';

class QuoteService {
  QuoteService._();

  static final QuoteService instance = QuoteService._();

  final CollectionReference<Map<String, dynamic>> _quotesCollection =
      FirebaseFirestore.instance.collection('quotes');

  Future<DocumentReference<Map<String, dynamic>>> addQuote(
    Map<String, dynamic> data,
  ) async {
    final customerId = data['customer_id'] as String?;
    if (customerId == null || customerId.isEmpty) {
      throw ArgumentError('customer_id is required');
    }

    final productsRaw = data['products'] as List<dynamic>? ?? <dynamic>[];
    final products = productsRaw
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(
            item as Map<dynamic, dynamic>,
          ),
        )
        .toList(growable: false);
    final total = (data['total'] as num?)?.toDouble() ?? 0;

    final payload = <String, dynamic>{
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    final docRef = await _quotesCollection.add(payload);

    try {
      final customerSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();

      if (!customerSnapshot.exists) {
        throw StateError('Customer not found');
      }

      final customerData =
          Map<String, dynamic>.from(customerSnapshot.data() ?? {});

      final pdfBytes = await QuotePdfService.instance.createQuotePdf(
        quoteId: docRef.id,
        customer: customerData,
        products: products,
        total: total,
        createdAt: DateTime.now(),
      );

      final pdfUrl = await _uploadQuotePdf(docRef.id, pdfBytes);

      await docRef.update({
        'pdf_url': pdfUrl,
        'pdf_generated_at': FieldValue.serverTimestamp(),
      });

      return docRef;
    } catch (error) {
      await docRef.delete();
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getQuotes() {
    return _quotesCollection
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> updateQuoteStatus({
    required String quoteId,
    required String status,
  }) {
    return _quotesCollection.doc(quoteId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _uploadQuotePdf(
    String quoteId,
    Uint8List pdfBytes,
  ) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('quotes')
        .child(quoteId)
        .child('offer.pdf');

    await storageRef.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    return storageRef.getDownloadURL();
  }
}
