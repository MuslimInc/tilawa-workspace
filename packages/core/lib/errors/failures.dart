import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];

  // Factory methods for easier failure creation
  static Failure unexpectedError(String message) => UnexpectedFailure(message);
  static Failure validationError(String message) => ValidationFailure(message);
  static Failure permissionDenied(String message) => PermissionFailure(message);
  static Failure cacheError(String message) => CacheFailure(message);
  static Failure serverError(String message) => ServerFailure(message);
  static Failure networkError(String message) => NetworkFailure(message);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

final class AudioFailure extends Failure {
  const AudioFailure([super.message]);
}

enum VideoGenerationFailureReason {
  missingScreenshot,
  invalidFrameFormat,
  invalidOutput,
  encodingFailed,
}

final class VideoGenerationFailure extends Failure {
  const VideoGenerationFailure([
    super.message,
    this.reason = VideoGenerationFailureReason.encodingFailed,
  ]);

  final VideoGenerationFailureReason reason;

  @override
  List<Object?> get props => [message, reason];
}

enum OfflinePlaybackReason { notDownloaded, fileMissing, downloadIncomplete }

final class OfflinePlaybackFailure extends NetworkFailure {
  const OfflinePlaybackFailure([
    super.message = 'Cannot play online content while offline',
    this.reason = OfflinePlaybackReason.notDownloaded,
  ]);

  final OfflinePlaybackReason reason;

  @override
  List<Object?> get props => [message, reason];
}

// Exception classes for throwing
class NetworkException implements Exception {
  NetworkException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'Network exception';
}

final class ServerException implements Exception {
  ServerException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'Server exception';
}

final class CacheException implements Exception {
  CacheException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'Cache exception';
}

final class AudioException implements Exception {
  AudioException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'Audio exception';
}

// Additional failure types for new features
final class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message]);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message]);
}

final class PersistenceFailure extends Failure {
  const PersistenceFailure([super.message]);
}

final class UIError extends Failure {
  const UIError([super.message]);
}

final class UserCancelledFailure extends Failure {
  const UserCancelledFailure([super.message]);
}

enum NotificationFailureReason { missingPayload, invalidPayload }

final class NotificationFailure extends Failure {
  const NotificationFailure([
    super.message,
    this.reason = NotificationFailureReason.missingPayload,
  ]);

  final NotificationFailureReason reason;

  @override
  List<Object?> get props => [message, reason];
}
