import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/quran_assets_prefetch_policy_service.dart';
import 'package:tilawa/features/auth/data/datasources/profile_avatar_storage.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/downloads/domain/services/download_queue_service_interface.dart';
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';
import 'package:tilawa/features/settings/presentation/cubit/edit_profile_cubit.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

/// Manual GetIt registrations for `settings`.
class SettingsDi {
  SettingsDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<TeacherCapabilityRefreshNotifier>(
      TeacherCapabilityRefreshNotifier.new,
    );
    getIt.registerFactoryIfAbsent<EditProfileCubit>(
      () => EditProfileCubit(
        getIt<UserRepository>(),
        getIt<ProfileAvatarStorage>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SettingsCubit>(
      () => SettingsCubit(
        getIt<IDownloadQueueService>(),
        getIt<AppInfoService>(),
        getIt<QuranAssetsPrefetchPolicyService>(),
      ),
    );
  }
}
