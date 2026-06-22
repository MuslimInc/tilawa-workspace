import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/genui_assistant/genui_assistant.dart';

GenUiNode _node(String? actionId, [Map<String, Object?> props = const {}]) =>
    GenUiNode(type: 'ActionButton', properties: props, actionId: actionId);

void main() {
  const resolver = GenUiActionResolver();

  group('GenUiActionResolver — allowlist', () {
    test('unknown action id is rejected', () {
      final r = resolver.resolve(_node('deleteAllData'));
      check(r).isA<GenUiActionRejected>();
    });

    test('null action id is rejected', () {
      final r = resolver.resolve(_node(null));
      check(r).isA<GenUiActionRejected>();
    });

    test('every allowlisted id has a resolution path', () {
      // Guard: the switch must cover exactly the published allowlist.
      for (final id in GenUiActionResolver.allowedActionIds) {
        final r = resolver.resolve(_node(id, _validPropsFor(id)));
        check(r).isA<GenUiActionAccepted>();
      }
    });
  });

  group('GenUiActionResolver — typed intents + bounds', () {
    test('openQuranReader maps to a bounded intent', () {
      final r = resolver.resolve(
        _node('openQuranReader', {'surah': 2, 'ayah': 255}),
      );
      check(r)
          .isA<GenUiActionAccepted>()
          .has((a) => a.intent, 'intent')
          .isA<OpenQuranReaderIntent>()
        ..has((i) => i.surah, 'surah').equals(2)
        ..has((i) => i.ayah, 'ayah').equals(255);
    });

    test('openQuranReader with surah out of range is rejected', () {
      check(
        resolver.resolve(_node('openQuranReader', {'surah': 0})),
      ).isA<GenUiActionRejected>();
      check(
        resolver.resolve(_node('openQuranReader', {'surah': 115})),
      ).isA<GenUiActionRejected>();
    });

    test('openAthkar rejects an unknown category', () {
      check(
        resolver.resolve(_node('openAthkar', {'category': 'mystery'})),
      ).isA<GenUiActionRejected>();
    });

    test('setReminder rejects an out-of-range hour', () {
      check(
        resolver.resolve(
          _node('setReminder', {'kind': 'wird', 'hour': 99}),
        ),
      ).isA<GenUiActionRejected>();
    });

    test('savePlan requires a draft id', () {
      check(resolver.resolve(_node('savePlan', {}))).isA<GenUiActionRejected>();
      check(
        resolver.resolve(_node('savePlan', {'planDraftId': 'd1'})),
      ).isA<GenUiActionAccepted>();
    });
  });
}

Map<String, Object?> _validPropsFor(String id) => switch (id) {
  'openQuranReader' => {'surah': 1},
  'openAthkar' => {'category': 'morning'},
  'setReminder' => {'kind': 'wird', 'hour': 6, 'minute': 0},
  'savePlan' => {'planDraftId': 'draft-1'},
  _ => const {},
};
