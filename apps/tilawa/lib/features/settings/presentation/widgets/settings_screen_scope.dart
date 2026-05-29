import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../../app_review/presentation/cubit/app_review_cubit.dart';
import '../../../share/domain/usecases/share_content_use_case.dart';
import '../screens/settings_screen.dart';

/// Composition root for [SettingsScreen] (main tab and `/settings` route).
class SettingsScreenScope extends StatelessWidget {
  const SettingsScreenScope({super.key, this.child});

  /// When set (e.g. in widget tests), replaces [SettingsScreen].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AppReviewCubit>(),
      child:
          child ??
          SettingsScreen(
            supportTilawaEnabled: getIt<AppLaunchConfig>().supportTilawaEnabled,
            shareContent: getIt<ShareContentUseCase>(),
          ),
    );
  }
}
