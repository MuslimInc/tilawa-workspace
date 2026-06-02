import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciter_list_moshaf_label.dart';

/// Persists whether the reciters A–Z letter index rail is visible.
class RecitersLetterIndexPreference {
  RecitersLetterIndexPreference(this._prefs);

  static const String showKey = 'reciters_show_letter_index';
  static const String userSetKey = 'reciters_letter_index_user_set';

  final SharedPreferencesAsync _prefs;

  /// Saved visibility after the user toggles the alphabet pill.
  ///
  /// Returns `null` when the user has never toggled (width default applies).
  Future<bool?> loadSavedVisibility() async {
    final userSet = await _prefs.getBool(userSetKey) ?? false;
    if (!userSet) {
      return null;
    }
    return await _prefs.getBool(showKey) ?? false;
  }

  Future<void> saveVisibility(bool show) async {
    await _prefs.setBool(showKey, show);
    await _prefs.setBool(userSetKey, true);
  }
}

/// Default letter-index visibility for first launch before any user toggle.
bool letterIndexDefaultVisibleForWidth(double width) {
  return width >= kRecitersAlphabetDefaultVisibleBreakpoint;
}
