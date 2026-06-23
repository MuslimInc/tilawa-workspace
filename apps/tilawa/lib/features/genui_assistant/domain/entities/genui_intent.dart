import 'package:equatable/equatable.dart';

/// The closed set of actions an AI-authored UI is permitted to trigger.
///
/// This is the *allowlist*. The model emits an action id string plus primitive
/// args; the resolver maps it to exactly one of these typed intents or rejects
/// it. There is no path from model output to an arbitrary route, URL, or
/// callback — the dispatcher can only act on a value of this type.
sealed class GenUiIntent extends Equatable {
  const GenUiIntent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Open the Quran reader at a validated [surah] (1–114) and optional [ayah].
final class OpenQuranReaderIntent extends GenUiIntent {
  const OpenQuranReaderIntent({required this.surah, this.ayah});

  final int surah;
  final int? ayah;

  @override
  List<Object?> get props => <Object?>[surah, ayah];
}

/// Start today's wird, optionally for a specific plan.
final class StartTodayWirdIntent extends GenUiIntent {
  const StartTodayWirdIntent({this.planId});

  final String? planId;

  @override
  List<Object?> get props => <Object?>[planId];
}

/// Open the athkar feature at a known [category].
final class OpenAthkarIntent extends GenUiIntent {
  const OpenAthkarIntent({required this.category});

  final String category;

  @override
  List<Object?> get props => <Object?>[category];
}

/// Schedule a reminder of a known [kind] at an optional time-of-day.
final class SetReminderIntent extends GenUiIntent {
  const SetReminderIntent({required this.kind, this.hour, this.minute});

  final String kind;
  final int? hour;
  final int? minute;

  @override
  List<Object?> get props => <Object?>[kind, hour, minute];
}

/// Persist a previously-prepared plan draft.
final class SavePlanIntent extends GenUiIntent {
  const SavePlanIntent({required this.planDraftId});

  final String planDraftId;

  @override
  List<Object?> get props => <Object?>[planDraftId];
}
