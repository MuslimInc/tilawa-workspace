import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/tour_guide/domain/entities/tour_content_align.dart';
import 'package:tilawa/features/tour_guide/domain/entities/tour_definition.dart';
import 'package:tilawa/features/tour_guide/domain/entities/tour_step.dart';
import 'package:tilawa/features/tour_guide/presentation/services/tour_guide_service.dart';

import 'reciters_tour_targets.dart';

/// Builds localized Reciters tours and triggers [TourGuideService].
@injectable
class RecitersTourLauncher {
  RecitersTourLauncher(this._tourGuide);

  final TourGuideService _tourGuide;

  /// Highlights search, favourites, and opening a reciter on the list tab.
  Future<bool> maybeShowRecitersIntro(BuildContext context) {
    final l10n = context.l10n;
    return _tourGuide.tryShowTour(
      context: context,
      tourId: RecitersTourIds.intro,
      definition: TourDefinition(
        id: RecitersTourIds.intro,
        version: 2,
        steps: <TourStep>[
          TourStep(
            id: 'search',
            targetId: RecitersTourTargets.searchField,
            title: l10n.tourRecitersSearchTitle,
            description: l10n.tourRecitersSearchDescription,
            contentAlign: TourContentAlign.bottom,
          ),
          TourStep(
            id: 'open_reciter',
            targetId: RecitersTourTargets.firstReciterCard,
            title: l10n.tourRecitersOpenReciterTitle,
            description: l10n.tourRecitersOpenReciterDescription,
            contentAlign: TourContentAlign.top,
            enableTargetTap: true,
          ),
        ],
      ),
    );
  }

  /// Highlights the active surah row and mini player after playback starts.
  Future<bool> maybeShowPlaybackTour(BuildContext context) {
    final l10n = context.l10n;
    return _tourGuide.tryShowTour(
      context: context,
      tourId: RecitersTourIds.playback,
      definition: TourDefinition(
        id: RecitersTourIds.playback,
        version: 1,
        steps: <TourStep>[
          TourStep(
            id: 'playing_surah',
            targetId: RecitersTourTargets.playingSurah,
            title: l10n.tourReciterPlaybackPlayingTitle,
            description: l10n.tourReciterPlaybackPlayingDescription,
            contentAlign: TourContentAlign.top,
          ),
          TourStep(
            id: 'mini_player',
            targetId: RecitersTourTargets.miniPlayer,
            title: l10n.tourReciterPlaybackMiniPlayerTitle,
            description: l10n.tourReciterPlaybackMiniPlayerDescription,
            contentAlign: TourContentAlign.top,
          ),
        ],
      ),
    );
  }
}
