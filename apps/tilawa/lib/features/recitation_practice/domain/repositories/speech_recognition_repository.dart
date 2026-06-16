import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/speech_recognition_update.dart';

/// Captures and transcribes spoken Arabic recitation.
abstract class SpeechRecognitionRepository {
  Future<Either<Failure, void>> initialize();

  Future<Either<Failure, bool>> requestMicrophonePermission();

  Stream<SpeechRecognitionUpdate> watchRecognitionUpdates();

  Future<Either<Failure, void>> startListening({bool resetTranscript = true});

  Future<Either<Failure, String>> stopListening({
    bool clearTranscript = true,
    bool discardPendingLive = false,
  });

  Future<Either<Failure, void>> alignCommittedTranscript(
    String sanitizedPrefix,
  );

  Future<void> dispose();
}
