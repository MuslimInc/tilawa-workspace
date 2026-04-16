import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';

void extractIsolateEntryPoint(ExtractMessage message) {
  try {
    final inputStream = InputFileStream(message.archivePath);
    final archive = ZipDecoder().decodeStream(inputStream);
    var count = 0;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final outFile = File('${message.destinationPath}/${file.name}');
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(file.content as List<int>);
      count++;
      // Report every 50 files to avoid flooding the port.
      if (count % 50 == 0) message.sendPort.send(count);
    }
    inputStream.closeSync();
    message.sendPort.send(ExtractDone(count));
  } catch (e) {
    message.sendPort.send(ExtractDone(0, error: e.toString()));
  }
}

class ExtractMessage {
  const ExtractMessage({
    required this.archivePath,
    required this.destinationPath,
    required this.sendPort,
  });

  final String archivePath;
  final String destinationPath;
  final SendPort sendPort;
}

class ExtractDone {
  const ExtractDone(this.count, {this.error});

  final int count;
  final String? error;
}
