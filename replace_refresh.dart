import 'dart:io';

void main() {
  final files = [
    'packages/quran_sessions/lib/src/presentation/screens/my_sessions_screen.dart',
    'packages/quran_sessions/lib/src/presentation/screens/teacher_dashboard_screen.dart',
    'packages/quran_sessions/lib/src/presentation/screens/session_detail_screen.dart',
    'packages/quran_sessions/lib/src/presentation/screens/wallet_screen.dart',
    'packages/quran_sessions/lib/src/presentation/screens/teacher_list_screen.dart',
    'apps/tilawa/lib/features/history/presentation/screens/history_screen.dart',
    'apps/tilawa/lib/features/prayer_times/presentation/screens/prayer_times_screen.dart',
    'apps/tilawa/lib/features/reciters/presentation/screens/reciter_details_screen.dart',
    'apps/tilawa/lib/features/reciters/presentation/screens/reciters_screen.dart',
    'apps/tilawa/lib/features/home/presentation/screens/home_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    if (content.contains('RefreshIndicator(')) {
      content = content.replaceAll('RefreshIndicator(', 'TilawaRefreshIndicator(');
      
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
