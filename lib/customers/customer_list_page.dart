import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'customer_form_page.dart';

class CustomersListPage extends StatelessWidget {
  const CustomersListPage({super.key});

  static const routeName = '/customers';

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('customers')
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Veriler getirilirken bir hata oluştu.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Henüz müşteri kaydı yok.'),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final name = data['name'] as String? ?? 'Adsız Müşteri';
              final email = data['email'] as String? ?? '-';
              final phone = data['phone'] as String? ?? '-';
              final address = data['address'] as String? ?? '-';

              return ListTile(
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(email),
                    Text(phone),
                    Text(address),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context)
              .pushNamed<bool>(CustomerFormPage.routeName);
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Müşteri kaydedildi')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
