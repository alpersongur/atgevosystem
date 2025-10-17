import 'package:flutter/material.dart';

class PermissionTableWidget extends StatelessWidget {
  const PermissionTableWidget({super.key, required this.permissions});

  final Map<String, Map<String, bool>> permissions;

  @override
  Widget build(BuildContext context) {
    if (permissions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('İzin bilgisi bulunmuyor.'),
        ),
      );
    }

    final roles =
        permissions.values.expand((roleMap) => roleMap.keys).toSet().toList()
          ..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İzin Matrisi Özeti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Modül')),
                  ...roles.map(
                    (role) => DataColumn(label: Text(role.toUpperCase())),
                  ),
                ],
                rows: permissions.entries.map((entry) {
                  final module = entry.key;
                  final roleMap = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(module)),
                      ...roles.map((role) {
                        final allowed = roleMap[role] == true;
                        return DataCell(
                          Icon(
                            allowed ? Icons.check_circle : Icons.cancel,
                            color: allowed ? Colors.green : Colors.red,
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
