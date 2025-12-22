import 'dart:io';

void main(List<String> args) {
  final start = int.parse(args[0]);
  final end = int.parse(args[1]);
  final lines = File('lib/features/dashboard/presentation/pages/dashboard_page.dart')
      .readAsLinesSync();
  for (var i = start; i <= end && i <= lines.length; i++) {
    final line = lines[i - 1];
    print('L$i: $line');
  }
}
