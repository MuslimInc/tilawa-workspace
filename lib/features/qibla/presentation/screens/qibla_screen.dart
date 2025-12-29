import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions.dart';
import '../bloc/qibla_bloc.dart';
import '../widgets/qibla_compass_widget.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return BlocProvider(
      create: (context) =>
          getIt<QiblaBloc>()..add(const CheckLocationService()),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(elevation: 0, title: Text(context.l10n.qiblaDirection)),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const Spacer(),
                    BlocBuilder<QiblaBloc, QiblaState>(
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
                            if (state.direction == null) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.onSurface,
                                ),
                              );
                            }
                            return QiblaCompassWidget(
                              qiblaDirection: state.direction!,
                            );
                          case QiblaStatus.initial:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 24.h,
                      ),
                      child: Text(
                        context.l10n.qiblaCompassTip,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 16.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80.r,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.onSurface,
              foregroundColor: colorScheme.surface,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: Text(context.l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}
