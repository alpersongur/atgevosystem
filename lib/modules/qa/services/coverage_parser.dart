import 'dart:convert';

class CoverageParser {
  const CoverageParser._();

  static double? parseLcov(List<int> bytes) {
    final content = utf8.decode(bytes, allowMalformed: true);
    int linesFound = 0;
    int linesHit = 0;
    for (final line in content.split(RegExp(r'\r?\n'))) {
      if (line.startsWith('LF:')) {
        final value = int.tryParse(line.substring(3).trim());
        if (value != null) {
          linesFound = value;
        }
      } else if (line.startsWith('LH:')) {
        final value = int.tryParse(line.substring(3).trim());
        if (value != null) {
          linesHit = value;
        }
      }
    }
    if (linesFound == 0) {
      return null;
    }
    return (linesHit / linesFound) * 100;
  }
}
