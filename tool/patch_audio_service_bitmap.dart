// Idempotent patch for audio_service Android BitmapFactory usage.
//
// Play Console flags `AudioService.loadArtBitmap` when any decode* call site
// omits BitmapFactory.Options (static APK scan). Upstream keeps a full-res
// else-branch when artDownscale* is unset; that branch survives in the APK even
// when the app configures downscaling at runtime.
//
// Run: dart run tool/patch_audio_service_bitmap.dart
// Also applied from melos bootstrap (post) and Android settings.gradle.

import 'dart:io';

const _marker = 'Always pass BitmapFactory.Options';

const _oldBlock = '''
            // Decode the image ourselves for scenarios 1 and 3 (see the comment above).
            if (!usesContentScheme || fileDescriptor != null) {
                if (config.artDownscaleWidth != -1) {
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    options.inJustDecodeBounds = true;
                    if (fileDescriptor != null) {
                        BitmapFactory.decodeFileDescriptor(fileDescriptor, null, options);
                    } else {
                        BitmapFactory.decodeFile(artUri.getPath(), options);
                    }
                    options.inSampleSize = calculateInSampleSize(options, config.artDownscaleWidth, config.artDownscaleHeight);
                    options.inJustDecodeBounds = false;

                    if (fileDescriptor != null) {
                        bitmap = BitmapFactory.decodeFileDescriptor(fileDescriptor, null, options);
                    } else {
                        bitmap = BitmapFactory.decodeFile(artUri.getPath(), options);
                    }
                } else {
                    if (fileDescriptor != null) {
                        bitmap = BitmapFactory.decodeFileDescriptor(fileDescriptor);
                    } else {
                        bitmap = BitmapFactory.decodeFile(artUri.getPath());
                    }
                }
            }
''';

const _newBlock = '''
            // Decode the image ourselves for scenarios 1 and 3 (see the comment above).
            // Always pass BitmapFactory.Options so Play/App Bundle scanners never see a
            // full-resolution decode* call site (Technical quality: bitmap downsampling).
            if (!usesContentScheme || fileDescriptor != null) {
                BitmapFactory.Options options = new BitmapFactory.Options();
                if (config.artDownscaleWidth != -1) {
                    options.inJustDecodeBounds = true;
                    if (fileDescriptor != null) {
                        BitmapFactory.decodeFileDescriptor(fileDescriptor, null, options);
                    } else {
                        BitmapFactory.decodeFile(artUri.getPath(), options);
                    }
                    options.inSampleSize = calculateInSampleSize(options, config.artDownscaleWidth, config.artDownscaleHeight);
                    options.inJustDecodeBounds = false;
                }

                if (fileDescriptor != null) {
                    bitmap = BitmapFactory.decodeFileDescriptor(fileDescriptor, null, options);
                } else {
                    bitmap = BitmapFactory.decodeFile(artUri.getPath(), options);
                }
            }
''';

void main() {
  final String pubCache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}${Platform.pathSeparator}.pub-cache';
  final Directory hosted = Directory(
    '$pubCache${Platform.pathSeparator}hosted${Platform.pathSeparator}pub.dev',
  );
  if (!hosted.existsSync()) {
    stderr.writeln('PUB_CACHE hosted/pub.dev not found: ${hosted.path}');
    exit(1);
  }

  var patched = 0;
  var already = 0;
  var skipped = 0;

  for (final FileSystemEntity entity in hosted.listSync()) {
    if (entity is! Directory) continue;
    final String name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (!name.startsWith('audio_service-0.')) continue;

    final File java = File(
      '${entity.path}${Platform.pathSeparator}android'
      '${Platform.pathSeparator}src${Platform.pathSeparator}main'
      '${Platform.pathSeparator}java${Platform.pathSeparator}com'
      '${Platform.pathSeparator}ryanheise${Platform.pathSeparator}audioservice'
      '${Platform.pathSeparator}AudioService.java',
    );
    if (!java.existsSync()) {
      skipped++;
      continue;
    }

    final String text = java.readAsStringSync();
    if (text.contains(_marker)) {
      already++;
      stdout.writeln('already patched: ${java.path}');
      continue;
    }
    if (!text.contains(_oldBlock)) {
      stderr.writeln(
        'unexpected AudioService.java layout (upgrade patch?): ${java.path}',
      );
      skipped++;
      continue;
    }

    java.writeAsStringSync(text.replaceFirst(_oldBlock, _newBlock));
    patched++;
    stdout.writeln('patched: ${java.path}');
  }

  stdout.writeln(
    'audio_service bitmap patch: patched=$patched already=$already skipped=$skipped',
  );
  if (patched == 0 && already == 0) {
    stderr.writeln('No audio_service-0.* package found under ${hosted.path}');
    exit(1);
  }
}
