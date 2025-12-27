import 'package:flutter_test/flutter_test.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tilawa/router/json_type_registry.dart';

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

    test('should return null when input is null', () {
      expect(registry.encode(null), isNull);
      expect(registry.decode(null), isNull);
    });

    test('should pass through unregistered objects during encoding', () {
      const unregistered = 'Simple String';
      final Object? result = registry.encode(unregistered);
      expect(result, unregistered);
    });

    test('should pass through maps without metadata during decoding', () {
      final rawMap = {'key': 'value'};
      final Object? result = registry.decode(rawMap);
      expect(result, rawMap);
    });

    test('should pass through maps with unknown type during decoding', () {
      final Map<String, Object> unknownMap = {
        '__type': 'UnknownType',
        'data': {},
      };
      final Object? result = registry.decode(unknownMap);
      // Since specific decoder is not found, it returns the map as is
      expect(result, unknownMap);
    });
  });
}
