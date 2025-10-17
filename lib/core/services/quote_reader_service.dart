import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

import 'package:atgevosystem/core/models/quote.dart';

class QuoteReaderService {
  QuoteReaderService._(this._firestore);

  factory QuoteReaderService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return QuoteReaderService._(firestore);
    }
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return instance;
  }

  static QuoteReaderService? _instance;
  static QuoteReaderService? _testInstance;

  static QuoteReaderService get instance {
    final override = _testInstance;
    if (override != null) {
      return override;
    }
    return _instance ??= QuoteReaderService._(FirebaseFirestore.instance);
  }

  @visibleForTesting
  static void setTestInstance(QuoteReaderService service) {
    _testInstance = service;
  }

  @visibleForTesting
  static void resetTestInstance() {
    _testInstance = null;
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('quotes');

  Stream<List<QuoteModel>> watchQuotes() {
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
}
