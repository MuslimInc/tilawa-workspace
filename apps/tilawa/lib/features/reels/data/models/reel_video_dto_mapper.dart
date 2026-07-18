import '../../domain/entities/reel.dart';
import 'reel_video_dto.dart';

extension ReelSheikhDtoMapper on ReelSheikhDto {
  List<Reel> toReels() {
    return videos
        .map(
          (v) => Reel(
            id: v.id,
            sheikhId: id,
            sheikhName: reciterName,
            videoUrl: v.videoUrl,
            thumbUrl: v.videoThumbUrl,
            categoryId: v.videoType,
          ),
        )
        .toList();
  }
}
