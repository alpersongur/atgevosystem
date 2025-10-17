import 'package:cloud_firestore/cloud_firestore.dart';

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
  NotificationService._(this._firestore);

  factory NotificationService({FirebaseFirestore? firestore}) {
    if (firestore == null) return instance;
    return NotificationService._(firestore);
  }

  static final NotificationService instance =
      NotificationService._(FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;

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
          (snapshot) => snapshot.docs
              .map(SystemNotification.fromDoc)
              .toList(growable: false),
        );
  }

  Stream<int> streamUnreadCount() {
    return _collection
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String id) async {
    await _collection.doc(id).update({
      'read': true,
      'read_at': FieldValue.serverTimestamp(),
    });
  }
}
