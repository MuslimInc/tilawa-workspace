import 'package:flutter/foundation.dart';

import 'in_app_update_presentation_event.dart';

/// Outcome of [CheckForInAppUpdateUseCase] for the presentation layer.
@immutable
class InAppUpdateCheckResult {
  const InAppUpdateCheckResult({
    this.presentationEvent = InAppUpdatePresentationEvent.none,
  });

  final InAppUpdatePresentationEvent presentationEvent;

  bool get hasPresentationEvent =>
      presentationEvent != InAppUpdatePresentationEvent.none;
}
