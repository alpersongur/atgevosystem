import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class ApiKeyRecord {
  const ApiKeyRecord({
    required this.id,
    required this.companyId,
    required this.createdAt,
    required this.status,
    required this.scopes,
    this.last8,
  });

  final String id;
  final String companyId;
  final DateTime createdAt;
  final String status;
  final List<String> scopes;
  final String? last8;
}

class ApiKeysService {
  ApiKeysService._();

  static final ApiKeysService instance = ApiKeysService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('api_keys');
  }

  Stream<List<ApiKeyRecord>> watchKeys(String companyId) {
    return _collection(companyId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ApiKeyRecord(
                  id: doc.id,
                  companyId: companyId,
                  createdAt:
                      (doc.data()['created_at'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  status: doc.data()['status'] as String? ?? 'active',
                  scopes:
                      (doc.data()['scopes'] as List?)
                          ?.map((scope) => scope.toString())
                          .toList() ??
                      const [],
                  last8: doc.data()['last8'] as String?,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<ApiKeyCreationResult> createKey(
    String companyId,
    List<String> scopes,
  ) async {
    final rawKey = _generateKey();
    final hashed = sha256.convert(rawKey.codeUnits).toString();
    final docRef = _collection(companyId).doc();
    final payload = <String, dynamic>{
      'hashed_key': hashed,
      'status': 'active',
      'scopes': scopes,
      'created_at': FieldValue.serverTimestamp(),
      'last8': rawKey.substring(rawKey.length - 8),
    };
    await docRef.set(payload);
    return ApiKeyCreationResult(
      keyId: docRef.id,
      companyId: companyId,
      plainKey: rawKey,
      scopes: scopes,
    );
  }

  Future<void> revokeKey(String companyId, String keyId) {
    return _collection(companyId).doc(keyId).update({
      'status': 'revoked',
      'revoked_at': FieldValue.serverTimestamp(),
    });
  }

  String _generateKey({int length = 40}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}

class ApiKeyCreationResult {
  const ApiKeyCreationResult({
    required this.keyId,
    required this.companyId,
    required this.plainKey,
    required this.scopes,
  });

  final String keyId;
  final String companyId;
  final String plainKey;
  final List<String> scopes;
}
