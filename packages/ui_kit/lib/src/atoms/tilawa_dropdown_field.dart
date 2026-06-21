import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_input_style.dart';

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
/// Everything visual is sourced from [TilawaDesignTokens] and the ambient
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
        child: ConstrainedBox(
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
          final double? menuWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : null;

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

          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: tokens.minInteractiveDimension,
            ),
            child: SizedBox(
              width: double.infinity,
              child: MenuAnchor(
                crossAxisUnconstrained: false,
                alignmentOffset: Offset(0, tokens.dropdownMenuGap),
                style: menuStyle,
                menuChildren: [
                  for (final item in items)
                    MenuItemButton(
                      style: menuItemStyle,
                      onPressed: isEnabled
                          ? () => onChanged!(item.value)
                          : null,
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
                        child: InkWell(
                          onTap: isEnabled ? toggleMenu : null,
                          borderRadius: BorderRadius.circular(radius),
                          child: InputDecorator(
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
              ),
            ),
          );
        },
      ),
    );
  }
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
  });

  final bool hasValue;
  final String label;
  final TextStyle? textStyle;
  final ColorScheme colorScheme;
  final IconData? prefixIcon;
  final TilawaDesignTokens tokens;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isEnabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withValues(alpha: 0.38);

    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, size: tokens.iconSizeLarge, color: iconColor),
            SizedBox(width: tokens.spaceSmall),
          ],
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: hasValue
                  ? textStyle
                  : textStyle?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: iconColor),
        ],
      ),
    );
  }
}
