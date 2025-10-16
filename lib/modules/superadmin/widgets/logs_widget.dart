import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LogsWidget extends StatelessWidget {
  const LogsWidget({
    super.key,
    required this.stream,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Loglar yüklenemedi\n${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Log kaydı bulunmuyor.'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Son Loglar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...docs.map((doc) {
                  final data = doc.data();
                  final message = data['message'] as String? ?? 'Log mesajı yok';
                  final timestamp = data['timestamp'];
                  DateTime? time;
                  if (timestamp is Timestamp) {
                    time = timestamp.toDate();
                  }
                  final formatted = time == null
                      ? '---'
                      : '${time.day}.${time.month}.${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(message),
                    subtitle: Text(formatted),
                  );
                })
              ],
            ),
          ),
        );
      },
    );
  }
}
