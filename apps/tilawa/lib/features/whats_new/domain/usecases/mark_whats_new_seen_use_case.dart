import '../repositories/whats_new_progress_repository.dart';

class MarkWhatsNewSeenUseCase {
  MarkWhatsNewSeenUseCase(this._progressRepository);

  final WhatsNewProgressRepository _progressRepository;

  Future<void> call(String releaseId) =>
      _progressRepository.markReleaseSeen(releaseId);
}
