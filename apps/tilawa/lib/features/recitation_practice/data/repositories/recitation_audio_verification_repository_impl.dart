import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/recitation_comparison_result.dart';
import '../../domain/entities/recitation_target.dart';
import '../../domain/repositories/recitation_audio_verification_repository.dart';
import '../services/microphone_permission_service.dart';
import '../services/recitation_audio_recorder.dart';
import '../services/recitation_audio_verification_client.dart';

@LazySingleton(as: RecitationAudioVerificationRepository)
class RecitationAudioVerificationRepositoryImpl
    implements RecitationAudioVerificationRepository {
  RecitationAudioVerificationRepositoryImpl(
    this._recorder,
    this._client,
    this._permissionService,
  );

  final RecitationAudioRecorder _recorder;
  final RecitationAudioVerificationClient _client;
  final MicrophonePermissionService _permissionService;

  @override
  Future<Either<Failure, void>> startRecording(RecitationTarget target) async {
    try {
      final bool granted = await _permissionService.requestPermission();
      if (!granted) {
        return Left(
          Failure.permissionDenied('Microphone permission is required.'),
        );
      }
      await _recorder.start(target);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }

  @override
  Future<Either<Failure, RecitationComparisonResult>> stopAndVerify(
    RecitationTarget target,
  ) async {
    String? audioPath;
    try {
      audioPath = await _recorder.stop();
      if (audioPath == null) {
        return Left(
          Failure.validationError('No recitation audio was captured.'),
        );
      }

      final RecitationComparisonResult result = await _client.verify(
        target: target,
        audioPath: audioPath,
        sampleRate: _recorder.sampleRate,
      );
      return Right(result);
    } on Failure catch (failure) {
      return Left(failure);
    } on FirebaseFunctionsException catch (error) {
      return Left(Failure.serverError(_messageForFunctionsException(error)));
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    } finally {
      if (audioPath != null) {
        try {
          await File(audioPath).delete();
        } catch (_) {
          // Best-effort cleanup for temporary recitation audio.
        }
      }
    }
  }

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> dispose() => _recorder.dispose();

  String _messageForFunctionsException(FirebaseFunctionsException error) {
    return switch (error.code.toLowerCase()) {
      'not-found' =>
        'Recitation verifier function was not found. Deploy '
            'verifyRecitationAudio in us-central1 or set '
            'TILAWA_RECITATION_VERIFIER_FUNCTION to the deployed callable.',
      'failed-precondition' =>
        error.message ?? 'Recitation verifier is not configured.',
      'permission-denied' =>
        error.message ??
            'Recitation verifier rejected this app. Check Firebase App Check.',
      'unauthenticated' =>
        'Recitation verifier rejected this app. Check Firebase App Check.',
      'unavailable' => error.message ?? 'Recitation verifier is unavailable.',
      _ => error.message ?? error.code,
    };
  }
}
