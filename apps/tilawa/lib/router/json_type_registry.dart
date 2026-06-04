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
  ///
  /// Unregistered values are only returned when they are already JSON-safe
  /// (primitives, or collections of primitives). Any other object — e.g. an
  /// in-session route `extra` that was never registered — is dropped to `null`
  /// rather than passed through. This is critical: GoRouter feeds the encoded
  /// result to the platform route-information channel
  /// ([SystemNavigator.routeInformationUpdated]) and to state restoration,
  /// both of which serialize it. A non-encodable object there throws a fatal
  /// "Converting object to an encodable object failed" error that crashes the
  /// app on launch. Dropping it is safe because the live navigation still uses
  /// the real in-memory `extra`; only the persisted/reported copy is omitted.
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
          // If toJson fails or doesn't exist, fall back to dropping the object
          break;
        }
      }
    }
    return _isJsonSafe(object) ? object : null;
  }

  /// Whether [value] can be JSON-encoded without a custom converter.
  static bool _isJsonSafe(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return true;
    }
    if (value is Map) {
      return value.entries.every(
        (MapEntry<dynamic, dynamic> e) =>
            e.key is String && _isJsonSafe(e.value),
      );
    }
    if (value is List) {
      return value.every(_isJsonSafe);
    }
    return false;
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
