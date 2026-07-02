import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/qibla_direction_entity.dart';
import '../../domain/qibla_heading_math.dart';
import '../bloc/qibla_bloc.dart';
import '../constants/qibla_constants.dart';
import '../widgets/qibla_compass_widget.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  QiblaBloc? _qiblaBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _qiblaBloc = context.read<QiblaBloc>();
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('[CompassSensor] QiblaScreen.initState');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final QiblaBloc? qiblaBloc = _qiblaBloc;
      if (qiblaBloc == null || qiblaBloc.isClosed) return;
      if (kDebugMode) {
        debugPrint('[CompassSensor] QiblaScreen -> CheckLocationService');
      }
      qiblaBloc.add(const CheckLocationService());
    });
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('[CompassSensor] QiblaScreen.dispose -> StopQiblaStream');
    }
    final QiblaBloc? qiblaBloc = _qiblaBloc;
    if (qiblaBloc != null && !qiblaBloc.isClosed) {
      qiblaBloc.add(const StopQiblaStream());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        BlocListener<QiblaBloc, QiblaState>(
          listenWhen: (previous, current) {
            final bool wasPoor =
                previous.direction?.hasPoorCompassAccuracy ?? false;
            final bool isPoor =
                current.direction?.hasPoorCompassAccuracy ?? false;
            return !wasPoor && isPoor;
          },
          listener: (context, state) {
            TilawaFeedback.showToast(
              context,
              message: context.l10n.qiblaCompassAccuracyPoor,
              variant: TilawaFeedbackVariant.warning,
            );
          },
          child: Scaffold(
            appBar: TilawaCatalogAppBar(
              preferredHeight: TilawaCatalogAppBar.resolvePreferredHeight(
                context,
                title: context.l10n.qiblaFinderTitle,
                titleBlockHeight: tilawaMeasureTextHeight(
                  context: context,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  text: context.l10n.qiblaFinderTitle,
                ),
              ),
              centerTitle: false,
              titleWidget: Text(
                context.l10n.qiblaFinderTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: isLandscape
                                  ? const _LandscapeContent()
                                  : const _PortraitContent(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PortraitContent extends StatelessWidget {
  const _PortraitContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: BlocBuilder<QiblaBloc, QiblaState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status,
                builder: (context, state) {
                  switch (state.status) {
                    case QiblaStatus.loading:
                      return TilawaLoadingIndicator(
                        color: colorScheme.onSurface,
                      );
                    case QiblaStatus.serviceDisabled:
                      return _QiblaUnavailableState(
                        icon: Icons.location_off_rounded,
                        tone: TilawaStateVisualTone.neutral,
                        title: context.l10n.locationServiceDisabled,
                        subtitle: context.l10n.enableLocationServiceMessage,
                        retryLabel: context.l10n.tryAgain,
                        onRetry: () => context.read<QiblaBloc>().add(
                          const CheckLocationService(),
                        ),
                      );
                    case QiblaStatus.permissionDenied:
                      return _QiblaUnavailableState(
                        icon: Icons.explore_off_rounded,
                        tone: TilawaStateVisualTone.tertiary,
                        title: context.l10n.permissionDenied,
                        subtitle:
                            context.l10n.locationPermissionRequiredMessage,
                        retryLabel: context.l10n.tryAgain,
                        onRetry: () => context.read<QiblaBloc>().add(
                          const RequestLocationPermission(),
                        ),
                      );
                    case QiblaStatus.error:
                      return _QiblaUnavailableState(
                        icon: Icons.error_outline_rounded,
                        tone: TilawaStateVisualTone.error,
                        title: context.l10n.error,
                        subtitle:
                            state.errorMessage ?? context.l10n.anErrorOccurred,
                        retryLabel: context.l10n.tryAgain,
                        onRetry: () => context.read<QiblaBloc>().add(
                          const CheckLocationService(),
                        ),
                      );
                    case QiblaStatus.success:
                      return BlocSelector<
                        QiblaBloc,
                        QiblaState,
                        QiblaDirectionEntity?
                      >(
                        selector: (s) => s.direction,
                        builder: (context, direction) {
                          if (direction == null) {
                            return TilawaLoadingIndicator(
                              color: colorScheme.onSurface,
                            );
                          }
                          return _QiblaCompassPanel(direction: direction);
                        },
                      );
                    case QiblaStatus.initial:
                      return TilawaLoadingIndicator(
                        color: colorScheme.onSurface,
                      );
                  }
                },
              ),
            ),
          ),
        ),
        const _QiblaInstructionFooter(bottomPadding: kPortraitTipBottomPadding),
      ],
    );
  }
}

class _LandscapeContent extends StatelessWidget {
  const _LandscapeContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Expanded(flex: kLandscapeCompassFlex, child: _CompassArea()),
        Expanded(
          flex: kLandscapeTextFlex,
          child: Center(child: _QiblaInstructionFooter()),
        ),
        const Spacer(),
      ],
    );
  }
}

class _CompassArea extends StatelessWidget {
  const _CompassArea();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<QiblaBloc, QiblaState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        switch (state.status) {
          case QiblaStatus.loading:
            return TilawaLoadingIndicator(color: colorScheme.onSurface);
          case QiblaStatus.serviceDisabled:
            return _QiblaUnavailableState(
              icon: Icons.location_off_rounded,
              tone: TilawaStateVisualTone.neutral,
              title: context.l10n.locationServiceDisabled,
              subtitle: context.l10n.enableLocationServiceMessage,
              retryLabel: context.l10n.tryAgain,
              onRetry: () =>
                  context.read<QiblaBloc>().add(const CheckLocationService()),
            );
          case QiblaStatus.permissionDenied:
            return _QiblaUnavailableState(
              icon: Icons.explore_off_rounded,
              tone: TilawaStateVisualTone.tertiary,
              title: context.l10n.permissionDenied,
              subtitle: context.l10n.locationPermissionRequiredMessage,
              retryLabel: context.l10n.tryAgain,
              onRetry: () => context.read<QiblaBloc>().add(
                const RequestLocationPermission(),
              ),
            );
          case QiblaStatus.error:
            return _QiblaUnavailableState(
              icon: Icons.error_outline_rounded,
              tone: TilawaStateVisualTone.error,
              title: context.l10n.error,
              subtitle: state.errorMessage ?? context.l10n.anErrorOccurred,
              retryLabel: context.l10n.tryAgain,
              onRetry: () =>
                  context.read<QiblaBloc>().add(const CheckLocationService()),
            );
          case QiblaStatus.success:
            return BlocSelector<QiblaBloc, QiblaState, QiblaDirectionEntity?>(
              selector: (s) => s.direction,
              builder: (context, direction) {
                if (direction == null) {
                  return TilawaLoadingIndicator(color: colorScheme.onSurface);
                }
                return _QiblaCompassPanel(direction: direction);
              },
            );
          case QiblaStatus.initial:
            return TilawaLoadingIndicator(color: colorScheme.onSurface);
        }
      },
    );
  }
}

class _QiblaUnavailableState extends StatelessWidget {
  const _QiblaUnavailableState({
    required this.icon,
    required this.title,
    required this.retryLabel,
    required this.onRetry,
    this.tone = TilawaStateVisualTone.primary,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String retryLabel;
  final VoidCallback onRetry;
  final TilawaStateVisualTone tone;

  @override
  Widget build(BuildContext context) {
    return TilawaIllustratedState(
      visual: TilawaStateVisual(icon: icon, tone: tone),
      title: title,
      subtitle: subtitle,
      semanticLabel: title,
      primaryAction: TilawaButton(
        text: retryLabel,
        variant: TilawaButtonVariant.secondary,
        leadingIcon: const Icon(Icons.refresh_rounded),
        onPressed: onRetry,
      ),
    );
  }
}

class _QiblaCompassPanel extends StatelessWidget {
  const _QiblaCompassPanel({required this.direction});

  final QiblaDirectionEntity direction;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: tokens.contentMaxWidthForm * kQiblaPanelMaxWidthFactor,
          ),
          child: QiblaCompassWidget(qiblaDirection: direction),
        ),
      ),
    );
  }
}

class _QiblaInstructionFooter extends StatelessWidget {
  const _QiblaInstructionFooter({
    this.bottomPadding = kDefaultTipBottomPadding,
  });

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<QiblaBloc, QiblaState, QiblaDirectionEntity?>(
      selector: (state) =>
          state.status == QiblaStatus.success ? state.direction : null,
      builder: (context, direction) {
        if (direction == null) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        final String message;
        if (direction.isAligned) {
          message = l10n.qiblaAligned;
        } else {
          final ({int degrees, bool rotateLeft}) hint = _qiblaRotationHint(
            direction,
          );
          message = hint.rotateLeft
              ? l10n.qiblaRotatePhoneLeft(hint.degrees)
              : l10n.qiblaRotatePhoneRight(hint.degrees);
        }

        return _QiblaInstructionChip(
          message: message,
          bottomPadding: bottomPadding,
        );
      },
    );
  }
}

({int degrees, bool rotateLeft}) _qiblaRotationHint(
  QiblaDirectionEntity direction,
) {
  final double delta = shortestHeadingDelta(
    bearing: direction.offset,
    heading: direction.direction,
  );
  final int degrees = delta.abs().round().clamp(1, 180);
  return (degrees: degrees, rotateLeft: delta < 0);
}

class _QiblaInstructionChip extends StatelessWidget {
  const _QiblaInstructionChip({
    required this.message,
    required this.bottomPadding,
  });

  final String message;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kTipHorizontalPadding,
        vertical: kTipVerticalPadding,
      ).copyWith(bottom: bottomPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
            width: tokens.borderWidthThin,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceMedium,
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: kTipFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
