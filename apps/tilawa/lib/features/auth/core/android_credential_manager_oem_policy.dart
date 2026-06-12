/// OEM heuristics for Android Credential Manager Google sign-in.
///
/// Transsion ROMs (Infinix, Tecno, Itel) launch [HiddenActivity] for the
/// account picker but the bottom sheet stays invisible when Flutter's surface
/// is stacked above it — the platform future may never complete. google_sign_in
/// 7.x routes through Credential Manager / Play Services [HiddenActivity], so
/// silent and automatic sign-in flows must be skipped on these devices.
abstract final class AndroidCredentialManagerOemPolicy {
  static const Set<String> _transsionOems = <String>{
    'infinix',
    'tecno',
    'itel',
  };

  /// Whether this OEM needs sign-in workarounds (no silent auth, no auto
  /// sign-in; interactive sign-in only, triggered by an explicit user tap).
  static bool shouldSkipAutomaticSignIn({
    required String manufacturer,
    required String brand,
  }) {
    final String manufacturerLower = manufacturer.toLowerCase();
    final String brandLower = brand.toLowerCase();
    return _transsionOems.contains(manufacturerLower) ||
        _transsionOems.contains(brandLower);
  }
}
