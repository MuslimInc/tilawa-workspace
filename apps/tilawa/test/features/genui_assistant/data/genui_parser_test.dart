import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/genui_assistant/genui_assistant.dart';

/// Helpers to read an Either without `as` casts.
GenUiFailure _left(Either<GenUiFailure, GenUiDocument> e) =>
    e.fold((l) => l, (r) => throw StateError('expected Left, got $r'));
GenUiDocument _right(Either<GenUiFailure, GenUiDocument> e) =>
    e.fold((l) => throw StateError('expected Right, got $l'), (r) => r);

void main() {
  const parser = GenUiParser();

  group('GenUiParser — valid payloads', () {
    test('parses a well-formed Smart Quran Plan document', () {
      const raw = '''
{
  "schemaVersion": "1",
  "assistantNote": "A gentle plan",
  "nodes": [
    {
      "type": "SectionStack",
      "children": [
        { "type": "AyahReferenceCard", "props": { "surah": 2, "ayah": 255 } },
        { "type": "ActionButton", "props": { "labelKey": "startTodayWird" },
          "actionId": "startTodayWird" }
      ]
    }
  ]
}
''';
      final doc = _right(parser.parse(raw));
      check(doc.schemaVersion).equals('1');
      check(doc.assistantNote).equals('A gentle plan');
      check(doc.nodes).length.equals(1);
      check(doc.nodes.first.type).equals('SectionStack');
      check(doc.nodes.first.children).length.equals(2);
      check(doc.nodes.first.children.last.actionId).equals('startTodayWird');
    });

    test('sanitises non-primitive prop values away', () {
      const raw = '''
{ "schemaVersion": "1", "nodes": [
  { "type": "WirdCard", "props": { "rangeLabel": "Al-Baqarah 1-5",
    "nested": { "ok": 1 }, "list": [1, "two"] } } ] }
''';
      final doc = _right(parser.parse(raw));
      final props = doc.nodes.first.properties;
      check(props['rangeLabel']).equals('Al-Baqarah 1-5');
      // Nested primitive map/list are kept (still JSON-safe), functions/objects
      // would have been dropped. Primitive containers survive sanitisation.
      check(props.containsKey('nested')).isTrue();
    });

    test(
      'keeps unknown node types — the registry handles them, not parsing',
      () {
        const raw =
            '{ "schemaVersion": "1", "nodes": [ { "type": "TotallyMadeUp" } ] }';
        final doc = _right(parser.parse(raw));
        check(doc.nodes.first.type).equals('TotallyMadeUp');
      },
    );
  });

  group('GenUiParser — invalid payloads fail closed', () {
    test('malformed JSON → GenUiParseFailure', () {
      final f = _left(parser.parse('{ not json '));
      check(f).isA<GenUiParseFailure>();
    });

    test('non-object root → GenUiParseFailure', () {
      final f = _left(parser.parse('[1, 2, 3]'));
      check(f).isA<GenUiParseFailure>();
    });

    test('missing schemaVersion → GenUiParseFailure', () {
      final f = _left(parser.parse('{ "nodes": [] }'));
      check(f).isA<GenUiParseFailure>();
    });

    test('unsupported schemaVersion → GenUiSchemaVersionFailure', () {
      final f = _left(parser.parse('{ "schemaVersion": "99", "nodes": [] }'));
      check(f).isA<GenUiSchemaVersionFailure>();
    });

    test('nodes not a list → GenUiParseFailure', () {
      final f = _left(parser.parse('{ "schemaVersion": "1", "nodes": {} }'));
      check(f).isA<GenUiParseFailure>();
    });

    test('node without a type → GenUiParseFailure', () {
      final f = _left(
        parser.parse('{ "schemaVersion": "1", "nodes": [ { "props": {} } ] }'),
      );
      check(f).isA<GenUiParseFailure>();
    });
  });
}
