import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

/// Captures and transcribes spoken Arabic recitation.
abstract class SpeechRecognitionRepository {
  Future<Either<Failure, void>> initialize();

  Future<Either<Failure, bool>> requestMicrophonePermission();

  Stream<String> watchTranscript();

  Future<Either<Failure, void>> startListening();

  Future<Either<Failure, String>> stopListening();

  Future<void> dispose();
}
