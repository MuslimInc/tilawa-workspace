import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Shared hero tag for catalog launcher → dedicated search screen morph.
abstract final class RecitersSearchFieldHero {
  static const String tag = 'reciters_catalog_search_field';
}

/// Catalog-styled reciter search field used on the launcher and search screen.
class RecitersCatalogSearchField extends StatelessWidget {
  const RecitersCatalogSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onClear,
    this.onTapOutside,
    this.scrollPadding,
    this.semanticsIdentifier,
    this.enableHero = false,
    this.onTap,
  });

  const RecitersCatalogSearchField.launcher({
    super.key,
    required this.onTap,
    this.semanticsIdentifier,
    this.enableHero = false,
  }) : controller = null,
       focusNode = null,
       onChanged = null,
       onClear = null,
       onTapOutside = null,
       scrollPadding = null;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TapRegionCallback? onTapOutside;
  final EdgeInsets? scrollPadding;
  final String? semanticsIdentifier;
  final bool enableHero;
  final VoidCallback? onTap;

  bool get _isLauncher => onTap != null;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final BorderRadius borderRadius = BorderRadius.circular(
      tokens.radiusExtraLarge,
    );

    Widget field = TilawaSearchField(
      controller: controller,
      focusNode: focusNode,
      hintText: context.l10n.searchReciters,
      textInputAction: TextInputAction.search,
      prefixIcon: FluentIcons.search_24_regular,
      clearIcon: FluentIcons.dismiss_24_regular,
      showShadow: false,
      scrollPadding: scrollPadding,
      onChanged: onChanged,
      onClear: onClear,
      onTapOutside: onTapOutside,
      clearButtonTooltip: context.l10n.a11yClearRecitersSearch,
    );

    if (enableHero) {
      field = Hero(
        tag: RecitersSearchFieldHero.tag,
        child: Material(
          type: MaterialType.transparency,
          child: field,
        ),
      );
    }

    if (_isLauncher) {
      field = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          borderRadius: borderRadius,
          splashColor: Theme.of(context).colorScheme.primary.withValues(
            alpha: tokens.opacitySubtle,
          ),
          highlightColor: Theme.of(context).colorScheme.primary.withValues(
            alpha: tokens.opacitySubtle * 0.5,
          ),
          child: AbsorbPointer(child: field),
        ),
      );
    }

    if (semanticsIdentifier != null) {
      field = Semantics(
        identifier: semanticsIdentifier,
        button: _isLauncher,
        textField: !_isLauncher,
        label: context.l10n.searchReciters,
        child: field,
      );
    }

    return field;
  }
}
