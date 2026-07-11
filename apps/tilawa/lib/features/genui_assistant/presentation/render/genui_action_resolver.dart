import 'package:equatable/equatable.dart';

import '../../domain/entities/genui_intent.dart';
import '../../domain/entities/genui_node.dart';

/// Outcome of resolving a node's action against the allowlist.
sealed class GenUiActionResolution extends Equatable {
  const GenUiActionResolution();

  @override
  List<Object?> get props => const <Object?>[];
}

/// The action id was allowlisted and its args validated into a typed intent.
final class GenUiActionAccepted extends GenUiActionResolution {
  const GenUiActionAccepted(this.intent);

  final GenUiIntent intent;

  @override
  List<Object?> get props => <Object?>[intent];
}

/// The action id was unknown, or its args were invalid/out of bounds. The
/// dispatcher must treat this as a no-op (plus telemetry) — never an execution.
final class GenUiActionRejected extends GenUiActionResolution {
  const GenUiActionRejected({required this.actionId, required this.reason});

  final String actionId;
  final String reason;

  @override
  List<Object?> get props => <Object?>[actionId, reason];
}

/// Maps an AI-supplied action id + primitive args to a typed [GenUiIntent].
///
/// This is the *action allowlist*. The set [allowedActionIds] is closed; any id
/// outside it is rejected before any intent exists. Even for allowlisted ids,
/// args are validated (e.g. surah must be 1–114) so a hostile or buggy payload
/// cannot drive navigation to a nonsensical target. There is no reflection and
/// no dynamic route string — the only reachable behaviours are the five typed
/// intents.
class GenUiActionResolver {
  const GenUiActionResolver();

  static const Set<String> allowedActionIds = <String>{
    'openQuranReader',
    'startTodayWird',
    'openAthkar',
    'setReminder',
    'savePlan',
  };

  static const Set<String> _athkarCategories = <String>{
    'morning',
    'evening',
    'sleep',
    'afterPrayer',
    'general',
  };

  static const Set<String> _reminderKinds = <String>{
    'wird',
    'athkar',
    'prayer',
  };

  GenUiActionResolution resolve(GenUiNode node) {
    final String? actionId = node.actionId;
    if (actionId == null || !allowedActionIds.contains(actionId)) {
      return GenUiActionRejected(
        actionId: actionId ?? '<null>',
        reason: 'unknown action',
      );
    }

    return switch (actionId) {
      'openQuranReader' => _openQuranReader(node),
      'startTodayWird' => GenUiActionAccepted(
        StartTodayWirdIntent(planId: node.stringProp('planId')),
      ),
      'openAthkar' => _openAthkar(node),
      'setReminder' => _setReminder(node),
      'savePlan' => _savePlan(node),
      // Unreachable: allowedActionIds is the switch's domain.
      _ => GenUiActionRejected(actionId: actionId, reason: 'unhandled action'),
    };
  }

  GenUiActionResolution _openQuranReader(GenUiNode node) {
    final int? surah = node.intProp('surah');
    if (surah == null || surah < 1 || surah > 114) {
      return const GenUiActionRejected(
        actionId: 'openQuranReader',
        reason: 'surah out of range',
      );
    }
    final int? ayah = node.intProp('ayah');
    if (ayah != null && ayah < 1) {
      return const GenUiActionRejected(
        actionId: 'openQuranReader',
        reason: 'ayah out of range',
      );
    }
    return GenUiActionAccepted(OpenQuranReaderIntent(surah: surah, ayah: ayah));
  }

  GenUiActionResolution _openAthkar(GenUiNode node) {
    final String? category = node.stringProp('category');
    if (category == null || !_athkarCategories.contains(category)) {
      return const GenUiActionRejected(
        actionId: 'openAthkar',
        reason: 'unknown athkar category',
      );
    }
    return GenUiActionAccepted(OpenAthkarIntent(category: category));
  }

  GenUiActionResolution _setReminder(GenUiNode node) {
    final String? kind = node.stringProp('kind');
    if (kind == null || !_reminderKinds.contains(kind)) {
      return const GenUiActionRejected(
        actionId: 'setReminder',
        reason: 'unknown reminder kind',
      );
    }
    final int? hour = node.intProp('hour');
    final int? minute = node.intProp('minute');
    if (hour != null && (hour < 0 || hour > 23)) {
      return const GenUiActionRejected(
        actionId: 'setReminder',
        reason: 'hour out of range',
      );
    }
    if (minute != null && (minute < 0 || minute > 59)) {
      return const GenUiActionRejected(
        actionId: 'setReminder',
        reason: 'minute out of range',
      );
    }
    return GenUiActionAccepted(
      SetReminderIntent(kind: kind, hour: hour, minute: minute),
    );
  }

  GenUiActionResolution _savePlan(GenUiNode node) {
    final String? draftId = node.stringProp('planDraftId');
    if (draftId == null || draftId.isEmpty) {
      return const GenUiActionRejected(
        actionId: 'savePlan',
        reason: 'missing planDraftId',
      );
    }
    return GenUiActionAccepted(SavePlanIntent(planDraftId: draftId));
  }
}
