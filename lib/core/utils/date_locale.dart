import 'package:intl/intl.dart';

class DateLocale {
  const DateLocale._();

  static String fmt(DateTime date, [String pattern = 'dd.MM.yyyy']) {
    return DateFormat(pattern, Intl.defaultLocale).format(date);
  }

  static String? fmtNullable(DateTime? date, [String pattern = 'dd.MM.yyyy']) {
    if (date == null) return null;
    return fmt(date, pattern);
  }
}
