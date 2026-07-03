import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_input_style.dart';
import '../foundation/tilawa_interactive_surface.dart';

/// A single option for a [TilawaDropdownField].
@immutable
class TilawaDropdownItem<T> {
  const TilawaDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });

  /// The value carried by this option.
  final T value;

  /// The human-readable label shown in the closed field and the popup.
  final String label;

  /// Optional leading icon shown beside [label] inside the popup.
  final IconData? icon;
}

/// A design-system-compliant select / dropdown field.
///
/// [TilawaDropdownField] is the dropdown counterpart of [TilawaTextField]: it
/// renders the **same** closed-field shell (border radius, content padding,
/// border / focus / error / disabled colours, typography) so dropdowns sit
/// visually flush with text fields in a form, and it opens a [MenuAnchor]
/// menu **below** the field (native picker placement) instead of the legacy
/// [DropdownButton] overlay that vertically centers on the selected row.
///
/// Everything visual is sourced from [MeMuslimDesignTokens] and the ambient
/// [ThemeData]; nothing is hardcoded.
class TilawaDropdownField<T> extends StatelessWidget {
  const TilawaDropdownField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.labelText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.semanticLabel,
    this.shrinkWrapWidth = false,
  });

  /// The selectable options.
  final List<TilawaDropdownItem<T>> items;

  /// The currently selected value, or null when nothing is selected.
  final T? value;

  /// Called when the user selects an option. When null the field is disabled.
  final ValueChanged<T>? onChanged;

  /// Placeholder shown when [value] is null.
  final String? hintText;

  /// Floating label text.
  final String? labelText;

  /// Error message; when non-null the field renders its error state.
  final String? errorText;

  /// Leading icon (rendered on the right under RTL automatically).
  final IconData? prefixIcon;

  /// Whether the field is interactive. A disabled field is also produced when
  /// [onChanged] is null.
  final bool enabled;

  /// Accessibility label; falls back to [labelText] then [hintText].
  final String? semanticLabel;

  /// When true, the closed field sizes to its label instead of expanding to
  /// the parent width (e.g. country-code prefix beside a phone field).
  final bool shrinkWrapWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodyLarge;
    final inputStyle = context.inputStyle();
    final isEnabled = enabled && onChanged != null;
    final fieldDecoration = inputStyle.decoration(
      labelText: labelText,
      errorText: errorText,
      prefixIcon: prefixIcon != null && items.length == 1
          ? Icon(prefixIcon)
          : null,
      enabled: isEnabled,
      textStyle: textStyle,
    );

    if (items.length == 1) {
      final item = items.first;
      if (value != item.value && onChanged != null && enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onChanged!(item.value);
        });
      }

      return Semantics(
        label: semanticLabel ?? labelText ?? hintText,
        child: shrinkWrapWidth
            ? ShrinkWrapInputShell(
                decoration: fieldDecoration,
                tokens: tokens,
                child: Text(
                  item.label,
                  style: textStyle,
                  maxLines: 1,
                  softWrap: false,
                ),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: tokens.minInteractiveDimension,
                ),
                child: InputDecorator(
                  decoration: fieldDecoration,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: textStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    TilawaDropdownItem<T>? selectedItem;
    if (value != null) {
      for (final item in items) {
        if (item.value == value) {
          selectedItem = item;
          break;
        }
      }
    }

    return Semantics(
      label: semanticLabel ?? labelText ?? hintText,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double? menuWidth = shrinkWrapWidth
              ? _measureDropdownMenuWidth(
                  context,
                  items: items,
                  textStyle: textStyle,
                  tokens: tokens,
                )
              : (constraints.maxWidth.isFinite ? constraints.maxWidth : null);

          final double radius = inputStyle.borderRadius();

          final MenuStyle menuStyle = MenuStyle(
            alignment: AlignmentDirectional.bottomStart,
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: WidgetStatePropertyAll(
              colorScheme.shadow.withValues(alpha: 0.08),
            ),
            side: WidgetStatePropertyAll(
              BorderSide(color: colorScheme.outlineVariant),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            minimumSize: menuWidth == null
                ? null
                : WidgetStatePropertyAll(Size(menuWidth, 0)),
            maximumSize: menuWidth == null
                ? null
                : WidgetStatePropertyAll(
                    Size(menuWidth, double.infinity),
                  ),
          );

          final ButtonStyle menuItemStyle = MenuItemButton.styleFrom(
            minimumSize: Size(
              menuWidth ?? tokens.minInteractiveDimension,
              tokens.minInteractiveDimension,
            ),
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
            textStyle: textStyle,
            alignment: AlignmentDirectional.centerStart,
          );

          final menuAnchor = MenuAnchor(
            crossAxisUnconstrained: false,
            alignmentOffset: Offset(0, tokens.dropdownMenuGap),
            style: menuStyle,
            menuChildren: [
              for (final item in items)
                MenuItemButton(
                  style: menuItemStyle,
                  onPressed: isEnabled ? () => onChanged!(item.value) : null,
                  leadingIcon: item.icon == null
                      ? null
                      : Icon(item.icon, size: tokens.iconSizeMedium),
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            builder:
                (
                  BuildContext context,
                  MenuController controller,
                  Widget? child,
                ) {
                  final bool hasValue = selectedItem != null;
                  void toggleMenu() {
                    if (!isEnabled) {
                      return;
                    }
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  }

                  return Semantics(
                    button: true,
                    enabled: isEnabled,
                    expanded: controller.isOpen,
                    child: TilawaInteractiveSurface(
                      onTap: isEnabled ? toggleMenu : null,
                      enabled: isEnabled,
                      button: false,
                      // Form fields use stable state-layer press (default).
                      borderRadius: BorderRadius.circular(radius),
                      child: shrinkWrapWidth
                          ? ShrinkWrapInputShell(
                              decoration: fieldDecoration,
                              tokens: tokens,
                              child: _FieldContent(
                                hasValue: hasValue,
                                label: hasValue
                                    ? selectedItem.label
                                    : (hintText ?? ''),
                                textStyle: textStyle,
                                colorScheme: colorScheme,
                                prefixIcon: prefixIcon,
                                tokens: tokens,
                                isEnabled: isEnabled,
                                shrinkWrapWidth: true,
                              ),
                            )
                          : InputDecorator(
                              decoration: fieldDecoration,
                              isEmpty: !hasValue && hintText != null,
                              child: _FieldContent(
                                hasValue: hasValue,
                                label: hasValue
                                    ? selectedItem.label
                                    : (hintText ?? ''),
                                textStyle: textStyle,
                                colorScheme: colorScheme,
                                prefixIcon: prefixIcon,
                                tokens: tokens,
                                isEnabled: isEnabled,
                              ),
                            ),
                    ),
                  );
                },
          );

          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: tokens.minInteractiveDimension,
            ),
            child: shrinkWrapWidth
                ? menuAnchor
                : SizedBox(width: double.infinity, child: menuAnchor),
          );
        },
      ),
    );
  }
}

/// Closed-field shell that sizes to [child] instead of expanding like
/// [InputDecorator].
class ShrinkWrapInputShell extends StatelessWidget {
  const ShrinkWrapInputShell({
    super.key,
    required this.decoration,
    required this.tokens,
    required this.child,
  });

  final InputDecoration decoration;
  final MeMuslimDesignTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasError =
        decoration.errorText != null && decoration.errorText!.trim().isNotEmpty;
    final border =
        (hasError ? decoration.errorBorder : decoration.enabledBorder)
            as OutlineInputBorder?;

    return Container(
      constraints: BoxConstraints(minHeight: tokens.minInteractiveDimension),
      padding: decoration.contentPadding,
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: decoration.fillColor,
        borderRadius: border?.borderRadius,
        border: border == null
            ? null
            : Border.fromBorderSide(border.borderSide),
      ),
      child: child,
    );
  }
}

double _measureDropdownMenuWidth<T>(
  BuildContext context, {
  required List<TilawaDropdownItem<T>> items,
  required TextStyle? textStyle,
  required MeMuslimDesignTokens tokens,
}) {
  final textDirection = Directionality.of(context);
  final resolvedStyle = textStyle ?? DefaultTextStyle.of(context).style;
  final textScaler = MediaQuery.textScalerOf(context);
  var maxLabelWidth = 0.0;
  for (final item in items) {
    final labelWidth = _measureDropdownLabelWidth(
      label: item.label,
      style: resolvedStyle,
      textDirection: textDirection,
      textScaler: textScaler,
    );
    if (labelWidth > maxLabelWidth) {
      maxLabelWidth = labelWidth;
    }
  }
  return maxLabelWidth + tokens.spaceMedium * 2;
}

double _measureDropdownLabelWidth({
  required String label,
  required TextStyle style,
  required TextDirection textDirection,
  required TextScaler textScaler,
}) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  return painter.width;
}

class _FieldContent extends StatelessWidget {
  const _FieldContent({
    required this.hasValue,
    required this.label,
    required this.textStyle,
    required this.colorScheme,
    required this.prefixIcon,
    required this.tokens,
    required this.isEnabled,
    this.shrinkWrapWidth = false,
  });

  final bool hasValue;
  final String label;
  final TextStyle? textStyle;
  final ColorScheme colorScheme;
  final IconData? prefixIcon;
  final MeMuslimDesignTokens tokens;
  final bool isEnabled;
  final bool shrinkWrapWidth;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isEnabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final labelWidget = Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: hasValue
          ? textStyle
          : textStyle?.copyWith(color: colorScheme.onSurfaceVariant),
    );

    return Row(
      mainAxisSize: shrinkWrapWidth ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: tokens.iconSizeLarge, color: iconColor),
          SizedBox(width: tokens.spaceSmall),
        ],
        if (shrinkWrapWidth) labelWidget else Flexible(child: labelWidget),
        SizedBox(width: tokens.spaceTiny),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: tokens.iconSizeLarge,
          color: iconColor,
        ),
      ],
    );
  }
}
