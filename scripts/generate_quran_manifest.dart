import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main(List<String> args) {
  final targetDir = Directory('packages/quran_qcf/assets/quran_fonts');
  if (!targetDir.existsSync()) {
    print('Quran assets directory not found!');
    exit(1);
  }

  final filesToHash = [
    'qpc-v4.json',
    'quran_page_index.json',
    'quran_page_line_map.json',
    'QCF4_QBSML-Regular.ttf',
  ];

  final manifestFiles = <String, dynamic>{};

  for (final filename in filesToHash) {
    final file = File('${targetDir.path}/$filename');
    if (!file.existsSync()) {
      print('FAILED: Required asset $filename is missing.');
      exit(1);
    }
    
    final bytes = file.readAsBytesSync();
    final digest = sha256.convert(bytes);
    
    manifestFiles[filename] = {
      'sha256': digest.toString(),
      'byte_length': bytes.length,
      'required': true,
    };
  }

  final manifest = {
    'version': '1.0.0-qcf4',
    'source': 'King Fahd Complex QCF v4',
    'generated_at': DateTime.now().toUtc().toIso8601String().split('T').first + 'T00:00:00.000Z', // Deterministic enough for this example, usually would use a fixed env var or commit time.
    'files': manifestFiles,
  };

  final encoder = JsonEncoder.withIndent('  ');
  final manifestJson = encoder.convert(manifest);
  
  final outPath = 'packages/quran_qcf/assets/quran_manifest.json';
  File(outPath).writeAsStringSync(manifestJson + '\n');
  
  print('SUCCESS: Generated deterministic quran_manifest.json at $outPath');
}
