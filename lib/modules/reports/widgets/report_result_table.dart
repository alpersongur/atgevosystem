import 'package:flutter/material.dart';

import '../models/report_request_model.dart';

class ReportResultTable extends StatelessWidget {
  const ReportResultTable({super.key, required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    if (data.rows.isEmpty) {
      return const Center(child: Text('Bu kriterlere uygun kayıt bulunamadı.'));
    }

    final columns = data.columns;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns
            .map((column) => DataColumn(label: Text(column.label)))
            .toList(growable: false),
        rows: data.rows
            .map(
              (row) => DataRow(
                cells: row
                    .map((value) => DataCell(Text('$value')))
                    .toList(growable: false),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
