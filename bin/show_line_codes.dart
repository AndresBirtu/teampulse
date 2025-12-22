import 'dart:io';

void main(List<String> args) {
  final lineNumber = int.parse(args[0]);
  final lines = File('lib/features/dashboard/presentation/pages/dashboard_page.dart')
      .readAsLinesSync();
  final line = lines[lineNumber - 1];
  final codes = line.codeUnits.map((c) => c.toString()).join(',');
  print('L$lineNumber: "$line"');
  print('codes: $codes');
}
