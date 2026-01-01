import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
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
