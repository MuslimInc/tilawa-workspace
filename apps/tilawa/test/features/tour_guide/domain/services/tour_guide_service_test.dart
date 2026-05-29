import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilawa/features/tour_guide/domain/entities/tour_completion_record.dart';
import 'package:tilawa/features/tour_guide/domain/entities/tour_content_align.dart';
import 'package:tilawa/features/tour_guide/domain/entities/tour_definition.dart';
import 'package:tilawa/features/tour_guide/domain/entities/tour_step.dart';
import 'package:tilawa/features/tour_guide/presentation/overlay/tour_overlay_presenter.dart';
import 'package:tilawa/features/tour_guide/domain/repositories/tour_repository.dart';
import 'package:tilawa/features/tour_guide/domain/services/tour_catalog.dart';
import 'package:tilawa/features/tour_guide/domain/services/tour_flow_guard.dart';
import 'package:tilawa/features/tour_guide/presentation/services/tour_guide_service.dart';
import 'package:tilawa/features/tour_guide/presentation/services/tour_guide_labels.dart';
import 'package:tilawa/features/tour_guide/domain/services/tour_target_registry.dart';
import 'package:tilawa/features/tour_guide/domain/usecases/complete_tour.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class _FakeTourCatalog implements TourCatalog {
  _FakeTourCatalog(this._definitions);

  final List<TourDefinition> _definitions;

  @override
  TourDefinition? getDefinition(String tourId) {
    for (final TourDefinition definition in _definitions) {
      if (definition.id == tourId) {
        return definition;
      }
    }
    return null;
  }

  @override
  Iterable<TourDefinition> get definitions => _definitions;
}

class _FakeTourRepository implements TourRepository {
  final Map<String, TourCompletionRecord> _records =
      <String, TourCompletionRecord>{};

  @override
  Future<void> markCompleted({
    required String tourId,
    required int version,
  }) async {
    _records[tourId] = TourCompletionRecord(
      completed: true,
      completedVersion: version,
    );
  }

  @override
  Future<TourCompletionRecord> getCompletion(String tourId) async {
    return _records[tourId] ?? const TourCompletionRecord(completed: false);
  }

  @override
  Future<void> resetAllTours() async => _records.clear();

  @override
  Future<void> resetTour(String tourId) async => _records.remove(tourId);
}

class _FakeTourOverlayPresenter implements TourOverlayPresenter {
  int showCount = 0;
  VoidCallback? lastOnFinish;

  @override
  void dismiss() {}

  @override
  Future<void> show({
    required BuildContext context,
    required List<TourOverlayStep> steps,
    required TourOverlayStyle style,
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  }) async {
    showCount++;
    lastOnFinish = onFinish;
    onFinish();
  }
}

class _FakeTourGuideLabels extends TourGuideLabels {
  @override
  String finish(BuildContext context) => 'Finish';

  @override
  String next(BuildContext context) => 'Next';

  @override
  String skip(BuildContext context) => 'Skip';

  @override
  String stepSemantics(
    BuildContext context, {
    required int current,
    required int total,
  }) {
    return 'Step $current of $total';
  }
}

void main() {
  late _FakeTourRepository repository;
  late TourTargetRegistry registry;
  late _FakeTourOverlayPresenter presenter;
  late TourFlowGuard flowGuard;
  late TourGuideService service;

  const TourDefinition sampleTour = TourDefinition(
    id: 'sample_tour',
    version: 1,
    steps: <TourStep>[
      TourStep(
        id: 'step_a',
        targetId: 'target_a',
        title: 'Title',
        description: 'Body',
        contentAlign: TourContentAlign.bottom,
      ),
    ],
  );

  setUp(() {
    repository = _FakeTourRepository();
    registry = TourTargetRegistry();
    presenter = _FakeTourOverlayPresenter();
    flowGuard = TourFlowGuard();
    service = TourGuideService(
      _FakeTourCatalog(<TourDefinition>[sampleTour]),
      repository,
      registry,
      presenter,
      flowGuard,
      CompleteTour(repository, _FakeTourCatalog(<TourDefinition>[sampleTour])),
      _FakeTourGuideLabels(),
    );
  });

  testWidgets('shows tour when targets are registered and not completed', (
    tester,
  ) async {
    final GlobalKey targetKey = GlobalKey();
    registry.register('target_a', targetKey);

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return SizedBox(key: targetKey);
          },
        ),
      ),
    );

    final bool shown = await service.tryShowTour(
      context: capturedContext,
      tourId: 'sample_tour',
    );

    expect(shown, isTrue);
    expect(presenter.showCount, 1);
    final record = await repository.getCompletion('sample_tour');
    expect(record.completed, isTrue);
  });

  testWidgets('skips tour when already completed', (tester) async {
    await repository.markCompleted(tourId: 'sample_tour', version: 1);
    registry.register('target_a', GlobalKey());

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final bool shown = await service.tryShowTour(
      context: capturedContext,
      tourId: 'sample_tour',
    );

    expect(shown, isFalse);
    expect(presenter.showCount, 0);
  });

  testWidgets('does not show when flow guard is active', (tester) async {
    registry.register('target_a', GlobalKey());
    flowGuard.enter('quran_reader');

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final bool shown = await service.tryShowTour(
      context: capturedContext,
      tourId: 'sample_tour',
      force: true,
    );

    expect(shown, isFalse);
    expect(presenter.showCount, 0);
  });
}
