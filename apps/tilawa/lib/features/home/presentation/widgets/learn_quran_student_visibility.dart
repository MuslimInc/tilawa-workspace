import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';

/// Role gates for the home Learn Quran student card.
abstract final class LearnQuranStudentVisibility {
  static bool shouldShowHomeCard({
    required bool capabilityLoaded,
    required TeacherCapability? capability,
  }) {
    if (!quranSessionsFeatureConfig().showLearnQuranStudentExperience) {
      return false;
    }
    if (!capabilityLoaded) {
      return false;
    }
    if (capability?.hasTeacherMarketplaceRole ?? false) {
      return false;
    }
    return true;
  }
}
