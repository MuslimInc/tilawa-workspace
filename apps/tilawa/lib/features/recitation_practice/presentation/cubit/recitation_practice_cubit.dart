import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/recitation_comparison_result.dart';
import '../../domain/entities/recitation_target.dart';
import '../../domain/usecases/compare_recitation_use_case.dart';
import '../../domain/usecases/get_page_recitation_targets_use_case.dart';
import '../../domain/usecases/request_microphone_permission_use_case.dart';
import '../../domain/repositories/speech_recognition_repository.dart';
import 'recitation_practice_state.dart';

@injectable
class RecitationPracticeCubit extends Cubit<RecitationPracticeState> {
  RecitationPracticeCubit(
    this._getPageTargets,
    this._compareRecitation,
    this._requestMicrophonePermission,
    this._speechRecognition,
  ) : super(const RecitationPracticeState());

  final GetPageRecitationTargetsUseCase _getPageTargets;
  final CompareRecitationUseCase _compareRecitation;
  final RequestMicrophonePermissionUseCase _requestMicrophonePermission;
  final SpeechRecognitionRepository _speechRecognition;

  StreamSubscription<String>? _transcriptSubscription;

  Future<void> openForPage(int pageNumber) async {
    _openWithTargets(_getPageTargets(pageNumber));
  }

  Future<void> openForAyah({
    required int pageNumber,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final List<RecitationTarget> targets = _getPageTargets(pageNumber);
    if (targets.isEmpty) {
      return;
    }

    final int selectedIndex = targets.indexWhere(
      (RecitationTarget target) =>
          target.surahNumber == surahNumber && target.ayahNumber == ayahNumber,
    );

    _openWithTargets(
      targets,
      selectedTargetIndex: selectedIndex >= 0 ? selectedIndex : 0,
    );
  }

  void _openWithTargets(
    List<RecitationTarget> targets, {
    int selectedTargetIndex = 0,
  }) {
    if (targets.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        isPanelOpen: true,
        targets: targets,
        selectedTargetIndex: selectedTargetIndex.clamp(0, targets.length - 1),
        phase: RecitationPracticePhase.idle,
        liveTranscript: '',
        clearComparisonResult: true,
        clearFailure: true,
      ),
    );
  }

  void closePanel() {
    unawaited(_stopListeningInternal());
    emit(
      const RecitationPracticeState(),
    );
  }

  void selectTarget(int index) {
    if (index < 0 || index >= state.targets.length) {
      return;
    }
    emit(
      state.copyWith(
        selectedTargetIndex: index,
        phase: RecitationPracticePhase.idle,
        liveTranscript: '',
        clearComparisonResult: true,
        clearFailure: true,
      ),
    );
  }

  void selectNextTarget() {
    if (state.targets.isEmpty) {
      return;
    }
    final int nextIndex =
        (state.selectedTargetIndex + 1) % state.targets.length;
    selectTarget(nextIndex);
  }

  Future<void> startListening() async {
    final target = state.selectedTarget;
    if (target == null || state.phase == RecitationPracticePhase.listening) {
      return;
    }

    emit(
      state.copyWith(
        isInitializing: true,
        clearFailure: true,
        clearComparisonResult: true,
        liveTranscript: '',
      ),
    );

    final permissionResult = await _requestMicrophonePermission();
    final bool permissionGranted = permissionResult.fold(
      (Failure failure) {
        emit(
          state.copyWith(
            isInitializing: false,
            failure: failure,
          ),
        );
        return false;
      },
      (bool granted) => granted,
    );
    if (!permissionGranted) {
      if (state.failure == null) {
        emit(
          state.copyWith(
            isInitializing: false,
            failure: Failure.permissionDenied(
              'Microphone permission is required.',
            ),
          ),
        );
      }
      return;
    }

    final initResult = await _speechRecognition.initialize();
    final bool initialized = initResult.fold(
      (Failure failure) {
        emit(
          state.copyWith(
            isInitializing: false,
            failure: failure,
          ),
        );
        return false;
      },
      (_) => true,
    );
    if (!initialized) {
      return;
    }

    await _transcriptSubscription?.cancel();
    _transcriptSubscription = _speechRecognition.watchTranscript().listen(
      (String transcript) {
        _emitLiveTranscript(transcript);
      },
    );

    final startResult = await _speechRecognition.startListening();
    startResult.fold(
      (Failure failure) => emit(
        state.copyWith(
          isInitializing: false,
          failure: failure,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isInitializing: false,
          phase: RecitationPracticePhase.listening,
        ),
      ),
    );
  }

  Future<void> stopListening() async {
    final target = state.selectedTarget;
    if (target == null) {
      return;
    }

    final stopResult = await _speechRecognition.stopListening();
    await _transcriptSubscription?.cancel();
    _transcriptSubscription = null;

    stopResult.fold(
      (Failure failure) => emit(
        state.copyWith(
          phase: RecitationPracticePhase.idle,
          failure: failure,
        ),
      ),
      (String transcript) {
        if (transcript.trim().isEmpty) {
          emit(
            state.copyWith(
              phase: RecitationPracticePhase.idle,
              failure: Failure.validationError(
                'No speech was detected.',
              ),
            ),
          );
          return;
        }

        final RecitationComparisonResult comparison = _compareRecitation(
          targetText: target.normalText,
          spokenText: transcript,
        );
        emit(
          state.copyWith(
            phase: RecitationPracticePhase.feedback,
            liveTranscript: transcript,
            comparisonResult: comparison,
            clearFailure: true,
          ),
        );
      },
    );
  }

  Future<void> retry() async {
    emit(
      state.copyWith(
        phase: RecitationPracticePhase.idle,
        liveTranscript: '',
        clearComparisonResult: true,
        clearFailure: true,
      ),
    );
  }

  void _emitLiveTranscript(String transcript) {
    final RecitationTarget? target = state.selectedTarget;
    if (target == null) {
      return;
    }

    final RecitationComparisonResult? liveComparison =
        transcript.trim().isEmpty
        ? null
        : _compareRecitation(
            targetText: target.normalText,
            spokenText: transcript,
          );

    emit(
      state.copyWith(
        liveTranscript: transcript,
        comparisonResult: liveComparison,
        clearComparisonResult: liveComparison == null,
      ),
    );
  }

  Future<void> _stopListeningInternal() async {
    await _transcriptSubscription?.cancel();
    _transcriptSubscription = null;
    await _speechRecognition.stopListening();
  }

  @override
  Future<void> close() async {
    await _stopListeningInternal();
    await _speechRecognition.dispose();
    return super.close();
  }
}
