import 'package:equatable/equatable.dart';

/// A single declarative node in an AI-authored UI document.
///
/// A node is *data only*: a [type] string (resolved against a closed component
/// whitelist at render time), an optional bag of primitive [properties],
/// optional [children], and an optional [actionId] (resolved against a closed
/// action allowlist). The model never emits Flutter widgets, callbacks, routes,
/// or colours — only this shape. Anything the renderer cannot map fails closed.
class GenUiNode extends Equatable {
  const GenUiNode({
    required this.type,
    this.properties = const <String, Object?>{},
    this.children = const <GenUiNode>[],
    this.actionId,
  });

  /// Component identifier, matched against the component registry. Unknown
  /// values render a safe fallback rather than throwing.
  final String type;

  /// Primitive-valued properties (String/num/bool only after parsing).
  final Map<String, Object?> properties;

  /// Nested nodes, rendered recursively by container components.
  final List<GenUiNode> children;

  /// Optional action this node triggers, matched against the action allowlist.
  /// Unknown or out-of-bounds actions are rejected at dispatch time.
  final String? actionId;

  String? stringProp(String key) {
    final Object? value = properties[key];
    return value is String ? value : null;
  }

  int? intProp(String key) {
    final Object? value = properties[key];
    return switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v),
      _ => null,
    };
  }

  bool boolProp(String key, {bool orElse = false}) {
    final Object? value = properties[key];
    return value is bool ? value : orElse;
  }

  @override
  List<Object?> get props => <Object?>[type, properties, children, actionId];
}
