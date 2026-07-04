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
    bool changed = false;
    
    final RegExp badImport1 = RegExp(r"import 'package:ui_kit/ui_kit\.dart';[\n\r]*");
    final RegExp badImport2 = RegExp(r"import 'package:ui_kit/tilawa_ui_kit\.dart';[\n\r]*");
    
    if (badImport1.hasMatch(content)) {
      content = content.replaceAll(badImport1, '');
      changed = true;
    }
    if (badImport2.hasMatch(content)) {
      content = content.replaceAll(badImport2, '');
      changed = true;
    }
    
    if (changed) {
      file.writeAsStringSync(content);
      print('Cleaned $path');
    }
  }
}
