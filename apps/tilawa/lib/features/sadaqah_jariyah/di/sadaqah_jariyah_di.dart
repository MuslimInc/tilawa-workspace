import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/sadaqah_jariyah/data/datasources/dedications_remote_data_source.dart';
import 'package:tilawa/features/sadaqah_jariyah/data/datasources/sadaqah_jariyah_config_remote_data_source.dart';
import 'package:tilawa/features/sadaqah_jariyah/data/repositories/dedications_repository_impl.dart';
import 'package:tilawa/features/sadaqah_jariyah/data/repositories/sadaqah_jariyah_config_repository_impl.dart';
import 'package:tilawa/features/sadaqah_jariyah/data/services/firebase_dedication_photo_url_resolver.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/repositories/dedications_repository.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/repositories/sadaqah_jariyah_config_repository.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/services/dedication_photo_url_resolver.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/usecases/build_whatsapp_participate_uri_use_case.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/usecases/get_sadaqah_jariyah_page_use_case.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/cubit/sadaqah_jariyah_cubit.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Manual GetIt registrations for `sadaqah_jariyah`.
class SadaqahJariyahDi {
  SadaqahJariyahDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<BuildWhatsappParticipateUriUseCase>(
      BuildWhatsappParticipateUriUseCase.new,
    );
    getIt.registerLazySingletonIfAbsent<DedicationsRemoteDataSource>(
      () => FirestoreDedicationsRemoteDataSource(
        getIt<FirebaseFirestore>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DedicationsRepository>(
      () => DedicationsRepositoryImpl(
        getIt<DedicationsRemoteDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SadaqahJariyahConfigRemoteDataSource>(
      () => FirestoreSadaqahJariyahConfigRemoteDataSource(
        getIt<FirebaseFirestore>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DedicationPhotoUrlResolver>(
      () => FirebaseDedicationPhotoUrlResolver(getIt<FirebaseStorage>()),
    );
    getIt.registerLazySingletonIfAbsent<SadaqahJariyahConfigRepository>(
      () => SadaqahJariyahConfigRepositoryImpl(
        getIt<SadaqahJariyahConfigRemoteDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetSadaqahJariyahPageUseCase>(
      () => GetSadaqahJariyahPageUseCase(
        getIt<DedicationsRepository>(),
        getIt<SadaqahJariyahConfigRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SadaqahJariyahCubit>(
      () => SadaqahJariyahCubit(
        getIt<GetSadaqahJariyahPageUseCase>(),
        getIt<DedicationPhotoUrlResolver>(),
        getIt<AnalyticsService>(),
      ),
    );
  }
}
