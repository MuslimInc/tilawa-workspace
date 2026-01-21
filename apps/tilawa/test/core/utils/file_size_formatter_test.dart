import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/utils/file_size_formatter.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  group('FileSizeFormatter', () {
    testWidgets('should return "0 B" for zero bytes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(context, 0);
              expect(result, '0 B');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should return "0 B" for negative bytes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                -100,
              );
              expect(result, '0 B');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should format bytes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(context, 500);
              expect(result, '500 B');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should format kilobytes correctly with default decimals', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                1536,
              ); // 1.5 KB
              expect(result, '1.5 KB');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should format megabytes correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                1572864,
              ); // 1.5 MB
              expect(result, '1.5 MB');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should format gigabytes correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                1610612736,
              ); // 1.5 GB
              expect(result, '1.5 GB');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should format terabytes correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                1649267441664,
              ); // 1.5 TB
              expect(result, '1.5 TB');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should respect custom decimal places', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                1536,
                decimals: 3,
              );
              expect(result, '1.500 KB');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should handle zero decimal places', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                1536,
                decimals: 0,
              );
              expect(result, '2 KB'); // Rounds to 2
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should format exactly 1 KB correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                1024,
              );
              expect(result, '1.0 KB');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should format exactly 1 MB correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                1048576,
              );
              expect(result, '1.0 MB');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should format large files correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final String result = FileSizeFormatter.formatBytes(
                context,
                10737418240,
              ); // 10 GB
              expect(result, '10.0 GB');
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
