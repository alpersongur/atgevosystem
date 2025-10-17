import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:atgevosystem/core/utils/timestamp_helper.dart';

import 'package:atgevosystem/core/models/quote.dart';
import 'quote_pdf_service.dart';

class QuoteService with FirestoreTimestamps {
  QuoteService._(this._firestore, this._storage);

  factory QuoteService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) {
    if (firestore == null && storage == null) {
      return instance;
    }
    return QuoteService._(
      firestore ?? FirebaseFirestore.instance,
      storage ?? FirebaseStorage.instance,
    );
  }

  static final QuoteService instance = QuoteService._(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('quotes');

  Stream<List<QuoteModel>> getQuotes() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(QuoteModel.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<QuoteModel?> watchQuote(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return QuoteModel.fromDocument(snapshot);
    });
  }

  Future<QuoteModel?> getQuoteById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return QuoteModel.fromDocument(doc);
  }

  Future<String> addQuote(Map<String, dynamic> data) async {
    final payload = _preparePayload(data, isUpdate: false);
    final docRef = await _collection.add(payload);

    await _maybeGeneratePdf(docRef.id, data);

    return docRef.id;
  }

  Future<void> updateQuote(String id, Map<String, dynamic> data) async {
    final payload = _preparePayload(data, isUpdate: true);
    await _collection.doc(id).update(payload);
  }

  Future<void> deleteQuote(String id) async {
    await _collection.doc(id).delete();
    await _deleteStoredPdf(id);
  }

  Map<String, dynamic> _preparePayload(
    Map<String, dynamic> data, {
    required bool isUpdate,
  }) {
    var payload = Map<String, dynamic>.from(data);

    // Normalize valid_until
    final validUntil = payload['valid_until'];
    if (validUntil is DateTime) {
      payload['valid_until'] = Timestamp.fromDate(validUntil);
    } else if (validUntil is String && validUntil.isNotEmpty) {
      try {
        payload['valid_until'] = Timestamp.fromDate(DateTime.parse(validUntil));
      } catch (_) {
        payload['valid_until'] = validUntil;
      }
    } else if (validUntil == null) {
      payload.remove('valid_until');
    }

    payload = isUpdate
        ? withUpdateTimestamp(payload)
        : withCreateTimestamps(payload);

    return payload;
  }

  Future<void> _maybeGeneratePdf(
    String quoteId,
    Map<String, dynamic> data,
  ) async {
    final productsRaw = data['products'];
    final total = (data['total'] as num?)?.toDouble();
    final customerId = data['customer_id'] as String?;

    if (productsRaw == null ||
        total == null ||
        customerId == null ||
        customerId.isEmpty) {
      return;
    }

    final products = (productsRaw as List)
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
        )
        .toList(growable: false);

    final customerDoc = await _firestore
        .collection('customers')
        .doc(customerId)
        .get();
    final customerData = customerDoc.data();

    if (customerData == null) return;

    final pdfBytes = await QuotePdfService.instance.createQuotePdf(
      quoteId: quoteId,
      customer: customerData,
      products: products,
      total: total,
      createdAt: DateTime.now(),
    );

    final pdfUrl = await _uploadQuotePdf(quoteId, pdfBytes);

    await _collection.doc(quoteId).update({
      'pdf_url': pdfUrl,
      'pdf_generated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _uploadQuotePdf(String quoteId, Uint8List pdfBytes) async {
    final storageRef = _storage
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

  Future<void> _deleteStoredPdf(String quoteId) async {
    final ref = _storage
        .ref()
        .child('quotes')
        .child(quoteId)
        .child('offer.pdf');
    try {
      await ref.delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }
}
