import 'package:equatable/equatable.dart';

import 'genui_node.dart';

/// A validated, AI-authored UI document.
///
/// The document is a *layout plan*, never a source of religious truth. Its
/// [nodes] reference trusted content (ayat, plans, athkar) by id; the renderer
/// resolves those ids against local/backend repositories. [assistantNote] is
/// the only free-text slot the model controls, and it is non-authoritative —
/// the renderer always frames it with a standing "AI-assisted, not a religious
/// ruling" disclosure.
class GenUiDocument extends Equatable {
  const GenUiDocument({
    required this.schemaVersion,
    required this.nodes,
    this.assistantNote,
  });

  final String schemaVersion;
  final List<GenUiNode> nodes;

  /// Optional, non-authoritative greeting/encouragement copy. Must never carry
  /// ayah text, translations, or rulings — those come from trusted sources.
  final String? assistantNote;

  @override
  List<Object?> get props => <Object?>[schemaVersion, nodes, assistantNote];
}
