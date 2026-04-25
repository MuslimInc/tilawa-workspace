import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
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

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

class AudioFailure extends Failure {
  const AudioFailure([super.message]);
}

enum OfflinePlaybackReason { notDownloaded, fileMissing, downloadIncomplete }

class OfflinePlaybackFailure extends NetworkFailure {
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

class ServerException implements Exception {
  ServerException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'Server exception';
}

class CacheException implements Exception {
  CacheException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'Cache exception';
}

class AudioException implements Exception {
  AudioException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'Audio exception';
}

// Additional failure types for new features
class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message]);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message]);
}

class PersistenceFailure extends Failure {
  const PersistenceFailure([super.message]);
}

class UIError extends Failure {
  const UIError([super.message]);
}
