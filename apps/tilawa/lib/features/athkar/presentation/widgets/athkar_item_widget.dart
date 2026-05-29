import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';
import 'item_count_widget.dart';

class AthkarItemWidget extends StatefulWidget {
  const AthkarItemWidget({
    super.key,
    required this.item,
    required this.currentCount,
    required this.onTap,
    required this.onReset,
  });

  final AthkarItem item;
  final int currentCount;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  State<AthkarItemWidget> createState() => _AthkarItemWidgetState();
}

class _AthkarItemWidgetState extends State<AthkarItemWidget> {
  late ScrollController _scrollController;
  int _tapFeedbackGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _handleDhikrTap() {
    setState(() {
      _tapFeedbackGeneration++;
    });
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final double bottomInset = context.systemBottomSafeArea;
    final bool isDone = widget.currentCount == 0;
    final bool canReset = widget.currentCount != widget.item.count;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        tokens.spaceMedium + bottomInset,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: tokens.contentMaxWidthReader,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _AthkarDhikrTapCard(
                  tapFeedbackGeneration: _tapFeedbackGeneration,
                  borderRadius: tokens.radiusExtraLarge,
                  onTap: _handleDhikrTap,
                  backgroundColor: colorScheme.surface,
                  splashColor: colorScheme.primary.withValues(
                    alpha: tokens.opacityMedium,
                  ),
                  highlightColor: colorScheme.primary.withValues(
                    alpha: tokens.opacitySubtle,
                  ),
                  child: _AthkarDhikrText(
                    text: widget.item.textAr,
                    scrollController: _scrollController,
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      height: tokens.textHeightLoose,
                    ),
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceMedium),
              _AthkarCountFooter(
                item: widget.item,
                currentCount: widget.currentCount,
                isDone: isDone,
                canReset: canReset,
                onReset: widget.onReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-card tap target via [TilawaCard.onTap], plus lighting flash and scale.
class _AthkarDhikrTapCard extends StatelessWidget {
  const _AthkarDhikrTapCard({
    required this.tapFeedbackGeneration,
    required this.borderRadius,
    required this.onTap,
    required this.backgroundColor,
    required this.splashColor,
    required this.highlightColor,
    required this.child,
  });

  final int tapFeedbackGeneration;
  final double borderRadius;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color splashColor;
  final Color highlightColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(tapFeedbackGeneration),
        tween: Tween<double>(begin: 0.992, end: 1),
        duration: tokens.durationFast,
        curve: Curves.easeOutCubic,
        builder: (context, scale, animatedChild) {
          return Transform.scale(scale: scale, child: animatedChild);
        },
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: TilawaCard(
                  borderRadius: borderRadius,
                  surface: TilawaCardSurface.raised,
                  backgroundColor: backgroundColor,
                  padding: EdgeInsets.zero,
                  child: SizedBox.expand(
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: radius,
                        splashColor: splashColor,
                        highlightColor: highlightColor,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceLarge,
                            vertical: tokens.spaceExtraLarge,
                          ),
                          child: SizedBox.expand(child: child),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: _AthkarTapFlash(
                    generation: tapFeedbackGeneration,
                    borderRadius: borderRadius,
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

/// Full-card lighting pulse drawn on each tap (visual only; taps pass through).
class _AthkarTapFlash extends StatelessWidget {
  const _AthkarTapFlash({
    required this.generation,
    required this.borderRadius,
  });

  final int generation;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return SizedBox.expand(
      child: generation == 0
          ? const SizedBox.shrink()
          : TweenAnimationBuilder<double>(
              key: ValueKey<int>(generation),
              tween: Tween<double>(begin: 1, end: 0),
              duration: tokens.durationMedium,
              curve: Curves.easeOut,
              builder: (context, intensity, _) {
                if (intensity <= 0) {
                  return const SizedBox.shrink();
                }
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: colorScheme.primary.withValues(
                      alpha: tokens.opacitySubtle * intensity,
                    ),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.25,
                      colors: [
                        colorScheme.primary.withValues(
                          alpha: tokens.opacityMedium * intensity,
                        ),
                        colorScheme.primary.withValues(
                          alpha: tokens.opacitySubtle * 0.35 * intensity,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Count ring centered with reset icon in the trailing [end] slot (RTL-aware).
class _AthkarCountFooter extends StatelessWidget {
  const _AthkarCountFooter({
    required this.item,
    required this.currentCount,
    required this.isDone,
    required this.canReset,
    required this.onReset,
  });

  final AthkarItem item;
  final int currentCount;
  final bool isDone;
  final bool canReset;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final double sideSlotWidth = athkarCountRingLayoutSize(context);

    final Widget resetControl = TilawaIconActionButton(
      icon: Icons.restart_alt_rounded,
      tooltip: context.l10n.reset,
      semanticLabel: context.l10n.reset,
      enabled: canReset,
      onTap: () => _confirmAthkarReset(context, onReset),
    );

    return Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: sideSlotWidth),
          Semantics(
            label: isDone ? null : '$currentCount / ${item.count}',
            child: ItemCountWidget(
              item: item,
              currentCount: currentCount,
              isDone: isDone,
              showProgressLabel: false,
            ),
          ),
          SizedBox(
            width: sideSlotWidth,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: resetControl,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmAthkarReset(
  BuildContext context,
  VoidCallback onReset,
) async {
  final bool? confirmed = await showTilawaConfirmSheet(
    context: context,
    title: context.l10n.reset,
    message: context.l10n.athkarResetConfirmationMessage,
    confirmLabel: context.l10n.reset,
    cancelLabel: context.l10n.cancel,
    confirmVariant: TilawaButtonVariant.secondary,
    onConfirm: () => Navigator.of(context).pop(true),
    onClose: () => Navigator.of(context).pop(false),
  );
  if (confirmed == true && context.mounted) {
    onReset();
  }
}

/// Scrollable dhikr text that stays vertically centered when content is short.
class _AthkarDhikrText extends StatelessWidget {
  const _AthkarDhikrText({
    required this.text,
    required this.scrollController,
    required this.textStyle,
  });

  final String text;
  final ScrollController scrollController;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: scrollController,
          radius: Radius.circular(tokens.radiusSmall),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            dragStartBehavior: DragStartBehavior.down,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Text(
                  text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
