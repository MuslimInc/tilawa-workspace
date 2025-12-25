import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/core/utils/file_size_formatter.dart';

void main() {
  group('FileSizeFormatter', () {
    group('formatBytes', () {
      test('should return "0 B" for zero bytes', () {
        // act
        final String result = FileSizeFormatter.formatBytes(0);

        // assert
        expect(result, '0 B');
      });

      test('should return "0 B" for negative bytes', () {
        // act
        final String result = FileSizeFormatter.formatBytes(-100);

        // assert
        expect(result, '0 B');
      });

      test('should format bytes correctly', () {
        // act
        final String result = FileSizeFormatter.formatBytes(500);

        // assert
        expect(result, '500 B');
      });

      test('should format kilobytes correctly with default decimals', () {
        // act
        final String result = FileSizeFormatter.formatBytes(1536); // 1.5 KB

        // assert
        expect(result, '1.5 KB');
      });

      test('should format megabytes correctly', () {
        // act
        final String result = FileSizeFormatter.formatBytes(1572864); // 1.5 MB

        // assert
        expect(result, '1.5 MB');
      });

      test('should format gigabytes correctly', () {
        // act
        final String result = FileSizeFormatter.formatBytes(
          1610612736,
        ); // 1.5 GB

        // assert
        expect(result, '1.5 GB');
      });

      test('should format terabytes correctly', () {
        // act
        final String result = FileSizeFormatter.formatBytes(
          1649267441664,
        ); // 1.5 TB

        // assert
        expect(result, '1.5 TB');
      });

      test('should respect custom decimal places', () {
        // act
        final String result = FileSizeFormatter.formatBytes(1536, decimals: 3);

        // assert
        expect(result, '1.500 KB');
      });

      test('should handle zero decimal places', () {
        // act
        final String result = FileSizeFormatter.formatBytes(1536, decimals: 0);

        // assert
        expect(result, '2 KB'); // Rounds to 2
      });

      test('should format exactly 1 KB correctly', () {
        // act
        final String result = FileSizeFormatter.formatBytes(1024);

        // assert
        expect(result, '1.0 KB');
      });

      test('should format exactly 1 MB correctly', () {
        // act
        final String result = FileSizeFormatter.formatBytes(1048576);

        // assert
        expect(result, '1.0 MB');
      });

      test('should format large files correctly', () {
        // act
        final String result = FileSizeFormatter.formatBytes(
          10737418240,
        ); // 10 GB

        // assert
        expect(result, '10.0 GB');
      });
    });
  });
}
