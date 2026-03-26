import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/share_content.dart';

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
    // Video capture
    GlobalKey? boundaryKey,
    // Error
    String? errorMessage,
  }) = _ShareState;
}
