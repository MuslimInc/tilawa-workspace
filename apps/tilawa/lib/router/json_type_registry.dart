/// Registry for JSON serialization of types.
/// Used by AppRouter to encode/decode complex objects in routes.
class JsonTypeRegistry {
  factory JsonTypeRegistry() => _instance;
  JsonTypeRegistry._internal();
  static final JsonTypeRegistry _instance = JsonTypeRegistry._internal();

  final Map<String, dynamic Function(Map<String, dynamic>)> _decoders = {};
  final List<_TypeEncoder> _encoders = [];

  /// Registers a type [T] with a specific [key] and [fromJson] factory.
  void register<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    _decoders[key] = fromJson;
    _encoders.add(_TypeEncoder(isType: (obj) => obj is T, key: key));
  }

  /// Encodes an object into a Map with metadata if it's a registered type.
  Object? encode(Object? object) {
    if (object == null) {
      return null;
    }

    // Try to find a registered encoder
    for (final _TypeEncoder encoder in _encoders) {
      if (encoder.isType(object)) {
        // Assume object has toJson() if it's registered
        // We use dynamic dispatch or assume the user ensured it has toJson
        try {
          // Check if object has toJson method via dynamic, or require interface.
          // Since we can't enforce interface on freezed classes easily, use dynamic.
          final dynamic data = (object as dynamic).toJson();
          return {'__type': encoder.key, 'data': data};
        } catch (e) {
          // If toJson fails or doesn't exist, fall back to returning object
          break;
        }
      }
    }
    return object;
  }

  /// Decodes a Map with metadata back into its original type.
  Object? decode(Object? object) {
    if (object == null) {
      return null;
    }

    if (object is Map<String, dynamic> && object.containsKey('__type')) {
      final type = object['__type'] as String;
      final dynamic data = object['data'];

      final Function(Map<String, dynamic>)? decoder = _decoders[type];
      if (decoder != null && data is Map<String, dynamic>) {
        try {
          return decoder(data);
        } catch (_) {
          // Decoding failed
        }
      }
    }
    return object;
  }
}

class _TypeEncoder {
  _TypeEncoder({required this.isType, required this.key});
  final bool Function(Object) isType;
  final String key;
}
