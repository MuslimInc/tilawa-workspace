import 'package:injectable/injectable.dart';

import '../repositories/whats_new_progress_repository.dart';

@lazySingleton
class MarkWhatsNewSeenUseCase {
  MarkWhatsNewSeenUseCase(this._progressRepository);

  final WhatsNewProgressRepository _progressRepository;

  Future<void> call(String releaseId) =>
      _progressRepository.markReleaseSeen(releaseId);
}
