import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/features/downloads/utils/download_path_utils.dart';
import 'package:path/path.dart' as path;

void main() {
  group('DownloadPathUtils', () {
    group('calculateRelativePath', () {
      test('should extract path structure from standard URL', () {
        const url = 'https://server.com/reciter/narrative/001.mp3';
        const reciter = 'Reciter Name';

        final String result = DownloadPathUtils.calculateRelativePath(
          url,
          reciter,
        );

        // path.joinAll(['reciter', 'narrative', '001.mp3'])
        // On POSIX: reciter/narrative/001.mp3
        expect(result, path.join('reciter', 'narrative', '001.mp3'));
      });

      test('should use reciter name folder when URL has no path structure', () {
        const url = 'https://server.com/001.mp3';
        const reciter = 'Reciter Name';

        final String result = DownloadPathUtils.calculateRelativePath(
          url,
          reciter,
        );

        // Reciter_Name/001.mp3
        expect(result, path.join('Reciter_Name', '001.mp3'));
      });

      test('should handle URL without extension by adding .mp3', () {
        const url = 'https://server.com/reciter/narrative/001';
        const reciter = 'Reciter Name';

        final String result = DownloadPathUtils.calculateRelativePath(
          url,
          reciter,
        );

        expect(result, path.join('reciter', 'narrative', '001.mp3'));
      });

      test('should fallback to default when URL has no path segments', () {
        const url = 'http://server.com';
        const reciter = 'Reciter Name';

        final String result = DownloadPathUtils.calculateRelativePath(
          url,
          reciter,
        );

        expect(result, path.join('Reciter_Name', 'audio.mp3'));
      });

      test('should trim white spaces from URL', () {
        const url = '  https://server.com/reciter/narrative/001.mp3  ';
        const reciter = 'Reciter Name';

        final String result = DownloadPathUtils.calculateRelativePath(
          url,
          reciter,
        );

        expect(result, path.join('reciter', 'narrative', '001.mp3'));
      });

      test('should sanitize reciter name for directory', () {
        const url = 'https://server.com/001.mp3';
        const reciter = 'Reciter With Spaces';

        final String result = DownloadPathUtils.calculateRelativePath(
          url,
          reciter,
        );

        expect(result, path.join('Reciter_With_Spaces', '001.mp3'));
      });
    });

    group('extractNarrativeFromPath', () {
      test('should extract narrative from standard path', () {
        const filePath = 'downloads/reciter/narrative/001.mp3';

        final String result = DownloadPathUtils.extractNarrativeFromPath(
          filePath,
        );

        expect(result, 'narrative');
      });

      test('should extract narrative from deeply nested path', () {
        const filePath =
            '/var/mobile/Containers/Data/Application/ID/Documents/downloads/reciter/narrative/001.mp3';

        final String result = DownloadPathUtils.extractNarrativeFromPath(
          filePath,
        );

        expect(result, 'narrative');
      });

      test('should return Default for short path', () {
        const filePath = 'reciter/001.mp3';

        final String result = DownloadPathUtils.extractNarrativeFromPath(
          filePath,
        );

        expect(result, 'Default');
      });

      test('should return Default for path with only filename', () {
        const filePath = '001.mp3';

        final String result = DownloadPathUtils.extractNarrativeFromPath(
          filePath,
        );

        expect(result, 'Default');
      });

      test('should handle Windows style paths', () {
        const filePath = r'C:\Users\Name\Downloads\reciter\narrative\001.mp3';

        final String result = DownloadPathUtils.extractNarrativeFromPath(
          filePath,
        );

        expect(result, 'narrative');
      });

      test('should handle path with exactly 3 parts', () {
        const filePath = 'reciter/narrative/001.mp3';

        final String result = DownloadPathUtils.extractNarrativeFromPath(
          filePath,
        );

        expect(result, 'narrative');
      });
    });

    group('resolveFullPath', () {
      test('should join directory and relative path', () {
        const dir = '/data/downloads';
        const relative = 'reciter/narrative/001.mp3';

        final String result = DownloadPathUtils.resolveFullPath(dir, relative);

        expect(result, path.join(dir, relative));
      });
    });

    group('getDirectoryName', () {
      test('should return directory name', () {
        final String filePath = path.join('path', 'to', 'file.mp3');

        final String result = DownloadPathUtils.getDirectoryName(filePath);

        expect(result, path.join('path', 'to'));
      });
    });

    group('getFileName', () {
      test('should return file name', () {
        final String filePath = path.join('path', 'to', 'file.mp3');

        final String result = DownloadPathUtils.getFileName(filePath);

        expect(result, 'file.mp3');
      });
    });
  });
}
