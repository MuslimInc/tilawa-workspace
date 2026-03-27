import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
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
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.immersiveComposer;

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
              child: Padding(
                padding: EdgeInsets.all(designTokens.spaceLarge),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactHeight =
                        constraints.maxHeight <
                        componentTokens.compactHeightBreakpoint;
                    final verticalSpacing = isCompactHeight
                        ? designTokens.spaceMedium
                        : designTokens.spaceLarge;
                    final panelMaxHeight = clampDouble(
                      constraints.maxHeight *
                          (isCompactHeight
                              ? componentTokens.compactPanelHeightFactor
                              : componentTokens.regularPanelHeightFactor),
                      componentTokens.panelMinHeight,
                      constraints.maxHeight,
                    );
                    final previewHeight = clampDouble(
                      constraints.maxHeight *
                          (isCompactHeight
                              ? componentTokens.compactPreviewHeightFactor
                              : componentTokens.regularPreviewHeightFactor),
                      componentTokens.panelMinHeight,
                      componentTokens.previewMaxHeight,
                    );

                    Widget buildHeader() {
                      return Row(
                        children: [
                          leading ??
                              _RoundHeaderButton(
                                icon: Icons.close_rounded,
                                onPressed: onClose,
                              ),
                          SizedBox(width: designTokens.spaceMedium),
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
                                  SizedBox(
                                    height: designTokens.spaceExtraSmall,
                                  ),
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
                          SizedBox(width: designTokens.spaceMedium),
                          trailing ??
                              SizedBox(
                                width: componentTokens.headerButtonSize,
                                height: componentTokens.headerButtonSize,
                              ),
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

                      return TilawaGlassPanel(child: panelChild);
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
