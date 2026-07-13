import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract store for tracking learning interest preference and revision practice status.
abstract interface class HomeLearningPreferenceStore {
  /// Checks if the user has completed the onboarding interest prompt.
  Future<bool> getHasSetLearningInterest();

  /// Sets whether the user has completed the onboarding interest prompt.
  Future<void> setHasSetLearningInterest(bool value);

  /// Checks if the user expressed interest in tutoring.
  Future<bool> getIsInterested();

  /// Sets whether the user is interested in tutoring.
  Future<void> setIsInterested(bool value);

  /// Gets the last session ID where the user tapped "Practice" on the revision card.
  Future<String?> getLastPracticedSessionId();

  /// Sets the last session ID where the user tapped "Practice" on the revision card.
  Future<void> setLastPracticedSessionId(String sessionId);
}

/// SharedPreferencesAsync implementation of [HomeLearningPreferenceStore].
@LazySingleton(as: HomeLearningPreferenceStore)
class SharedPreferencesHomeLearningPreferenceStore
    implements HomeLearningPreferenceStore {
  SharedPreferencesHomeLearningPreferenceStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const String _keyHasSetInterest = 'has_set_learning_interest';
  static const String _keyIsInterested = 'is_learning_interested';
  static const String _keyLastPracticed = 'last_practiced_session_id';

  @override
  Future<bool> getHasSetLearningInterest() async {
    return (await _prefs.getBool(_keyHasSetInterest)) ?? false;
  }

  @override
  Future<void> setHasSetLearningInterest(bool value) async {
    await _prefs.setBool(_keyHasSetInterest, value);
  }

  @override
  Future<bool> getIsInterested() async {
    return (await _prefs.getBool(_keyIsInterested)) ?? false;
  }

  @override
  Future<void> setIsInterested(bool value) async {
    await _prefs.setBool(_keyIsInterested, value);
  }

  @override
  Future<String?> getLastPracticedSessionId() async {
    return _prefs.getString(_keyLastPracticed);
  }

  @override
  Future<void> setLastPracticedSessionId(String sessionId) async {
    await _prefs.setString(_keyLastPracticed, sessionId);
  }
}
