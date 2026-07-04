import 'dart:io';

void main() {
  final files = [
    'apps/tilawa/lib/features/home/presentation/screens/home_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    if (content.contains('RefreshIndicator.adaptive(')) {
      content = content.replaceAll('RefreshIndicator.adaptive(', 'TilawaRefreshIndicator.adaptive(');
      
      // Add import if not present
      if (!content.contains("package:ui_kit/ui_kit.dart") && !content.contains("'package:ui_kit/ui_kit.dart'")) {
        // Find last import
        final importIdx = content.lastIndexOf(RegExp(r'^import .*?;$', multiLine: true));
        if (importIdx != -1) {
          final endOfImport = content.indexOf(';', importIdx) + 1;
          content = content.substring(0, endOfImport) + '\nimport \'package:ui_kit/ui_kit.dart\';' + content.substring(endOfImport);
        } else {
          content = 'import \'package:ui_kit/ui_kit.dart\';\n' + content;
        }
      }
      file.writeAsStringSync(content);
      print('Updated $path');
    }
  }
}
