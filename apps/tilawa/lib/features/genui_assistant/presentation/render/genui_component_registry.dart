import 'components/genui_components.dart';

/// The component *whitelist*: a closed map from a node `type` to its builder.
///
/// Resolution is total — an unregistered type returns null and the renderer
/// substitutes [GenUiUnknownComponent]. There is no dynamic widget construction
/// and no way for a payload to introduce a type that isn't compiled in here.
class GenUiComponentRegistry {
  const GenUiComponentRegistry(this._builders);

  final Map<String, GenUiComponentBuilder> _builders;

  bool isRegistered(String type) => _builders.containsKey(type);

  GenUiComponentBuilder? resolve(String type) => _builders[type];

  Iterable<String> get registeredTypes => _builders.keys;

  /// The MVP whitelist. Each entry maps 1:1 onto an existing ui_kit widget.
  factory GenUiComponentRegistry.defaults() {
    return GenUiComponentRegistry(<String, GenUiComponentBuilder>{
      'SectionStack': (context, node, scope) =>
          GenUiSectionStack(node: node, scope: scope),
      'PlanHeader': (context, node, scope) => GenUiPlanHeader(node: node),
      'WirdCard': (context, node, scope) =>
          GenUiWirdCard(node: node, scope: scope),
      'AyahReferenceCard': (context, node, scope) =>
          GenUiAyahReferenceCard(node: node, scope: scope),
      'InfoNote': (context, node, scope) => GenUiInfoNote(node: node),
      'ActionButton': (context, node, scope) =>
          GenUiActionButton(node: node, scope: scope),
    });
  }
}
