import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';

import '../../../../shared/widgets/bottom_player_widget.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';
import '../../domain/entities/qibla_direction_entity.dart';
import '../bloc/qibla_bloc.dart';
import '../widgets/qibla_compass_widget.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QiblaBloc>().add(const CheckLocationService());
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Scaffold(
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
                  child: Column(
                    children: [
                      const Spacer(),
                      BlocBuilder<QiblaBloc, QiblaState>(
                        // Only rebuild the outer switch on status transitions.
                        // Direction-only updates are handled by the inner
                        // BlocSelector so only QiblaCompassWidget rebuilds.
                        buildWhen: (previous, current) =>
                            previous.status != current.status,
                        builder: (context, state) {
                          switch (state.status) {
                            case QiblaStatus.loading:
                              return Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.onSurface,
                                ),
                              );
                            case QiblaStatus.serviceDisabled:
                              return _buildErrorState(
                                context,
                                context.l10n.locationServiceDisabled,
                                context.l10n.enableLocationServiceMessage,
                                Icons.location_off_rounded,
                                () => context.read<QiblaBloc>().add(
                                  const CheckLocationService(),
                                ),
                              );
                            case QiblaStatus.permissionDenied:
                              return _buildErrorState(
                                context,
                                context.l10n.permissionDenied,
                                context.l10n.locationPermissionRequiredMessage,
                                Icons.security_rounded,
                                () => context.read<QiblaBloc>().add(
                                  const RequestLocationPermission(),
                                ),
                              );
                            case QiblaStatus.error:
                              return _buildErrorState(
                                context,
                                context.l10n.error,
                                state.errorMessage ??
                                    context.l10n.anErrorOccurred,
                                Icons.error_outline_rounded,
                                () => context.read<QiblaBloc>().add(
                                  const CheckLocationService(),
                                ),
                              );
                            case QiblaStatus.success:
                              // Subscribe only the compass widget to direction
                              // updates — the outer switch won't rebuild on
                              // every sensor tick.
                              return BlocSelector<
                                QiblaBloc,
                                QiblaState,
                                QiblaDirectionEntity?
                              >(
                                selector: (s) => s.direction,
                                builder: (context, direction) {
                                  if (direction == null) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onSurface,
                                      ),
                                    );
                                  }
                                  return QiblaCompassWidget(
                                    qiblaDirection: direction,
                                  );
                                },
                              );
                            case QiblaStatus.initial:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ).copyWith(bottom: 120),
                        child: Text(
                          context.l10n.qiblaCompassTip,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned.fill(child: BottomPlayerWidget()),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    VoidCallback onRetry,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.onSurface,
              foregroundColor: colorScheme.surface,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(context.l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}
