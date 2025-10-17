import 'package:flutter/material.dart';

class QaFailuresList extends StatelessWidget {
  const QaFailuresList({super.key, required this.failures});

  final List<String> failures;

  @override
  Widget build(BuildContext context) {
    if (failures.isEmpty) {
      return const Text('Başarısız test bulunmuyor.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: failures.length,
      separatorBuilder: (context, _) => const Divider(),
      itemBuilder: (context, index) {
        final failure = failures[index];
        return ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.redAccent),
          title: Text(failure),
        );
      },
    );
  }
}
