import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

/// In-memory fake for [TeacherApplicationRepository].
///
/// Re-application cooldown policy (MVP): 30 days after rejection.
/// Max re-application attempts: unlimited in MVP (document this as a deferred
/// product decision in ADR-003).
class FakeMvpTeacherApplicationRepository
    implements TeacherApplicationRepository {
  FakeMvpTeacherApplicationRepository(this._store);

  final QuranSessionsMvpStore _store;

  static const _cooldownDays = 30;

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> getApplication(
    String userId,
  ) async {
    final app = _store.teacherApplications[userId];
    if (app == null) return const Left(TeacherApplicationNotFoundFailure());
    return Right(app);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> createDraft(
    String userId,
  ) async {
    final existing = _store.teacherApplications[userId];
    if (existing != null && (existing.isPending || existing.isApproved)) {
      return const Left(TeacherApplicationAlreadyPendingFailure());
    }

    if (existing != null && existing.isRejected) {
      final rejectedAt = existing.reviewedAt;
      if (rejectedAt != null) {
        final cooldownEnd = rejectedAt.add(
          const Duration(days: _cooldownDays),
        );
        if (DateTime.now().isBefore(cooldownEnd)) {
          return Left(ReapplicationTooSoonFailure(cooldownEndsAt: cooldownEnd));
        }
      }
    }

    final now = DateTime.now();
    final draft = TeacherApplication(
      id: 'app_${userId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      status: TeacherApplicationStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
    _store.teacherApplications[userId] = draft;
    return Right(draft);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> saveDraft(
    TeacherApplication draft,
  ) async {
    final updated = draft.copyWith(updatedAt: DateTime.now());
    _store.teacherApplications[draft.userId] = updated;
    return Right(updated);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> submit(
    TeacherApplication application,
  ) async {
    final now = DateTime.now();
    final submitted = application.copyWith(
      status: TeacherApplicationStatus.pending,
      submittedAt: now,
      updatedAt: now,
    );
    _store.teacherApplications[application.userId] = submitted;
    return Right(submitted);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> approve({
    required String applicationId,
    required String reviewedBy,
  }) async {
    final entry = _store.teacherApplications.entries
        .cast<MapEntry<String, TeacherApplication>?>()
        .firstWhere(
          (e) => e?.value.id == applicationId,
          orElse: () => null,
        );
    if (entry == null) return const Left(TeacherApplicationNotFoundFailure());
    final now = DateTime.now();
    final approved = entry.value.copyWith(
      status: TeacherApplicationStatus.approved,
      reviewedAt: now,
      reviewedBy: reviewedBy,
      updatedAt: now,
    );
    _store.teacherApplications[entry.key] = approved;
    return Right(approved);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> reject({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    final entry = _findById(applicationId);
    if (entry == null) return const Left(TeacherApplicationNotFoundFailure());
    final now = DateTime.now();
    final rejected = entry.value.copyWith(
      status: TeacherApplicationStatus.rejected,
      reviewedAt: now,
      reviewedBy: reviewedBy,
      rejectionReason: reason,
      updatedAt: now,
    );
    _store.teacherApplications[entry.key] = rejected;
    return Right(rejected);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> suspend({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    final entry = _findById(applicationId);
    if (entry == null) return const Left(TeacherApplicationNotFoundFailure());
    final now = DateTime.now();
    final suspended = entry.value.copyWith(
      status: TeacherApplicationStatus.suspended,
      reviewedAt: now,
      reviewedBy: reviewedBy,
      rejectionReason: reason,
      updatedAt: now,
    );
    _store.teacherApplications[entry.key] = suspended;
    return Right(suspended);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> revoke({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    final entry = _findById(applicationId);
    if (entry == null) return const Left(TeacherApplicationNotFoundFailure());
    final now = DateTime.now();
    final revoked = entry.value.copyWith(
      status: TeacherApplicationStatus.revoked,
      reviewedAt: now,
      reviewedBy: reviewedBy,
      rejectionReason: reason,
      updatedAt: now,
    );
    _store.teacherApplications[entry.key] = revoked;
    return Right(revoked);
  }

  MapEntry<String, TeacherApplication>? _findById(String applicationId) =>
      _store.teacherApplications.entries
          .cast<MapEntry<String, TeacherApplication>?>()
          .firstWhere(
            (e) => e?.value.id == applicationId,
            orElse: () => null,
          );
}
