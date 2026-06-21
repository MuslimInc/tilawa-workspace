import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'tilawa_interaction_feedback.dart';

/// Identifies a single invalid field after a submit attempt.
@immutable
class TilawaFormFieldIssue {
  /// Creates a field validation issue.
  const TilawaFormFieldIssue({
    required this.fieldId,
    required this.errorMessage,
  });

  /// Stable id matching [TilawaFormFieldAnchor.fieldId].
  final String fieldId;

  /// User-visible error copy for the field or section.
  final String errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TilawaFormFieldIssue &&
          fieldId == other.fieldId &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(fieldId, errorMessage);
}

/// Ordered validation output produced by domain/presentation logic.
@immutable
class TilawaFormValidationResult {
  /// Creates a validation result.
  const TilawaFormValidationResult({required this.issues});

  /// Invalid fields in visual top-to-bottom order.
  final List<TilawaFormFieldIssue> issues;

  /// Whether the form passed validation.
  bool get isValid => issues.isEmpty;

  /// Number of invalid fields.
  int get invalidCount => issues.length;
}

/// Registration metadata for a scroll/focus target in a long form.
@immutable
class TilawaFormFieldRegistration {
  /// Creates a field registration entry.
  const TilawaFormFieldRegistration({
    required this.id,
    required this.semanticLabel,
    required this.order,
    required this.anchorKey,
    this.focusNode,
  });

  /// Stable field id.
  final String id;

  /// Accessible name announced for this field (localized by the host screen).
  final String semanticLabel;

  /// Visual order from top to bottom (lower = higher on screen).
  final int order;

  /// Key on the anchor widget used for [Scrollable.ensureVisible].
  final GlobalKey anchorKey;

  /// When set, receives focus after a failed submit if this is the first issue.
  final FocusNode? focusNode;
}

/// Localized copy helpers for long-form submit failures.
abstract final class TilawaFormValidationMessages {
  /// Footer summary above the primary CTA (Arabic product copy).
  static String validationSummary(int invalidCount) {
    if (invalidCount <= 0) {
      return '';
    }
    if (invalidCount == 1) {
      return 'يرجى تصحيح حقل واحد مطلوب';
    }
    if (invalidCount == 2) {
      return 'يرجى تصحيح حقلين مطلوبين';
    }
    if (invalidCount >= 3 && invalidCount <= 10) {
      return 'يرجى تصحيح $invalidCount حقول مطلوبة';
    }
    return 'يرجى تصحيح $invalidCount حقلًا مطلوبًا';
  }

  /// Screen-reader announcement after a failed submit attempt.
  static String accessibilityAnnouncement({
    required int invalidCount,
    required String firstFieldLabel,
  }) {
    if (invalidCount <= 0) {
      return '';
    }
    if (invalidCount == 1) {
      return 'حقل واحد يحتاج تصحيح: $firstFieldLabel';
    }
    if (invalidCount == 2) {
      return 'حقلان يحتاجان تصحيح. أول حقل: $firstFieldLabel';
    }
    return '$invalidCount حقول تحتاج تصحيح. أول حقل: $firstFieldLabel';
  }
}

/// Scroll, focus, haptic, and accessibility orchestration for long forms.
///
/// Pair with [TilawaFormScreenScaffold] and [TilawaFormFieldAnchor] widgets.
/// Domain layers produce a [TilawaFormValidationResult]; this controller handles
/// presentation-only feedback.
class TilawaFormValidationController {
  /// Creates a controller, optionally reusing an existing [ScrollController].
  TilawaFormValidationController({ScrollController? scrollController})
    : _ownsScrollController = scrollController == null,
      scrollController = scrollController ?? ScrollController();

  /// Whether this controller owns [scrollController] and must dispose it.
  final bool _ownsScrollController;

  /// Scroll view driving the form body.
  final ScrollController scrollController;

  final Map<String, TilawaFormFieldRegistration> _fields =
      <String, TilawaFormFieldRegistration>{};

  /// Registers or replaces a field anchor.
  void registerField(TilawaFormFieldRegistration registration) {
    _fields[registration.id] = registration;
  }

  /// Removes a field anchor.
  void unregisterField(String fieldId) {
    _fields.remove(fieldId);
  }

  /// Returns issues sorted by registered [TilawaFormFieldRegistration.order].
  List<TilawaFormFieldIssue> sortIssuesByFieldOrder(
    List<TilawaFormFieldIssue> issues,
  ) {
    final List<TilawaFormFieldIssue> sorted = List<TilawaFormFieldIssue>.of(
      issues,
    );
    sorted.sort((TilawaFormFieldIssue a, TilawaFormFieldIssue b) {
      final int orderA = _fields[a.fieldId]?.order ?? 1 << 20;
      final int orderB = _fields[b.fieldId]?.order ?? 1 << 20;
      return orderA.compareTo(orderB);
    });
    return sorted;
  }

  /// First invalid field after ordering, or null when [result] is valid.
  TilawaFormFieldIssue? firstIssue(TilawaFormValidationResult result) {
    if (result.isValid) {
      return null;
    }
    return sortIssuesByFieldOrder(result.issues).first;
  }

  /// First registered field matching [result], for scroll/focus/a11y.
  TilawaFormFieldRegistration? firstRegistration(
    TilawaFormValidationResult result,
  ) {
    final TilawaFormFieldIssue? issue = firstIssue(result);
    if (issue == null) {
      return null;
    }
    return _fields[issue.fieldId];
  }

  /// Reveals validation failures: haptic, scroll, focus, and announcement.
  Future<void> handleValidationFailure(
    BuildContext hostContext,
    TilawaFormValidationResult result, {
    TextDirection? textDirection,
    Duration scrollDuration = const Duration(milliseconds: 300),
    Curve scrollCurve = Curves.easeInOut,
    double scrollAlignment = 0.1,
  }) async {
    if (result.isValid) {
      return;
    }

    TilawaInteractionFeedback.trigger(TilawaHaptic.lightImpact);

    final TilawaFormFieldRegistration? registration = firstRegistration(
      result,
    );
    final TilawaFormFieldIssue? issue = firstIssue(result);
    final BuildContext? anchorContext = registration?.anchorKey.currentContext;
    if (anchorContext != null && anchorContext.mounted) {
      await Scrollable.ensureVisible(
        anchorContext,
        alignment: scrollAlignment,
        duration: scrollDuration,
        curve: scrollCurve,
      );
      registration?.focusNode?.requestFocus();
    }

    if (issue != null && hostContext.mounted) {
      SemanticsService.sendAnnouncement(
        View.of(hostContext),
        TilawaFormValidationMessages.accessibilityAnnouncement(
          invalidCount: result.invalidCount,
          firstFieldLabel: registration?.semanticLabel ?? issue.errorMessage,
        ),
        textDirection ?? Directionality.of(hostContext),
      );
    }
  }

  /// Disposes owned resources.
  void dispose() {
    if (_ownsScrollController) {
      scrollController.dispose();
    }
    _fields.clear();
  }
}

/// Provides a [TilawaFormValidationController] to [TilawaFormFieldAnchor].
class TilawaFormValidationScope extends InheritedWidget {
  /// Creates a validation scope.
  const TilawaFormValidationScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// Shared controller for the form screen.
  final TilawaFormValidationController controller;

  /// Returns the scope controller.
  static TilawaFormValidationController of(BuildContext context) {
    final TilawaFormValidationScope? scope = context
        .dependOnInheritedWidgetOfExactType<TilawaFormValidationScope>();
    assert(
      scope != null,
      'TilawaFormValidationScope not found. Wrap the form in '
      'TilawaFormScreenScaffold(validationController: ...).',
    );
    return scope!.controller;
  }

  /// Returns the scope controller when present.
  static TilawaFormValidationController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TilawaFormValidationScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(TilawaFormValidationScope oldWidget) =>
      controller != oldWidget.controller;
}
