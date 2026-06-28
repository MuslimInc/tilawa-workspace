import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('TilawaAsyncContent shows loading spinner by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
        home: Scaffold(
          body: TilawaAsyncContent(
            state: TilawaAsyncContentState.loading,
            builder: (context) => const _LoadedContent(),
          ),
        ),
      ),
    );

    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
  });

  testWidgets('TilawaAsyncContent shows skeleton when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
        home: Scaffold(
          body: TilawaAsyncContent(
            state: TilawaAsyncContentState.loading,
            skeleton: Text('Skeleton'),
            builder: (context) => const _LoadedContent(),
          ),
        ),
      ),
    );

    expect(find.text('Skeleton'), findsOneWidget);
    expect(find.byType(TilawaLoadingIndicator), findsNothing);
  });

  testWidgets('TilawaAsyncContent distinguishes empty and error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            MeMuslimDesignTokens.light(),
            MeMuslimComponentTokens.light(),
          ],
        ),
        home: Scaffold(
          body: TilawaAsyncContent(
            state: TilawaAsyncContentState.empty,
            emptyTitle: 'No items',
            builder: (context) => const _LoadedContent(),
          ),
        ),
      ),
    );

    expect(find.text('No items'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            MeMuslimDesignTokens.light(),
            MeMuslimComponentTokens.light(),
          ],
        ),
        home: Scaffold(
          body: TilawaAsyncContent(
            state: TilawaAsyncContentState.error,
            errorTitle: 'Failed to load',
            onRetry: _NoOpCallback.call,
            builder: (context) => const _LoadedContent(),
          ),
        ),
      ),
    );

    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('TilawaAsyncContent shows retry loading on error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            MeMuslimDesignTokens.light(),
            MeMuslimComponentTokens.light(),
          ],
        ),
        home: Scaffold(
          body: TilawaAsyncContent(
            state: TilawaAsyncContentState.error,
            onRetry: _NoOpCallback.call,
            isRetrying: true,
            builder: (context) => const _LoadedContent(),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('TilawaAsyncContent shows content builder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
        home: Scaffold(
          body: TilawaAsyncContent(
            state: TilawaAsyncContentState.content,
            builder: (context) => const _LoadedContent(),
          ),
        ),
      ),
    );

    expect(find.text('Loaded content'), findsOneWidget);
  });
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent();

  @override
  Widget build(BuildContext context) {
    return const Text('Loaded content');
  }
}

abstract final class _NoOpCallback {
  static void call() {}
}
