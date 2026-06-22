import 'dart:convert';

import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/genui_document.dart';
import '../../domain/entities/genui_node.dart';
import '../../domain/entities/genui_schema.dart';
import '../../domain/failures/genui_failure.dart';

/// Turns an untrusted JSON string into a validated [GenUiDocument].
///
/// This is the *schema gate*. It is total over malformed input: any parse error
/// returns a [GenUiFailure] (never throws), and a document whose
/// `schemaVersion` is missing or unsupported is rejected wholesale. Node
/// `type`/`actionId` strings are *not* validated here — that is deliberately the
/// job of the component whitelist and action allowlist at render/dispatch time,
/// so an unknown component degrades gracefully instead of nuking the document.
///
/// Props are sanitised to JSON primitives (String/num/bool) and nested
/// primitive lists/maps; anything else is dropped, so a hostile payload cannot
/// smuggle structure the renderer doesn't expect.
class GenUiParser {
  const GenUiParser({this.supportedSchemaVersion = GenUiSchema.version});

  final String supportedSchemaVersion;

  Either<GenUiFailure, GenUiDocument> parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      return Left(GenUiParseFailure('Invalid JSON: ${e.message}'));
    }

    if (decoded is! Map<String, Object?>) {
      return const Left(GenUiParseFailure('Document root must be an object'));
    }

    final Object? version = decoded['schemaVersion'];
    if (version is! String) {
      return const Left(GenUiParseFailure('Missing schemaVersion'));
    }
    if (version != supportedSchemaVersion) {
      return Left(
        GenUiSchemaVersionFailure(
          expected: supportedSchemaVersion,
          received: version,
        ),
      );
    }

    final Object? rawNodes = decoded['nodes'];
    if (rawNodes is! List) {
      return const Left(GenUiParseFailure('"nodes" must be a list'));
    }

    final List<GenUiNode> nodes;
    try {
      nodes = rawNodes.map(_parseNode).toList(growable: false);
    } on FormatException catch (e) {
      return Left(GenUiParseFailure(e.message));
    }

    final Object? note = decoded['assistantNote'];
    return Right(
      GenUiDocument(
        schemaVersion: version,
        nodes: nodes,
        assistantNote: note is String ? note : null,
      ),
    );
  }

  GenUiNode _parseNode(Object? raw) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('Each node must be an object');
    }
    final Object? type = raw['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('Each node needs a non-empty "type"');
    }

    final Object? rawChildren = raw['children'];
    final List<GenUiNode> children = rawChildren is List
        ? rawChildren.map(_parseNode).toList(growable: false)
        : const <GenUiNode>[];

    final Object? rawProps = raw['props'];
    final Map<String, Object?> props = rawProps is Map<String, Object?>
        ? _sanitiseProps(rawProps)
        : const <String, Object?>{};

    final Object? actionId = raw['actionId'];

    return GenUiNode(
      type: type,
      properties: props,
      children: children,
      actionId: actionId is String ? actionId : null,
    );
  }

  Map<String, Object?> _sanitiseProps(Map<String, Object?> raw) {
    final Map<String, Object?> out = <String, Object?>{};
    raw.forEach((String key, Object? value) {
      final Object? clean = _sanitiseValue(value);
      if (clean != null) out[key] = clean;
    });
    return out;
  }

  Object? _sanitiseValue(Object? value) {
    if (value is String || value is num || value is bool) return value;
    if (value is List) {
      return value.map(_sanitiseValue).where((Object? v) => v != null).toList();
    }
    if (value is Map<String, Object?>) return _sanitiseProps(value);
    return null;
  }
}
