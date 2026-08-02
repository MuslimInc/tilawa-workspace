import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';

/// Content-first Athkar reading page: text, reference, repeat label.
class AthkarItemWidget extends StatefulWidget {
  const AthkarItemWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  final AthkarItem item;
  final VoidCallback onTap;

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDhikrTap() {
    setState(() {
      _tapFeedbackGeneration++;
    });
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final String reference = widget.item.reference.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceLarge,
        tokens.spaceLarge,
        0,
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
                child: _AthkarDhikrTapSurface(
                  tapFeedbackGeneration: _tapFeedbackGeneration,
                  onTap: _handleDhikrTap,
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
              if (reference.isNotEmpty) ...[
                SizedBox(height: tokens.spaceMedium),
                Text(
                  '«$reference»',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: tokens.spaceMedium),
              TilawaDivider(
                height: tokens.borderWidthThin,
                color: colorScheme.outlineVariant,
              ),
              SizedBox(height: tokens.spaceMedium),
              Text(
                context.l10n.athkarRepeatCount(widget.item.count),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-area tap target with a light flash on each count.
class _AthkarDhikrTapSurface extends StatelessWidget {
  const _AthkarDhikrTapSurface({
    required this.tapFeedbackGeneration,
    required this.onTap,
    required this.child,
  });

  final int tapFeedbackGeneration;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(tokens.radiusLarge);

    return ClipRRect(
      borderRadius: radius,
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(tapFeedbackGeneration),
        tween: Tween<double>(begin: 0.995, end: 1),
        duration: tokens.durationFast,
        curve: Curves.easeOutCubic,
        builder: (context, scale, animatedChild) {
          return Transform.scale(scale: scale, child: animatedChild);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  splashColor: colorScheme.primary.withValues(
                    alpha: tokens.opacityMedium,
                  ),
                  highlightColor: colorScheme.primary.withValues(
                    alpha: tokens.opacitySubtle,
                  ),
                  child: child,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _AthkarTapFlash(
                  generation: tapFeedbackGeneration,
                  borderRadius: tokens.radiusLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final MeMuslimDesignTokens tokens = theme.tokens;
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
                  ),
                );
              },
            ),
    );
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
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceMedium,
        ),
        child: LayoutBuilder(
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
        ),
      ),
    );
  }
}
