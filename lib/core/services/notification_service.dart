import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:atgevosystem/modules/tenant/services/tenant_service.dart';

class SystemNotification {
  const SystemNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.target,
    required this.read,
    required this.createdAt,
  });

  factory SystemNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return SystemNotification(
      id: doc.id,
      type: (data['type'] as String? ?? 'info').trim(),
      title: (data['title'] as String? ?? '').trim(),
      message: (data['message'] as String? ?? '').trim(),
      target: (data['target'] as String? ?? '').trim(),
      read: data['read'] as bool? ?? false,
      createdAt: _toDate(data['created_at']),
    );
  }

  final String id;
  final String type;
  final String title;
  final String message;
  final String target;
  final bool read;
  final DateTime? createdAt;

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class NotificationService {
  NotificationService._({FirebaseFirestore? firestore})
      : _firestoreProvider = firestore != null
            ? (() => firestore)
            : (() => TenantService.instance.firestore);

  factory NotificationService({FirebaseFirestore? firestore}) {
    if (firestore == null) return instance;
    return NotificationService._(firestore: firestore);
  }

  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore Function() _firestoreProvider;

  FirebaseFirestore get _firestore => _firestoreProvider();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('system_notifications');

  Stream<List<SystemNotification>> streamNotifications({
    bool unreadOnly = false,
  }) {
    Query<Map<String, dynamic>> query = _collection
        .orderBy('created_at', descending: true)
        .limit(200);
    if (unreadOnly) {
      query = query.where('read', isEqualTo: false);
    }
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(SystemNotification.fromDoc).toList(growable: false),
    );
  }

  Stream<int> streamUnreadCount() {
    final unreadQuery = _collection.where('read', isEqualTo: false);
    return unreadQuery.snapshots().asyncMap((_) async {
      final aggregate = await unreadQuery.count().get();
      return aggregate.count ?? 0;
    }).distinct();
  }

  Future<void> markAsRead(String id) async {
    await _collection.doc(id).update({
      'read': true,
      'read_at': FieldValue.serverTimestamp(),
    });
  }
}
