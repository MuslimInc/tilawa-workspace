import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_startup_service.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/device_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:tilawa/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:tilawa/features/notifications/data/services/fcm_service.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_lab_service.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_log_store.dart';
import 'package:tilawa/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:tilawa/features/notifications/domain/usecases/handle_fcm_notification_use_case.dart';
import 'package:tilawa/features/notifications/presentation/services/fcm_notification_handler_service.dart';
import 'package:tilawa/features/quran_sessions/domain/services/session_taken_over_notifier.dart';
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

/// Manual GetIt registrations for `notifications`.
class NotificationsDi {
  NotificationsDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<NotificationDebugLogStore>(
      NotificationDebugLogStore.new,
    );
    getIt.registerLazySingletonIfAbsent<HandleFcmNotificationUseCase>(
      HandleFcmNotificationUseCase.new,
    );
    getIt.registerLazySingletonIfAbsent<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(
        getIt<FirebaseMessaging>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<FCMNotificationHandlerService>(
      () => FCMNotificationHandlerService(
        getIt<INotificationDispatcher>(),
        getIt<Logger>(),
        getIt<NavigationService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<NotificationsRepository>(
      () => NotificationsRepositoryImpl(
        getIt<NotificationsRemoteDataSource>(),
        getIt<INotificationDispatcher>(),
        getIt<FCMNotificationHandlerService>(),
        getIt<Logger>(),
        getIt<TeacherCapabilityRefreshNotifier>(),
        getIt<SessionRevokedNotifier>(),
        getIt<SessionTakenOverNotifier>(),
        getIt<DeviceRevokedNotifier>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<NotificationDebugLabService>(
      () => NotificationDebugLabService(
        getIt<INotificationDispatcher>(),
        getIt<SharedPreferencesAsync>(),
        getIt<ProcessIdProvider>(),
        getIt<NavigationService>(),
        getIt<NotificationDebugLogStore>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<FCMService>(
      () => FCMService(
        getIt<AuthRepository>(),
        getIt<SyncDeviceTokenUseCase>(),
        getIt<DeviceTokenService>(),
      ),
    );
  }
}
