import 'dart:isolate';

Future<void> main() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:teampulse/features/dashboard/presentation/pages/dashboard_page.dart'),
  );
  final raw = uri?.toString();
  print(raw);
  if (raw != null) {
    final escaped = raw
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
    print('escaped:$escaped');
  }
}
