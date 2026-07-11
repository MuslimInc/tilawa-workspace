// ignore_for_file: avoid_public_fields, prefer_void_public_methods_on_cubit
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';

import '../config/home_learning_config.dart';
import '../services/home_learning_preference_store.dart';
import 'home_learning_state.dart';

@injectable
class HomeLearningCubit extends Cubit<HomeLearningState> {
  HomeLearningCubit({
    required this._getStudentSessions,
    required this._getSessionAggregate,
    required this._preferenceStore,
  }) : super(const HomeLearningState.initial());

  final GetStudentSessionsUseCase _getStudentSessions;
  final GetSessionAggregateUseCase _getSessionAggregate;
  final HomeLearningPreferenceStore _preferenceStore;

  /// The clock provider, can be overridden in tests.
  DateTime Function() clock = DateTime.now;

  bool _isLoading = false;
  String? _loadedUserId;

  /// Loads the student's learning state and determines the active card status.
  ///
  /// Safe and idempotent: returns early if already loading or if state has already
  /// loaded for the current user (unless [force] is true).
  Future<void> load({bool force = false}) async {
    final config = quranSessionsFeatureConfig();
    if (!config.quranSessionsEnabled) {
      emit(const HomeLearningState(status: HomeLearningStatus.none));
      return;
    }

    final userId = resolveQuranSessionsUserId(
      getIt,
    ); // Resolves current student ID
    if (userId == null || userId.isEmpty) {
      emit(const HomeLearningState(status: HomeLearningStatus.none));
      return;
    }

    if (_isLoading) return;
    if (!force &&
        _loadedUserId == userId &&
        state.status != HomeLearningStatus.initial) {
      return;
    }

    _isLoading = true;
    _loadedUserId = userId;
    emit(const HomeLearningState.loading());

    try {
      final now = clock();

      // 1. Fetch the student's sessions (upcoming and past)
      final result = await _getStudentSessions(userId);

      await result.fold(
        (failure) async {
          // Degrading gracefully to none on loading failures
          emit(const HomeLearningState(status: HomeLearningStatus.none));
        },
        (page) async {
          // 2. Priority 1: Check for ongoing session
          QuranSession? activeSession;
          for (final session in page.upcoming) {
            final status = session.effectiveLifecycleStatus;
            final isActive =
                status == SessionLifecycleStatus.scheduled ||
                status == SessionLifecycleStatus.confirmed ||
                status == SessionLifecycleStatus.inProgress ||
                status == SessionLifecycleStatus.rescheduled;

            if (isActive &&
                !now.isBefore(session.startsAt) &&
                !now.isAfter(session.endsAt)) {
              activeSession = session;
              break;
            }
          }

          if (activeSession != null) {
            emit(
              HomeLearningState(
                status: HomeLearningStatus.nextSession,
                session: activeSession,
              ),
            );
            return;
          }

          // 3. Priority 2: Check for nearest imminent upcoming session within 2 hours
          QuranSession? imminentSession;
          for (final session in page.upcoming) {
            final status = session.effectiveLifecycleStatus;
            final isActive =
                status == SessionLifecycleStatus.scheduled ||
                status == SessionLifecycleStatus.confirmed ||
                status == SessionLifecycleStatus.inProgress ||
                status == SessionLifecycleStatus.rescheduled;

            if (isActive && session.startsAt.isAfter(now)) {
              final diff = session.startsAt.difference(now);
              if (diff <= HomeLearningConfig.imminentSessionThreshold) {
                if (imminentSession == null ||
                    session.startsAt.isBefore(imminentSession.startsAt)) {
                  imminentSession = session;
                }
              }
            }
          }

          if (imminentSession != null) {
            emit(
              HomeLearningState(
                status: HomeLearningStatus.nextSession,
                session: imminentSession,
              ),
            );
            return;
          }

          // 4. Priority 3: Check for pending booking (pending payment or approval)
          QuranSession? pendingSession;
          if (page.pending.isNotEmpty) {
            // Sort by nearest startsAt
            final activePending = page.pending.where((s) {
              final status = s.effectiveLifecycleStatus;
              return status == SessionLifecycleStatus.pendingTutorApproval ||
                  status == SessionLifecycleStatus.pendingPayment;
            }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));

            if (activePending.isNotEmpty) {
              pendingSession = activePending.first;
            }
          }

          if (pendingSession != null) {
            emit(
              HomeLearningState(
                status: HomeLearningStatus.pendingBooking,
                session: pendingSession,
              ),
            );
            return;
          }

          // 5. Priority 4: Check for latest completed session with revision within 7 days
          if (page.past.isNotEmpty) {
            final completedPast =
                page.past.where((s) {
                  return s.effectiveLifecycleStatus ==
                      SessionLifecycleStatus.completed;
                }).toList()..sort(
                  (a, b) => b.startsAt.compareTo(a.startsAt),
                ); // Descending latest first

            final lastPracticedId = await _preferenceStore
                .getLastPracticedSessionId();
            for (final pastSession in completedPast) {
              // Check if age is <= 7 days
              final diff = now.difference(pastSession.startsAt);
              if (diff <= HomeLearningConfig.revisionAgeOutThreshold) {
                // The revision card marks practice with the aggregate id
                // (the booking id); session.id also maps to the booking id
                // today. Check both so the card never reappears if that
                // mapping ever diverges.
                final isPracticed =
                    lastPracticedId == pastSession.id ||
                    lastPracticedId == pastSession.bookingId;
                if (!isPracticed) {
                  // Load aggregate details to verify revision focus
                  final aggregateResult = await _getSessionAggregate(
                    pastSession.bookingId,
                  );
                  final hasValidRevision = aggregateResult.fold(
                    (failure) => false,
                    (aggregate) {
                      if (aggregate.revisionSurahNumber != null &&
                          aggregate.revisionSurahNumber! >= 1) {
                        emit(
                          HomeLearningState(
                            status: HomeLearningStatus.continueLearning,
                            revisionAggregate: aggregate,
                          ),
                        );
                        return true;
                      }
                      return false;
                    },
                  );

                  if (hasValidRevision) return;
                }
              }
            }
          }

          // 6. Priority 5: Fallback to None (check interest signal).
          // Unanswered → interest prompt; answered yes → persistent browse
          // entry so the Learn Quran section never disappears for an
          // interested student; answered no → nothing (dismissed).
          final hasSetInterest = await _preferenceStore
              .getHasSetLearningInterest();
          final isInterested =
              hasSetInterest && await _preferenceStore.getIsInterested();
          emit(
            HomeLearningState(
              status: HomeLearningStatus.none,
              isInterestSignalNeeded: !hasSetInterest,
              isBrowseEntryVisible: isInterested,
            ),
          );
        },
      );
    } catch (_) {
      // Graceful error fallback to avoid breaking Home screen
      emit(const HomeLearningState(status: HomeLearningStatus.none));
    } finally {
      _isLoading = false;
    }
  }

  /// Sets the user's tutoring interest preference and updates state
  /// accordingly. Answering yes swaps the prompt for the persistent browse
  /// entry instead of removing the Learn Quran section from Home.
  Future<void> setTutoringInterest({required bool isInterested}) async {
    await _preferenceStore.setIsInterested(isInterested);
    await _preferenceStore.setHasSetLearningInterest(true);
    emit(
      state.copyWith(
        isInterestSignalNeeded: false,
        isBrowseEntryVisible: isInterested,
      ),
    );
  }

  /// Marks a completed session's revision context as practiced.
  Future<void> markRevisionAsPracticed(String sessionId) async {
    await _preferenceStore.setLastPracticedSessionId(sessionId);
    // Reload state asynchronously to transition back to fallback card
    await load(force: true);
  }
}
