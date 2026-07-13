# Contract: Quran Validation Result

**Status**: Active
**Version**: 1.0.0
**Privacy Classification**: Internal / Diagnostic

## Purpose
Defines the output structure of the `QuranValidationService` executed during post-update or first-launch integrity checks. It communicates the health of the Quran database to the UI and Analytics.

## Schema (Dart Class Equivalent)
```dart
class QuranValidationResult {
  final bool isValid;
  final String versionChecked;
  final ValidationFailureReason? failureReason;
  final Duration validationDuration;
  final DateTime checkedAt;
}

enum ValidationFailureReason {
  manifestMissing,
  hashMismatch,
  structuralGap,
  ioError
}
```

## Fields
- `isValid` (Boolean, Required): True if the integrity check passed.
- `versionChecked` (String, Required): The manifest version that was validated (e.g., `1.0.0-qcf4`).
- `failureReason` (Enum, Optional): Present if `isValid` is false.
- `validationDuration` (Duration, Required): Must be benchmarked. Used to ensure the integrity check does not regress cold startup times.

## Interaction with Other Contracts
This result object is derived by comparing the bundled assets against the `contracts/quran-integrity-manifest.md`. 
If `isValid == false`, the app MUST log the failure to Crashlytics and safely degrade the Mushaf view.
