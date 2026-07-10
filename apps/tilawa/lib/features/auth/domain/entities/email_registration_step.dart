/// Steps in the multi-step email registration wizard.
enum EmailRegistrationStep {
  account,
  personal,
  review,
}

extension EmailRegistrationStepX on EmailRegistrationStep {
  int get index => EmailRegistrationStep.values.indexOf(this);

  /// Total visible steps in the registration wizard.
  static int visibleStepCount() => EmailRegistrationStep.values.length;

  /// 1-based display index for the progress indicator.
  int get displayIndex => index + 1;

  EmailRegistrationStep? next() {
    final int nextIndex = index + 1;
    if (nextIndex >= EmailRegistrationStep.values.length) {
      return null;
    }
    return EmailRegistrationStep.values[nextIndex];
  }

  EmailRegistrationStep? previous() {
    final int prevIndex = index - 1;
    if (prevIndex < 0) {
      return null;
    }
    return EmailRegistrationStep.values[prevIndex];
  }
}
