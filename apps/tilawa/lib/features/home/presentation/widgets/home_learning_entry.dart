import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_learning_cards.dart';
import 'package:tilawa/features/settings/presentation/cubit/teacher_capability_cubit.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'home_learn_quran_analytics.dart';
import 'learn_quran_student_visibility.dart';

bool _isHomeLearnQuranStudentCardVisible({
  TeacherCapability? capability,
  bool capabilityLoaded = true,
}) => LearnQuranStudentVisibility.shouldShowHomeCard(
  capabilityLoaded: capabilityLoaded,
  capability: capability,
);

/// Loads [TeacherCapability] and builds the home Learn Quran sliver when allowed.
class HomeLearningEntryScope extends StatelessWidget {
  const HomeLearningEntryScope({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TeacherCapabilityCubit()..load()),
        BlocProvider(create: (_) => getIt<HomeLearningCubit>()..load()),
      ],
      child: const _HomeLearningEntrySliverHost(),
    );
  }
}

class _HomeLearningEntrySliverHost extends StatelessWidget {
  const _HomeLearningEntrySliverHost();

  @override
  Widget build(BuildContext context) {
    final SettingsTeacherCapabilityLoadState capabilityState = context
        .watch<TeacherCapabilityCubit>()
        .state;
    final HomeLearningState learningState = context
        .watch<HomeLearningCubit>()
        .state;

    final Widget? cardWidget = () {
      switch (learningState.status) {
        case HomeLearningStatus.initial:
        case HomeLearningStatus.loading:
          return null;

        case HomeLearningStatus.nextSession:
          final session = learningState.session;
          if (session == null) return null;
          final isOngoing =
              DateTime.now().isAfter(session.startsAt) &&
              DateTime.now().isBefore(session.endsAt);
          return HomeLearningCardImpressionListener(
            cardType: isOngoing ? 'ongoing' : 'imminent',
            bookingId: session.bookingId,
            child: HomeLearningNextSessionCard(session: session),
          );

        case HomeLearningStatus.pendingBooking:
          final session = learningState.session;
          if (session == null) return null;
          return HomeLearningCardImpressionListener(
            cardType: 'pending',
            bookingId: session.bookingId,
            child: HomeLearningPendingBookingCard(session: session),
          );

        case HomeLearningStatus.continueLearning:
          final aggregate = learningState.revisionAggregate;
          if (aggregate == null) return null;
          return HomeLearningCardImpressionListener(
            cardType: 'revision',
            bookingId: aggregate.id,
            child: HomeLearningRevisionCard(revisionAggregate: aggregate),
          );

        case HomeLearningStatus.none:
          if (!learningState.isInterestSignalNeeded &&
              !learningState.isBrowseEntryVisible) {
            return null;
          }
          if (!_isHomeLearnQuranStudentCardVisible(
            capability: capabilityState.capability,
            capabilityLoaded: capabilityState.hasLoaded,
          )) {
            return null;
          }
          if (learningState.isInterestSignalNeeded) {
            return const HomeLearningCardImpressionListener(
              cardType: 'interest',
              child: HomeLearningInterestCard(),
            );
          }
          // Answered yes: keep the Learn Quran entry on Home.
          return const HomeLearningCardImpressionListener(
            cardType: 'browse',
            child: HomeLearningBrowseCard(),
          );
      }
    }();

    if (cardWidget == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final MeMuslimDesignTokens tokens = context.tokens;
    final double horizontalInset =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          horizontalInset,
          0,
          horizontalInset,
          tokens.spaceMedium,
        ),
        child: cardWidget,
      ),
    );
  }
}

/// Helper widget to detect when a card is viewed and log the impression.
class HomeLearningCardImpressionListener extends StatefulWidget {
  const HomeLearningCardImpressionListener({
    required this.cardType,
    required this.child,
    this.bookingId,
    super.key,
  });

  final String cardType;
  final Widget child;
  final String? bookingId;

  @override
  State<HomeLearningCardImpressionListener> createState() =>
      _HomeLearningCardImpressionListenerState();
}

class _HomeLearningCardImpressionListenerState
    extends State<HomeLearningCardImpressionListener> {
  static const double _kVisibleFraction = 0.5;
  bool _loggedView = false;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_loggedView) return;
    if (info.visibleFraction >= _kVisibleFraction) {
      _loggedView = true;
      logHomeLearnQuranCardAction(
        action: 'viewed',
        status: widget.cardType,
        bookingId: widget.bookingId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(
        'home_learning_card_view_${widget.cardType}_${widget.bookingId ?? ''}',
      ),
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.child,
    );
  }
}
