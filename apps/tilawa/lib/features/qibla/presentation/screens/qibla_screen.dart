import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/qibla_direction_entity.dart';
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

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
            ToastUtils.showToast(msg: context.l10n.qiblaCompassAccuracyPoor);
          },
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: TilawaCatalogAppBar.titleOnly(
              context,
              title: context.l10n.qiblaDirection,
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      const Positioned.fill(child: _QiblaAmbientBackground()),
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
        const _TipText(bottomPadding: kPortraitTipBottomPadding),
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
          child: Center(child: _TipText()),
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

class _QiblaAmbientBackground extends StatelessWidget {
  const _QiblaAmbientBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExcludeSemantics(
      child: CustomPaint(
        painter: _QiblaAmbientPainter(
          colorScheme: theme.colorScheme,
          tokens: theme.tokens,
        ),
      ),
    );
  }
}

class _QiblaAmbientPainter extends CustomPainter {
  const _QiblaAmbientPainter({
    required this.colorScheme,
    required this.tokens,
  });

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.34);
    final shortest = size.shortestSide;

    final primaryStroke = Paint()
      ..color = colorScheme.primary.withValues(
        alpha: tokens.opacitySubtle * 0.5,
      )
      ..strokeWidth = tokens.borderWidthThin
      ..style = PaintingStyle.stroke;
    final tertiaryStroke = Paint()
      ..color = colorScheme.tertiary.withValues(
        alpha: tokens.opacitySubtle * 0.4,
      )
      ..strokeWidth = tokens.borderWidthThin
      ..style = PaintingStyle.stroke;
    final guideStroke = Paint()
      ..color = colorScheme.outlineVariant.withValues(
        alpha: tokens.opacitySubtle * 0.5,
      )
      ..strokeWidth = tokens.borderWidthThin
      ..style = PaintingStyle.stroke;

    for (final factor in <double>[0.58, 0.88]) {
      final radius = shortest * factor;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        math.pi * 1.08,
        math.pi * 0.84,
        false,
        primaryStroke,
      );
    }

    final lowerCenter = Offset(size.width / 2, size.height * 0.72);
    for (final factor in <double>[0.56]) {
      final radius = shortest * factor;
      final rect = Rect.fromCircle(center: lowerCenter, radius: radius);
      canvas.drawArc(
        rect,
        math.pi * 1.18,
        math.pi * 0.64,
        false,
        tertiaryStroke,
      );
    }

    canvas.drawLine(
      Offset(center.dx, tokens.spaceExtraLarge),
      Offset(center.dx, size.height - tokens.spaceExtraLarge),
      guideStroke,
    );
  }

  @override
  bool shouldRepaint(_QiblaAmbientPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.tokens != tokens;
  }
}

class _QiblaCompassPanel extends StatelessWidget {
  const _QiblaCompassPanel({required this.direction});

  final QiblaDirectionEntity direction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: tokens.contentMaxWidthForm * kQiblaPanelMaxWidthFactor,
          ),
          child: TilawaGlassPanel(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMedium,
              vertical: tokens.spaceLarge,
            ),
            backgroundColor: colorScheme.surface.withValues(
              alpha: tokens.opacityGlass,
            ),
            borderColor: colorScheme.primary.withValues(
              alpha: tokens.opacitySubtle,
            ),
            child: QiblaCompassWidget(qiblaDirection: direction),
          ),
        ),
      ),
    );
  }
}

class _TipText extends StatelessWidget {
  const _TipText({this.bottomPadding = kDefaultTipBottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kTipHorizontalPadding,
        vertical: kTipVerticalPadding,
      ).copyWith(bottom: bottomPadding),
      child: Text(
        context.l10n.qiblaCompassTip,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontSize: kTipFontSize,
          fontWeight: kTipFontWeight,
        ),
      ),
    );
  }
}
