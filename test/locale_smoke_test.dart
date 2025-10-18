import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('DateFormat works for Turkish locale', () async {
    await initializeDateFormatting('tr_TR', null);
    final formatted = DateFormat('MMMM yyyy', 'tr_TR').format(
      DateTime(2025, 1, 1),
    );
    expect(formatted.isNotEmpty, isTrue);
  });
}
