import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';

class ImmersiveComposerScaffold extends StatelessWidget {
  const ImmersiveComposerScaffold({
    super.key,
    required this.title,
    required this.preview,
    required this.bottomPanel,
    this.subtitle,
    this.onClose,
    this.leading,
    this.trailing,
    this.background,
    this.backgroundGradient,
  });

  final String title;
  final String? subtitle;
  final Widget preview;
  final Widget bottomPanel;
  final VoidCallback? onClose;
  final Widget? leading;
  final Widget? trailing;
  final Widget? background;
  final Gradient? backgroundGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient:
              backgroundGradient ??
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerLowest,
                ],
              ),
        ),
        child: Stack(
          children: [
            if (background != null) ...[
              Positioned.fill(child: background!),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: tokens.blurShadow * 0.9,
                    sigmaY: tokens.blurShadow * 0.9,
                  ),
                  child: ColoredBox(
                    color: theme.colorScheme.surface.withValues(alpha: 0.42),
                  ),
                ),
              ),
            ],
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceLarge,
                  tokens.spaceLarge,
                  tokens.spaceLarge,
                  tokens.spaceLarge,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactHeight = constraints.maxHeight < 760;
                    final verticalSpacing = isCompactHeight
                        ? tokens.spaceMedium
                        : tokens.spaceLarge;
                    final panelMaxHeight = clampDouble(
                      constraints.maxHeight * (isCompactHeight ? 0.5 : 0.44),
                      220,
                      constraints.maxHeight,
                    );
                    final previewHeight = clampDouble(
                      constraints.maxHeight * (isCompactHeight ? 0.42 : 0.5),
                      220,
                      460,
                    );

                    Widget buildHeader() {
                      return Row(
                        children: [
                          leading ??
                              _RoundHeaderButton(
                                icon: Icons.close_rounded,
                                onPressed: onClose,
                              ),
                          SizedBox(width: tokens.spaceMedium),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  SizedBox(height: tokens.spaceExtraSmall),
                                  Text(
                                    subtitle!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: tokens.spaceMedium),
                          trailing ?? const SizedBox(width: 44, height: 44),
                        ],
                      );
                    }

                    Widget buildBottomPanel({required bool scrollInternally}) {
                      final panelChild = scrollInternally
                          ? SingleChildScrollView(
                              primary: false,
                              child: bottomPanel,
                            )
                          : bottomPanel;

                      return _GlassPanel(child: panelChild);
                    }

                    if (isCompactHeight) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildHeader(),
                              SizedBox(height: verticalSpacing),
                              SizedBox(height: previewHeight, child: preview),
                              SizedBox(height: verticalSpacing),
                              buildBottomPanel(scrollInternally: false),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildHeader(),
                        SizedBox(height: verticalSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: preview),
                              SizedBox(height: verticalSpacing),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: panelMaxHeight,
                                    ),
                                    child: buildBottomPanel(
                                      scrollInternally: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusExtraLarge + 8),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.blurGlass,
          sigmaY: tokens.blurGlass,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(tokens.spaceLarge),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge + 8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(
                alpha: tokens.opacitySubtle,
              ),
              width: tokens.borderWidthThin,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: tokens.opacitySubtle),
                blurRadius: tokens.blurShadow,
                offset: tokens.shadowOffsetMedium,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface.withValues(alpha: tokens.opacityGlass),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: tokens.opacitySubtle,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: tokens.iconSizeMedium + 2),
      ),
    );
  }
}
