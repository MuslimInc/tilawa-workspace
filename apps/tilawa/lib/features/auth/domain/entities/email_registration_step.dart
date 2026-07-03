/// Steps in the multi-step email registration wizard.
enum EmailRegistrationStep {
  account,
  personal,
  quranLearning,
  guardian,
  review,
}

extension EmailRegistrationStepX on EmailRegistrationStep {
  int get index => EmailRegistrationStep.values.indexOf(this);

  /// Total visible steps for the current draft (guardian skipped for adults).
  static int visibleStepCount({required bool includesGuardian}) =>
      includesGuardian ? 5 : 4;

  /// 1-based display index for the progress indicator.
  int displayIndex({required bool includesGuardian}) {
    if (!includesGuardian && index >= EmailRegistrationStep.guardian.index) {
      return index;
    }
    return index + 1;
  }

  EmailRegistrationStep? next({required bool includesGuardian}) {
    final int nextIndex = index + 1;
    if (nextIndex >= EmailRegistrationStep.values.length) {
      return null;
    }
    final EmailRegistrationStep candidate =
        EmailRegistrationStep.values[nextIndex];
    if (!includesGuardian && candidate == EmailRegistrationStep.guardian) {
      return EmailRegistrationStep.review;
    }
    return candidate;
  }

  EmailRegistrationStep? previous({required bool includesGuardian}) {
    final int prevIndex = index - 1;
    if (prevIndex < 0) {
      return null;
    }
    final EmailRegistrationStep candidate =
        EmailRegistrationStep.values[prevIndex];
    if (!includesGuardian && candidate == EmailRegistrationStep.guardian) {
      return EmailRegistrationStep.quranLearning;
    }
    return candidate;
  }
}
