import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/repositories/speech_recognition_repository.dart';
import '../datasources/speech_recognition_datasource.dart';
import '../services/microphone_permission_service.dart';

@Injectable(as: SpeechRecognitionRepository)
class SpeechRecognitionRepositoryImpl implements SpeechRecognitionRepository {
  SpeechRecognitionRepositoryImpl(
    this._datasource,
    this._permissionService,
  );

  final SpeechRecognitionDatasource _datasource;
  final MicrophonePermissionService _permissionService;

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      final bool isAvailable = await _datasource.initialize();
      if (!isAvailable) {
        return Left(
          Failure.unexpectedError('Speech recognition is unavailable.'),
        );
      }
      return const Right(null);
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    try {
      final bool granted = await _permissionService.requestPermission();
      return Right(granted);
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  @override
  Stream<String> watchTranscript() => _datasource.transcriptStream;

  @override
  Future<Either<Failure, void>> startListening() async {
    try {
      await _datasource.startListening();
      return const Right(null);
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    try {
      final String transcript = await _datasource.stopListening();
      return Right(transcript);
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  @override
  Future<void> dispose() => _datasource.dispose();
}
