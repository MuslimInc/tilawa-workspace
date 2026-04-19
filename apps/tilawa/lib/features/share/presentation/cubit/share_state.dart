import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/share_content.dart';
import '../../../quran_reader/domain/entities/entities.dart';

part 'share_state.freezed.dart';

enum ShareStatus { idle, capturing, generating, reviewing, sharing, error }

@freezed
abstract class ShareState with _$ShareState {
  const factory ShareState({
    @Default(ShareStatus.idle) ShareStatus status,
    // Audio clip configuration
    int? surahNumber,
    int? fromAyah,
    int? toAyah,
    String? reciterName,
    String? reciterServerUrl,
    // Progress tracking
    @Default(0.0) double progress,
    @Default('') String progressMessage,
    // Generated content
    ShareContent? content,
    // Error
    String? errorMessage,
    List<PageAyahInfo>? ayahs,
  }) = _ShareState;
}
