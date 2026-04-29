import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class TilawaIconActionButton extends StatefulWidget {
  const TilawaIconActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.size,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final double? size;
  final double? iconSize;

  @override
  State<TilawaIconActionButton> createState() => _TilawaIconActionButtonState();
}

class _TilawaIconActionButtonState extends State<TilawaIconActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePress() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.iconActionButton;
    final effectiveSize = widget.size ?? componentTokens.size;
    final effectiveIconSize = widget.iconSize ?? designTokens.iconSizeMedium;
    final effectiveBorderRadius = BorderRadius.circular(
      componentTokens.borderRadius,
    );

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: effectiveBorderRadius,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.92).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: InkWell(
            borderRadius: effectiveBorderRadius,
            onTap: _handlePress,
            child: Center(
              child: Icon(
                widget.icon,
                size: effectiveIconSize,
                color: widget.isActive
                    ? theme.primaryColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
