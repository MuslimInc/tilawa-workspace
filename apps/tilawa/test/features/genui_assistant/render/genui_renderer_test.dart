import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/genui_assistant/genui_assistant.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _NoopExecutor implements GenUiIntentExecutor {
  @override
  void execute(GenUiIntent intent) {}
}

Widget _host(GenUiDocument document) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Scaffold(
      body: SingleChildScrollView(
        child: GenUiRenderer(
          document: document,
          registry: GenUiComponentRegistry.defaults(),
          dispatcher: GenUiActionDispatcher(executor: _NoopExecutor()),
          content: const DefaultTrustedContentResolver(
            surahNames: <int, String>{2: 'Al-Baqarah'},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('GenUiRenderer — valid plan', () {
    testWidgets('maps whitelisted nodes onto ui_kit widgets', (tester) async {
      const document = GenUiDocument(
        schemaVersion: '1',
        assistantNote: 'A gentle plan',
        nodes: <GenUiNode>[
          GenUiNode(
            type: 'SectionStack',
            children: <GenUiNode>[
              GenUiNode(
                type: 'PlanHeader',
                properties: {'titleKey': 'smartQuranPlan'},
              ),
              GenUiNode(
                type: 'AyahReferenceCard',
                properties: {'surah': 2, 'ayah': 255},
              ),
              GenUiNode(
                type: 'ActionButton',
                properties: {'labelKey': 'startTodayWird'},
                actionId: 'startTodayWird',
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_host(document));

      // Design-system mapping: real ui_kit widgets, not raw Material.
      check(find.byType(TilawaSectionHeader).evaluate().isNotEmpty).isTrue();
      check(find.byType(TilawaButton).evaluate().isNotEmpty).isTrue();
      check(find.byType(TilawaCard).evaluate().isNotEmpty).isTrue();

      // Trusted content: ayah label comes from the resolver, not the payload.
      expect(find.text('Al-Baqarah · 255'), findsOneWidget);

      // Standing disclosure is always present and cannot be omitted.
      expect(find.text(GenUiStrings.aiDisclosure), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('GenUiRenderer — unknown component', () {
    testWidgets('renders a safe fallback, never crashes', (tester) async {
      const document = GenUiDocument(
        schemaVersion: '1',
        nodes: <GenUiNode>[
          GenUiNode(type: 'HolographicFatwaWidget'),
        ],
      );

      await tester.pumpWidget(_host(document));

      check(find.byType(GenUiUnknownComponent).evaluate().isNotEmpty).isTrue();
      expect(find.text(GenUiStrings.unknownComponent), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AyahReferenceCard with an invalid surah degrades safely', (
      tester,
    ) async {
      const document = GenUiDocument(
        schemaVersion: '1',
        nodes: <GenUiNode>[
          GenUiNode(type: 'AyahReferenceCard', properties: {'surah': 999}),
        ],
      );

      await tester.pumpWidget(_host(document));

      check(find.byType(GenUiUnknownComponent).evaluate().isNotEmpty).isTrue();
      expect(tester.takeException(), isNull);
    });
  });
}
