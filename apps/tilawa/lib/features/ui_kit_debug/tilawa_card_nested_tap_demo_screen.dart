import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/features/ui_kit_debug/tilawa_card_demo_semantics_ids.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer-only fixture for Maestro E2E verification of nested [TilawaCard]
/// tap routing (not press-scale — widget tests own that).
class TilawaCardNestedTapDemoScreen extends StatefulWidget {
  const TilawaCardNestedTapDemoScreen({super.key});

  @override
  State<TilawaCardNestedTapDemoScreen> createState() =>
      _TilawaCardNestedTapDemoScreenState();
}

class _TilawaCardNestedTapDemoScreenState
    extends State<TilawaCardNestedTapDemoScreen> {
  static const String _idleResult = 'idle';

  String _result = _idleResult;

  void _reset() {
    setState(() => _result = _idleResult);
  }

  void _onParentTap() {
    setState(() => _result = 'parent navigated');
  }

  void _onNestedPlay() {
    setState(() => _result = 'nested play');
  }

  void _onNestedDelete() {
    setState(() => _result = 'nested delete');
  }

  void _onNestedFavorite() {
    setState(() => _result = 'nested favorite');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      identifier: TilawaCardDemoSemanticsIds.screen,
      child: Scaffold(
        appBar: const TilawaAppBar(title: 'TilawaCard nested tap demo'),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                identifier: TilawaCardDemoSemanticsIds.result,
                label: _result,
                child: ExcludeSemantics(
                  child: Text(
                    _result,
                    key: const Key(TilawaCardDemoSemanticsIds.result),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  identifier: TilawaCardDemoSemanticsIds.reset,
                  button: true,
                  label: 'Reset',
                  child: ExcludeSemantics(
                    child: TextButton(
                      key: const Key(TilawaCardDemoSemanticsIds.reset),
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceMedium),
              SizedBox(
                height: 168,
                child: TilawaCard(
                  key: const Key('tilawa_card_demo_card'),
                  onTap: _onParentTap,
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spaceMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          identifier: TilawaCardDemoSemanticsIds.blankArea,
                          child: const Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text('Blank body'),
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            _EnabledControl(
                              identifier:
                                  TilawaCardDemoSemanticsIds.enabledPlay,
                              icon: FluentIcons.play_24_regular,
                              tooltip: 'Play',
                              onPressed: _onNestedPlay,
                            ),
                            _EnabledControl(
                              identifier:
                                  TilawaCardDemoSemanticsIds.enabledDelete,
                              icon: FluentIcons.delete_24_regular,
                              tooltip: 'Delete',
                              onPressed: _onNestedDelete,
                            ),
                            _EnabledControl(
                              identifier:
                                  TilawaCardDemoSemanticsIds.enabledFavorite,
                              icon: FluentIcons.star_24_regular,
                              tooltip: 'Favorite',
                              onPressed: _onNestedFavorite,
                            ),
                            Semantics(
                              identifier:
                                  TilawaCardDemoSemanticsIds.disabledControl,
                              button: true,
                              label: 'Disabled',
                              enabled: false,
                              child: ExcludeSemantics(
                                child: IconButton(
                                  key: const Key(
                                    TilawaCardDemoSemanticsIds.disabledControl,
                                  ),
                                  onPressed: null,
                                  tooltip: 'Disabled',
                                  icon: Icon(
                                    FluentIcons.prohibited_24_regular,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.38,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Semantics(
                              identifier:
                                  TilawaCardDemoSemanticsIds.decorativeInkWell,
                              button: true,
                              label: 'Decorative ink well',
                              child: ExcludeSemantics(
                                child: InkWell(
                                  onTap: null,
                                  child: Padding(
                                    padding: EdgeInsets.all(tokens.spaceSmall),
                                    child: Icon(
                                      FluentIcons.settings_24_regular,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Semantics(
                              identifier: TilawaCardDemoSemanticsIds
                                  .decorativeGestureDetector,
                              button: true,
                              label: 'Decorative gesture detector',
                              child: ExcludeSemantics(
                                child: GestureDetector(
                                  child: Padding(
                                    padding: EdgeInsets.all(tokens.spaceSmall),
                                    child: Icon(
                                      FluentIcons.star_emphasis_24_regular,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnabledControl extends StatelessWidget {
  const _EnabledControl({
    required this.identifier,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final String identifier;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      button: true,
      label: tooltip,
      child: ExcludeSemantics(
        child: IconButton(
          key: Key(identifier),
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon),
        ),
      ),
    );
  }
}
