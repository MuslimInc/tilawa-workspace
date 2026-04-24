import 'package:injectable/injectable.dart';
import '../../presentation/utils/share_ayah_range_utils.dart';
import '../../presentation/utils/video_page_specs.dart';
import '../entities/share_range_result.dart';

@injectable
class PrepareShareRangeUseCase {
  const PrepareShareRangeUseCase();

  ShareRangeResult call({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
  }) {
    final range = normalizeShareAyahRange(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );

    final specs = buildVideoPageSpecs(
      surahNumber: surahNumber,
      fromAyah: range.fromAyah,
      toAyah: range.toAyah,
    );

    return ShareRangeResult(
      fromAyah: range.fromAyah,
      toAyah: range.toAyah,
      videoPageSpecs: specs,
    );
  }
}
