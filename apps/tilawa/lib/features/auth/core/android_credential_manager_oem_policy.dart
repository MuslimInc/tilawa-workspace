/// OEM heuristics for Android Credential Manager Google sign-in.
///
/// Transsion ROMs (Infinix, Tecno, Itel) can composite GMS sign-in UI
/// invisibly behind Flutter's surface — the platform future may never
/// complete. RenderMode.texture (MainActivity) fixes the compositing, but
/// these devices still get a conservative policy: no auto sign-in on screen
/// entry, and interactive flows fail fast when no GMS UI becomes visible
/// (GoogleAuthProviderImpl UI visibility probe).
abstract final class AndroidCredentialManagerOemPolicy {
  static const Set<String> _transsionOems = <String>{
    'infinix',
    'tecno',
    'itel',
  };

  /// Whether this OEM needs sign-in workarounds (no auto sign-in on screen
  /// entry; interactive flows guarded by the UI visibility probe).
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
