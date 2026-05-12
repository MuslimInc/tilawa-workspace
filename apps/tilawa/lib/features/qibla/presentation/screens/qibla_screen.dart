import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../shared/widgets/quran_player_widget.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.qiblaCompassAccuracyPoor)),
            );
          },
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              leading: context.canPop() ? const TilawaBackButton() : null,
              title: Text(context.l10n.qiblaDirection),
            ),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: isLandscape
                        ? const _LandscapeContent()
                        : const _PortraitContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: QuranPlayerWidget()),
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
        const Spacer(),
        BlocBuilder<QiblaBloc, QiblaState>(
          buildWhen: (previous, current) => previous.status != current.status,
          builder: (context, state) {
            switch (state.status) {
              case QiblaStatus.loading:
                return TilawaLoadingIndicator(color: colorScheme.onSurface);
              case QiblaStatus.serviceDisabled:
                return _QiblaUnavailableState(
                  icon: Icons.location_off_rounded,
                  iconColor: colorScheme.outline,
                  title: context.l10n.locationServiceDisabled,
                  subtitle: context.l10n.enableLocationServiceMessage,
                  retryLabel: context.l10n.tryAgain,
                  onRetry: () => context.read<QiblaBloc>().add(
                    const CheckLocationService(),
                  ),
                );
              case QiblaStatus.permissionDenied:
                return _QiblaUnavailableState(
                  icon: Icons.security_rounded,
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
                  iconColor: colorScheme.error,
                  title: context.l10n.error,
                  subtitle: state.errorMessage ?? context.l10n.anErrorOccurred,
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
                    return QiblaCompassWidget(qiblaDirection: direction);
                  },
                );
              case QiblaStatus.initial:
                return const SizedBox.shrink();
            }
          },
        ),
        const Spacer(),
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
              iconColor: colorScheme.outline,
              title: context.l10n.locationServiceDisabled,
              subtitle: context.l10n.enableLocationServiceMessage,
              retryLabel: context.l10n.tryAgain,
              onRetry: () =>
                  context.read<QiblaBloc>().add(const CheckLocationService()),
            );
          case QiblaStatus.permissionDenied:
            return _QiblaUnavailableState(
              icon: Icons.security_rounded,
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
              iconColor: colorScheme.error,
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
                return QiblaCompassWidget(qiblaDirection: direction);
              },
            );
          case QiblaStatus.initial:
            return const SizedBox.shrink();
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
    this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String retryLabel;
  final VoidCallback onRetry;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return TilawaIllustratedState(
      icon: icon,
      iconColor: iconColor ?? Theme.of(context).colorScheme.primary,
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
