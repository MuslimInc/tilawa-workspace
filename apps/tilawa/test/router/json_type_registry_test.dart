import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tilawa/router/json_type_registry.dart';

// An object that is NOT registered and has no toJson — mirrors an in-session
// route `extra` such as PrayerAlertsPermissionNavExtra.
@immutable
class UnregisteredExtra {
  const UnregisteredExtra();
}

// Simple test class implementing toJson/fromJson pattern
@immutable
class TestObject {
  const TestObject(this.id, this.content);

  factory TestObject.fromJson(Map<String, dynamic> json) {
    return TestObject(json['id'] as int, json['content'] as String);
  }
  final int id;
  final String content;

  Map<String, dynamic> toJson() => {'id': id, 'content': content};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestObject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content;

  @override
  int get hashCode => id.hashCode ^ content.hashCode;
}

void main() {
  group('JsonTypeRegistry', () {
    late JsonTypeRegistry registry;

    setUp(() {
      registry = JsonTypeRegistry();
      // Since it's a singleton, we need to be careful.
      // However, multiple registers of same key behave fine in our impl (map overwrite).
      // But _encoders list grows. This is a limitation of singleton testing without clear method.
      // for now we just register our test type.
      registry.register('TestObject', TestObject.fromJson);
    });

    test('should encode registered object with metadata', () {
      const original = TestObject(1, 'test');
      final Object? encoded = registry.encode(original);

      expect(encoded, isA<Map<String, dynamic>>());
      final map = encoded! as Map<String, dynamic>;
      expect(map['__type'], 'TestObject');
      expect(map['data'], {'id': 1, 'content': 'test'});
    });

    test('should decode registered object from metadata map', () {
      final Map<String, Object> encoded = {
        '__type': 'TestObject',
        'data': {'id': 1, 'content': 'test'},
      };

      final Object? decoded = registry.decode(encoded);

      expect(decoded, isA<TestObject>());
      expect(decoded, const TestObject(1, 'test'));
    });

    test('should decode registered object from Map<Object?, Object?>', () {
      final Map<Object?, Object?> encoded = <Object?, Object?>{
        '__type': 'TestObject',
        'data': <Object?, Object?>{'id': 1, 'content': 'test'},
      };

      final Object? decoded = registry.decode(encoded);

      expect(decoded, isA<TestObject>());
      expect(decoded, const TestObject(1, 'test'));
    });

    test('should return null for unknown typed wrapper maps', () {
      final Map<String, Object> unknownMap = {
        '__type': 'UnknownType',
        'data': {},
      };
      final Object? result = registry.decode(unknownMap);
      expect(result, isNull);
    });

    test('should return null when input is null', () {
      expect(registry.encode(null), isNull);
      expect(registry.decode(null), isNull);
    });

    test('should pass through unregistered objects during encoding', () {
      const unregistered = 'Simple String';
      final Object? result = registry.encode(unregistered);
      expect(result, unregistered);
    });

    test('should drop non-encodable unregistered objects to null', () {
      // Regression: a non-JSON-encodable route `extra` (e.g.
      // PrayerAlertsPermissionNavExtra) must never be returned as-is, or
      // GoRouter's platform route reporting / state restoration crashes the
      // app with "Converting object to an encodable object failed".
      final Object? result = registry.encode(const UnregisteredExtra());
      expect(result, isNull);
      // The encoded result must be JSON-serializable.
      expect(() => jsonEncode(result), returnsNormally);
    });

    test('should keep JSON-safe collections of primitives', () {
      final value = {
        'a': 1,
        'b': <Object?>['x', true, 2.5, null],
      };
      final Object? result = registry.encode(value);
      expect(result, value);
      expect(() => jsonEncode(result), returnsNormally);
    });

    test('should drop collections that contain non-encodable objects', () {
      final value = {
        'steps': <Object?>[const UnregisteredExtra()],
      };
      final Object? result = registry.encode(value);
      expect(result, isNull);
    });

    test('should pass through maps without metadata during decoding', () {
      final rawMap = {'key': 'value'};
      final Object? result = registry.decode(rawMap);
      expect(result, rawMap);
    });

    test('should return null when registered decoder throws', () {
      registry.register(
        'BrokenObject',
        (_) => throw const FormatException('bad data'),
      );
      final Map<String, Object> encoded = {
        '__type': 'BrokenObject',
        'data': {'id': 1},
      };

      expect(registry.decode(encoded), isNull);
    });

    test('should return null when typed wrapper has invalid data', () {
      final Map<String, Object> encoded = {
        '__type': 'TestObject',
        'data': 'not-a-map',
      };

      expect(registry.decode(encoded), isNull);
    });
  });
}
