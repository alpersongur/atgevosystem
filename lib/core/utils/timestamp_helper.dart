import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

/// Ortak Firestore zaman damgası yardımcıları.
///
/// Hizmet katmanındaki CRUD işlemleri için `created_at` ve `updated_at`
/// alanlarının tutarlı şekilde setlenmesini sağlar.
mixin FirestoreTimestamps {
  @protected
  Map<String, dynamic> withCreateTimestamps(Map<String, dynamic> data) {
    return <String, dynamic>{
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  @protected
  Map<String, dynamic> withUpdateTimestamp(Map<String, dynamic> data) {
    return <String, dynamic>{
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
