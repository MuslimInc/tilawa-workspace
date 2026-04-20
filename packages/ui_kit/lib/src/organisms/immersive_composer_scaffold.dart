import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/content_bounds.dart';
import '../foundation/design_tokens.dart';
import '../molecules/tilawa_glass_panel.dart';

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
    this.compactPanelHeightFactor,
    this.regularPanelHeightFactor,
    this.compactPreviewHeightFactor,
    this.regularPreviewHeightFactor,
    this.panelMinHeight,
    this.previewMaxHeight,
    this.floatingActionButton,
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
  final double? compactPanelHeightFactor;
  final double? regularPanelHeightFactor;
  final double? compactPreviewHeightFactor;
  final double? regularPreviewHeightFactor;
  final double? panelMinHeight;
  final double? previewMaxHeight;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.immersiveComposer;
    final glassTokens = theme.componentTokens.glassPanel;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
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
                    sigmaX:
                        designTokens.blurShadow *
                        componentTokens.backgroundBlurScale,
                    sigmaY:
                        designTokens.blurShadow *
                        componentTokens.backgroundBlurScale,
                  ),
                  child: ColoredBox(
                    color: theme.colorScheme.surface.withValues(
                      alpha: componentTokens.backgroundOverlayOpacity,
                    ),
                  ),
                ),
              ),
            ],
            SafeArea(
              bottom: false,
              child: TilawaContentBounds(
                kind: TilawaContentKind.media,
                alignment: Alignment.topCenter,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactHeight =
                        constraints.maxHeight <
                        componentTokens.compactHeightBreakpoint;
                    final verticalSpacing = isCompactHeight
                        ? designTokens.spaceMedium
                        : designTokens.spaceLarge;
                    final resolvedCompactPanelHeightFactor =
                        compactPanelHeightFactor ??
                        componentTokens.compactPanelHeightFactor;
                    final resolvedRegularPanelHeightFactor =
                        regularPanelHeightFactor ??
                        componentTokens.regularPanelHeightFactor;
                    final resolvedCompactPreviewHeightFactor =
                        compactPreviewHeightFactor ??
                        componentTokens.compactPreviewHeightFactor;
                    final resolvedRegularPreviewHeightFactor =
                        regularPreviewHeightFactor ??
                        componentTokens.regularPreviewHeightFactor;
                    final resolvedPanelMinHeight =
                        panelMinHeight ?? componentTokens.panelMinHeight;
                    final resolvedPreviewMaxHeight =
                        previewMaxHeight ?? componentTokens.previewMaxHeight;
                    final panelMaxHeight = clampDouble(
                      constraints.maxHeight *
                          (isCompactHeight
                              ? resolvedCompactPanelHeightFactor
                              : resolvedRegularPanelHeightFactor),
                      resolvedPanelMinHeight,
                      constraints.maxHeight,
                    );
                    final previewHeight = clampDouble(
                      constraints.maxHeight *
                          (isCompactHeight
                              ? resolvedCompactPreviewHeightFactor
                              : resolvedRegularPreviewHeightFactor),
                      resolvedPanelMinHeight,
                      resolvedPreviewMaxHeight,
                    );

                    Widget buildHeader() {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: designTokens.spaceLarge,
                        ),
                        child: Row(
                          spacing: designTokens.spaceMedium,
                          children: [
                            leading ??
                                _RoundHeaderButton(
                                  icon: Icons.close_rounded,
                                  onPressed: onClose,
                                ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: designTokens.spaceExtraSmall,
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (subtitle != null)
                                    Text(
                                      subtitle!,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            trailing ??
                                SizedBox(
                                  width: componentTokens.headerButtonSize,
                                  height: componentTokens.headerButtonSize,
                                ),
                          ],
                        ),
                      );
                    }

                    Widget buildBottomPanel({required bool scrollInternally}) {
                      final panelChild = scrollInternally
                          ? SingleChildScrollView(
                              primary: false,
                              child: bottomPanel,
                            )
                          : bottomPanel;

                      final bottomInset = MediaQuery.paddingOf(context).bottom;

                      return TilawaGlassPanel(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(
                            designTokens.radiusExtraLarge +
                                glassTokens.borderRadiusOffset,
                          ),
                        ),
                        padding: EdgeInsets.only(
                          left: designTokens.spaceLarge,
                          right: designTokens.spaceLarge,
                          top: designTokens.spaceLarge,
                          bottom: bottomInset + designTokens.spaceLarge,
                        ),
                        child: panelChild,
                      );
                    }

                    if (isCompactHeight) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: verticalSpacing,
                                children: [
                                  buildHeader(),
                                  SizedBox(
                                    height: previewHeight,
                                    child: preview,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          buildBottomPanel(scrollInternally: false),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: verticalSpacing,
                      children: [
                        buildHeader(),
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(child: preview),
                              Align(
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

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.immersiveComposer;

    return Container(
      width: componentTokens.headerButtonSize,
      height: componentTokens.headerButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface.withValues(
          alpha: designTokens.opacityGlass,
        ),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: designTokens.opacitySubtle,
          ),
          width: designTokens.borderWidthThin,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size:
              designTokens.iconSizeMedium +
              componentTokens.headerIconSizeOffset,
        ),
      ),
    );
  }
}
