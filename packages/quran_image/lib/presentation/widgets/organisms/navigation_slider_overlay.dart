import 'package:flutter/material.dart';
import 'package:quran_image/l10n/quran_image_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../core/perf_logger.dart';
import '../../../domain/domain.dart';
import '../molecules/molecules.dart';

/// Organism component for the navigation slider overlay.
///
/// This is a complex widget that combines:
/// - Navigation button group (previous/next + page indicator)
/// - Page slider for fast navigation
/// - Fade in/out animations
/// - Gesture detection for interaction
class NavigationSliderOverlay extends StatelessWidget {
  const NavigationSliderOverlay({
    super.key,
    required this.screenWidth,
    required this.committedPage,
    required this.state,
    required this.canGoToPreviousPage,
    required this.canGoToNextPage,
    required this.onPreviewPageChanged,
    required this.onPageNavigationRequested,
    required this.onPreviousPageRequested,
    required this.onNextPageRequested,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    this.onShowIndex,
    this.trailingAction,
  });

  final double screenWidth;
  final int committedPage;
  final PageState state;
  final bool canGoToPreviousPage;
  final bool canGoToNextPage;
  final ValueChanged<int> onPreviewPageChanged;
  final ValueChanged<int> onPageNavigationRequested;
  final VoidCallback onPreviousPageRequested;
  final VoidCallback onNextPageRequested;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  /// Opens the surah index. Rendered as a button in the panel's bottom-anchored
  /// action row so it lives in the comfortable one-handed thumb arc instead of
  /// the hard-to-reach top corner.
  final VoidCallback? onShowIndex;

  /// Host-supplied action (e.g. the Mushaf/ayah-list view switch) placed at the
  /// end of the action row, also within thumb reach.
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('NavigationSliderOverlay');
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final componentTokens = theme.extension<MeMuslimComponentTokens>();
    final bottomInset = context.systemBottomSafeArea;
    final panelRadius = BorderRadius.circular(
      tokens.radiusExtraLarge,
    );
    final panelPadding = EdgeInsets.fromLTRB(
      tokens.spaceMedium,
      tokens.spaceExtraSmall,
      tokens.spaceMedium,
      tokens.spaceSmall,
    );

    return GestureDetector(
      onTapDown: (_) => onInteractionStart(),
      onTapUp: (_) => onInteractionEnd(),
      onHorizontalDragStart: (_) => onInteractionStart(),
      onHorizontalDragEnd: (_) => onInteractionEnd(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          0,
          tokens.spaceLarge,
          bottomInset + tokens.spaceSmall,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: tokens.contentMaxWidthForm),
            child: Builder(
              builder: (context) {
                final content = Builder(
                  builder: (context) {
                    final sw = PerfLogger.startTimer();
                    final hasActionRow =
                        onShowIndex != null || trailingAction != null;
                    final content = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PageSlider(
                          currentPage: state.displayPage,
                          committedPage: committedPage,
                          totalPages: state.totalPages,
                          onChanged: (value) =>
                              onPreviewPageChanged(value.round()),
                          onChangeEnd: (value) =>
                              onPageNavigationRequested(value.round()),
                          screenWidth: screenWidth,
                        ),
                        SizedBox(height: tokens.spaceSmall),
                        NavigationButtonGroup(
                          currentPage: state.displayPage,
                          totalPages: state.totalPages,
                          onPrevious: canGoToPreviousPage
                              ? onPreviousPageRequested
                              : null,
                          onNext: canGoToNextPage ? onNextPageRequested : null,
                          screenWidth: screenWidth,
                        ),
                        if (hasActionRow) ...[
                          SizedBox(height: tokens.spaceSmall),
                          _PanelActionRow(
                            onShowIndex: onShowIndex,
                            trailingAction: trailingAction,
                          ),
                        ],
                      ],
                    );
                    PerfLogger.logElapsed(
                      sw,
                      widgetName: 'NavigationSliderOverlay',
                      message:
                          'build displayPage=${state.displayPage} '
                          'currentPage=${state.currentPage}',
                    );
                    return content;
                  },
                );

                if (componentTokens != null) {
                  return TilawaGlassPanel(
                    enableBackdropBlur: true,
                    borderRadius: panelRadius,
                    backgroundColor: colorScheme.surface.withValues(
                      alpha: tokens.opacityGlass,
                    ),
                    borderColor: colorScheme.primary.withValues(
                      alpha: tokens.opacityMedium,
                    ),
                    padding: panelPadding,
                    child: content,
                  );
                }

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(
                      alpha: tokens.opacityGlass,
                    ),
                    borderRadius: panelRadius,
                    border: Border.all(
                      color: colorScheme.primary.withValues(
                        alpha: tokens.opacityMedium,
                      ),
                    ),
                  ),
                  child: Padding(padding: panelPadding, child: content),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-anchored row inside the navigation panel holding the surah-index
/// button and an optional host action (the view switch). Placed at the panel's
/// lower edge — the most comfortable part of the one-handed thumb arc.
class _PanelActionRow extends StatelessWidget {
  const _PanelActionRow({
    required this.onShowIndex,
    required this.trailingAction,
  });

  final VoidCallback? onShowIndex;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final indexLabel = QuranImageLocalizations.of(context).surahIndex;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: tokens.spaceSmall,
      children: [
        if (onShowIndex != null)
          _PanelIndexButton(label: indexLabel, onPressed: onShowIndex!)
        else
          const SizedBox.shrink(),
        trailingAction ?? const SizedBox.shrink(),
      ],
    );
  }
}

/// Labelled index button — icon + text so the now-primary "jump to surah"
/// action reads clearly in the panel.
class _PanelIndexButton extends StatelessWidget {
  const _PanelIndexButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(tokens.radiusLarge);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMedium,
              vertical: tokens.spaceSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.spaceExtraSmall,
              children: [
                Icon(
                  Icons.format_list_bulleted_rounded,
                  size: tokens.iconSizeMedium,
                  color: colorScheme.primary,
                ),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
