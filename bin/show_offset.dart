import 'dart:io';

void main(List<String> args) {
  final file = File('lib/features/dashboard/presentation/pages/dashboard_page.dart');
  final content = file.readAsStringSync();
  final offset = int.parse(args.first);
  final snippetStart = offset - 200 < 0 ? 0 : offset - 200;
  final snippetEnd = offset + 200 > content.length ? content.length : offset + 200;
  final snippet = content.substring(snippetStart, snippetEnd);
  print('Snippet around offset $offset:\n$snippet');
}
