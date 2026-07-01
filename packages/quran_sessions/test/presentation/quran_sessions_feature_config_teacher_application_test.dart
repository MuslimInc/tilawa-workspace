import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

void main() {
  group('QuranSessionsFeatureConfig teacher application flags', () {
    test('Google Form entry is independent of student marketplace', () {
      const config = QuranSessionsFeatureConfig(
        quranSessionsEnabled: true,
        learnQuranStudentFeatureEnabled: false,
        teacherApplicationEntryEnabled: true,
      );
      check(config.showLearnQuranStudentExperience).isFalse();
      check(config.showTeacherApplicationEntry).isTrue();
      check(config.showInAppTeacherApplicationEntry).isFalse();
      check(config.showProfileTeacherEntry).isTrue();
    });

    test('home card requires both entry and card flags', () {
      const entryOnly = QuranSessionsFeatureConfig(
        teacherApplicationEntryEnabled: true,
      );
      check(entryOnly.showHomeTeacherApplicationCard).isFalse();

      const cardEnabled = QuranSessionsFeatureConfig(
        teacherApplicationEntryEnabled: true,
        homeTeacherApplicationCardEnabled: true,
      );
      check(cardEnabled.showHomeTeacherApplicationCard).isTrue();
    });

    test('in-app apply requires student feature enabled', () {
      const config = QuranSessionsFeatureConfig(
        learnQuranStudentFeatureEnabled: false,
        teacherApplicationEnabled: true,
        teacherApplicationDiscoverability:
            TeacherApplicationDiscoverability.profileOnly,
      );
      check(config.showInAppTeacherApplicationEntry).isFalse();

      const enabled = QuranSessionsFeatureConfig(
        learnQuranStudentFeatureEnabled: true,
        teacherApplicationEnabled: true,
        teacherApplicationDiscoverability:
            TeacherApplicationDiscoverability.profileOnly,
      );
      check(enabled.showInAppTeacherApplicationEntry).isTrue();
    });
  });
}
