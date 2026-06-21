import 'package:flutter/material.dart';

import '../foundation/tilawa_input_style.dart';

/// A design-system-compliant text input field.
///
/// [TilawaTextField] wraps [TextFormField] and applies consistent styling
/// based on the Tilawa design tokens.
class TilawaTextField extends StatefulWidget {
  const TilawaTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.isPassword = false,
    this.onClear,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.semanticLabel,
    this.autofocus = false,
    this.initialValue,
    this.maxLength,
    this.showCounter = false,
    this.showPasswordTooltip,
    this.hidePasswordTooltip,
    this.clearTextTooltip,
  }) : assert(
         controller == null || initialValue == null,
         'controller and initialValue cannot both be provided.',
       ),
       assert(
         !(isPassword && suffixIcon != null),
         'suffixIcon cannot be provided when isPassword is true.',
       ),
       assert(
         !(onClear != null && suffixIcon != null),
         'suffixIcon cannot be provided when onClear is provided.',
       ),
       assert(
         !(isPassword && onClear != null),
         'onClear cannot be provided when isPassword is true.',
       );

  /// Text that describes the input field.
  final String? label;

  /// Text that suggests what sort of input the field accepts.
  final String? hintText;

  /// Text that provides additional context below the input field.
  final String? helperText;

  /// Text that describes an error state.
  final String? errorText;

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Defines the keyboard focus for this widget.
  final FocusNode? focusNode;

  /// Whether the input field is interactive.
  final bool enabled;

  /// Whether the text can be changed.
  final bool readOnly;

  /// Whether to hide the text being edited (e.g., for passwords).
  final bool isPassword;

  /// Called when the clear button is tapped.
  ///
  /// When provided, a clear button appears when the field is not empty.
  final VoidCallback? onClear;

  /// An icon to display before the text.
  final Widget? prefixIcon;

  /// An icon to display after the text.
  ///
  /// Cannot be used if [isPassword] is true or [onClear] is provided.
  final Widget? suffixIcon;

  /// The type of information for which to optimize the text input control.
  final TextInputType? keyboardType;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// The maximum number of lines to show at one time.
  final int? maxLines;

  /// The minimum number of lines to show at one time.
  final int? minLines;

  /// Called when the user initiates a change to the text.
  final ValueChanged<String>? onChanged;

  /// Called when the user indicates they are done editing the text.
  final ValueChanged<String>? onSubmitted;

  /// A function that checks the validity of the input.
  final FormFieldValidator<String>? validator;

  /// A semantic label for the input field.
  final String? semanticLabel;

  /// Whether to focus the field automatically.
  final bool autofocus;

  /// Initial text value if no controller is provided.
  final String? initialValue;

  /// The maximum number of characters allowed in the field.
  ///
  /// When provided, input beyond this length is prevented. Use [showCounter]
  /// to display a character count indicator.
  final int? maxLength;

  /// Whether to show the character counter when [maxLength] is set.
  ///
  /// Defaults to false to keep the UI minimal. When true, displays the
  /// default Flutter counter (e.g., "5/100").
  final bool showCounter;

  /// Tooltip text shown on the password reveal icon.
  final String? showPasswordTooltip;

  /// Tooltip text shown on the password hide icon.
  final String? hidePasswordTooltip;

  /// Tooltip text shown on the clear icon.
  final String? clearTextTooltip;

  @override
  State<TilawaTextField> createState() => _TilawaTextFieldState();
}

class _TilawaTextFieldState extends State<TilawaTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isObscured = true;
  bool _showClearButton = false;

  bool get _isInternalController => widget.controller == null;
  bool get _isInternalFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _isObscured = widget.isPassword;

    _controller.addListener(_updateClearButtonVisibility);
    _updateClearButtonVisibility();
  }

  @override
  void didUpdateWidget(TilawaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_updateClearButtonVisibility);
      if (_isInternalController) {
        _controller.dispose();
      }
      _controller =
          widget.controller ?? TextEditingController(text: widget.initialValue);
      _controller.addListener(_updateClearButtonVisibility);
    }
    _updateClearButtonVisibility();
  }

  @override
  void dispose() {
    _controller.removeListener(_updateClearButtonVisibility);
    if (_isInternalController) {
      _controller.dispose();
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _updateClearButtonVisibility() {
    final show =
        widget.onClear != null && _controller.text.isNotEmpty && widget.enabled;
    if (show != _showClearButton) {
      setState(() {
        _showClearButton = show;
      });
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    _updateClearButtonVisibility();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputStyle = context.inputStyle();

    final Widget? suffix = widget.isPassword
        ? IconButton(
            icon: Icon(
              _isObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: widget.enabled ? _togglePasswordVisibility : null,
            tooltip: _isObscured
                ? (widget.showPasswordTooltip ?? 'Show password')
                : (widget.hidePasswordTooltip ?? 'Hide password'),
          )
        : (_showClearButton
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: widget.enabled ? _handleClear : null,
                  tooltip: widget.clearTextTooltip ?? 'Clear text',
                )
              : widget.suffixIcon);

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        obscureText: _isObscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        minLines: widget.minLines,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        autofocus: widget.autofocus,
        style: theme.textTheme.bodyLarge,
        maxLength: widget.maxLength,
        buildCounter: widget.showCounter
            ? null
            : (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => const SizedBox.shrink(),
        decoration: inputStyle.decoration(
          labelText: widget.label,
          hintText: widget.hintText,
          helperText: widget.helperText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffix,
          enabled: widget.enabled,
          textStyle: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
