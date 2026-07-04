import 'dart:io';

void main() {
  final files = [
    'apps/tilawa/test/features/reciters/presentation/screens/reciters_screen_tabs_test.dart',
    'apps/tilawa/test/features/reciters/presentation/widgets/reciters_alphabet_interaction_test.dart',
    'apps/tilawa/test/features/reciters/presentation/widgets/reciters_alphabet_scrub_coverage_test.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    if (content.contains('find.byType(RefreshIndicator)')) {
      content = content.replaceAll('find.byType(RefreshIndicator)', 'find.byType(TilawaRefreshIndicator)');
      file.writeAsStringSync(content);
      print('Updated $path');
    }
  }
}
