import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../domain/entities/dedication.dart';
import '../../domain/entities/sadaqah_jariyah_page_data.dart';
import '../../domain/services/dedication_photo_url_resolver.dart';
import '../../domain/usecases/get_sadaqah_jariyah_page_use_case.dart';
import 'sadaqah_jariyah_state.dart';

@injectable
class SadaqahJariyahCubit extends Cubit<SadaqahJariyahState> {
  SadaqahJariyahCubit(
    this._getPage,
    this._photoUrlResolver,
    this._analytics,
  ) : super(const SadaqahJariyahInitial());

  final GetSadaqahJariyahPageUseCase _getPage;
  final DedicationPhotoUrlResolver _photoUrlResolver;
  final AnalyticsService _analytics;

  Future<void> load() async {
    emit(const SadaqahJariyahLoading());
    final result = await _getPage(const GetSadaqahJariyahPageParams());
    await result.foldAsync(
      (Failure failure) async {
        emit(SadaqahJariyahError(failure));
      },
      (SadaqahJariyahPageData pageData) async {
        final Map<String, String?> photoUrls = <String, String?>{};
        for (final Dedication d in pageData.dedications) {
          photoUrls[d.id] = await _photoUrlResolver.resolveDownloadUrl(
            d.photoStoragePath,
          );
        }
        emit(SadaqahJariyahLoaded(pageData: pageData, photoUrls: photoUrls));
        await _analytics.logEvent(AnalyticsEvents.sadaqahJariyahScreenViewed);
      },
    );
  }

  Future<void> logCtaTapped() {
    return _analytics.logEvent(AnalyticsEvents.sadaqahJariyahCtaTapped);
  }
}
