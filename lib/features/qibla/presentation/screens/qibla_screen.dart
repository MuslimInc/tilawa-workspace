import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/qibla_bloc.dart';
import '../widgets/qibla_compass_widget.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocProvider(
      create: (context) =>
          getIt<QiblaBloc>()..add(const CheckLocationService()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(AppLocalizations.of(context)!.qiblaDirection),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
                Colors.black,
              ],
            ),
          ),
          child: BlocBuilder<QiblaBloc, QiblaState>(
            builder: (context, state) {
              switch (state.status) {
                case QiblaStatus.loading:
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                case QiblaStatus.serviceDisabled:
                  return _buildErrorState(
                    context,
                    AppLocalizations.of(context)!.locationServiceDisabled,
                    AppLocalizations.of(context)!.enableLocationServiceMessage,
                    Icons.location_off_rounded,
                    () => context.read<QiblaBloc>().add(
                      const CheckLocationService(),
                    ),
                  );
                case QiblaStatus.permissionDenied:
                  return _buildErrorState(
                    context,
                    AppLocalizations.of(context)!.permissionDenied,
                    AppLocalizations.of(
                      context,
                    )!.locationPermissionRequiredMessage,
                    Icons.security_rounded,
                    () => context.read<QiblaBloc>().add(
                      const RequestLocationPermission(),
                    ),
                  );
                case QiblaStatus.error:
                  return _buildErrorState(
                    context,
                    AppLocalizations.of(context)!.error,
                    state.errorMessage ??
                        AppLocalizations.of(context)!.anErrorOccurred,
                    Icons.error_outline_rounded,
                    () => context.read<QiblaBloc>().add(
                      const CheckLocationService(),
                    ),
                  );
                case QiblaStatus.success:
                  if (state.direction == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  return Center(
                    child: QiblaCompassWidget(direction: state.direction!),
                  );
                case QiblaStatus.initial:
                  return const SizedBox.shrink();
              }
            },
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80.r, color: Colors.white.withValues(alpha: 0.8)),
          SizedBox(height: 24.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.tryAgain),
          ),
        ],
      ),
    );
  }
}
