import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/reciters/presentation/layout/reciter_details_fab_layout.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

const AudioEntity _tAudio = AudioEntity(
  id: '1',
  title: 'An-Nas',
  url: 'https://example.com/114.mp3',
  duration: Duration.zero,
);

Future<ReciterDetailsFabLayout> _resolveLayout(
  WidgetTester tester, {
  required QuranPlayerShellChrome shellChrome,
  required AudioPlayerState audioState,
  EdgeInsets viewPadding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
  bool scrollToTopFabVisible = true,
}) async {
  final QuranPlayerChromeNotifier notifier = QuranPlayerChromeNotifier();
  addTearDown(notifier.dispose);
  notifier.updateShellChrome(shellChrome);

  final MockAudioPlayerBloc audioPlayerBloc = MockAudioPlayerBloc();
  when(() => audioPlayerBloc.state).thenReturn(audioState);
  when(() => audioPlayerBloc.stream).thenAnswer((_) => const Stream.empty());

  late ReciterDetailsFabLayout layout;

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        viewPadding: viewPadding,
        viewInsets: viewInsets,
      ),
      child: ChangeNotifierProvider<QuranPlayerChromeNotifier>.value(
        value: notifier,
        child: BlocProvider<AudioPlayerBloc>.value(
          value: audioPlayerBloc,
          child: MaterialApp.router(
            theme: ThemeData(
              extensions: <ThemeExtension<dynamic>>[
                TilawaDesignTokens.light(),
              ],
            ),
            routerConfig: GoRouter(
              initialLocation: '/reciter/maher',
              routes: <RouteBase>[
                GoRoute(
                  path: '/reciter/:reciterId',
                  builder: (BuildContext context, GoRouterState state) {
                    layout = ReciterDetailsFabLayout.resolve(
                      context,
                      scrollToTopFabVisible: scrollToTopFabVisible,
                    );
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return layout;
}

void main() {
  group('ReciterDetailsFabLayout', () {
    testWidgets('no mini-player lifts FAB and list for system nav', (
      tester,
    ) async {
      const QuranPlayerShellChrome shellChrome = QuranPlayerShellChrome(
        bottomNavBarHeight: 0,
        isKeyboardOpen: false,
        isAudioBindingDeferred: false,
        hostAbsorbsBottomSafeArea: false,
      );

      final ReciterDetailsFabLayout layout = await _resolveLayout(
        tester,
        shellChrome: shellChrome,
        audioState: const AudioPlayerState(status: AudioPlayerStatus.initial),
      );

      final TilawaDesignTokens tokens = TilawaDesignTokens.light();
      final double expectedFabOffset =
          kTilawaMinInteractiveDimension + tokens.spaceLarge;

      expect(layout.fabBottomOffset, expectedFabOffset);
      expect(
        layout.listBottomPadding,
        expectedFabOffset + kTilawaMinInteractiveDimension + tokens.spaceLarge,
      );
      expect(layout.showScrollToTopFab, isTrue);
    });

    testWidgets('mini-player footer adds FAB clearance plus breathing room', (
      tester,
    ) async {
      const QuranPlayerShellChrome shellChrome = QuranPlayerShellChrome(
        bottomNavBarHeight: 0,
        isKeyboardOpen: false,
        isAudioBindingDeferred: false,
        hostAbsorbsBottomSafeArea: false,
      );

      final ReciterDetailsFabLayout layout = await _resolveLayout(
        tester,
        shellChrome: shellChrome,
        audioState: const AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: _tAudio,
        ),
      );

      final TilawaDesignTokens tokens = TilawaDesignTokens.light();
      final double fabBottomOffset = tokens.spaceSmall + tokens.spaceLarge;
      final double fabClearance =
          fabBottomOffset + kTilawaMinInteractiveDimension + tokens.spaceLarge;

      expect(layout.fabBottomOffset, fabBottomOffset);
      expect(layout.listBottomPadding, fabClearance + tokens.spaceMedium);
      expect(
        layout.listBottomPadding,
        greaterThan(tokens.spaceSmall),
        reason: 'must not use bare mini-player gap for FAB clearance',
      );
    });

    testWidgets('keyboard open hides FAB and uses small list padding', (
      tester,
    ) async {
      const QuranPlayerShellChrome shellChrome = QuranPlayerShellChrome(
        bottomNavBarHeight: 0,
        isKeyboardOpen: true,
        isAudioBindingDeferred: false,
        hostAbsorbsBottomSafeArea: false,
      );

      final ReciterDetailsFabLayout layout = await _resolveLayout(
        tester,
        shellChrome: shellChrome,
        audioState: const AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: _tAudio,
        ),
        viewInsets: const EdgeInsets.only(bottom: 280),
      );

      final TilawaDesignTokens tokens = TilawaDesignTokens.light();

      expect(layout.showScrollToTopFab, isFalse);
      expect(layout.fabBottomOffset, 0);
      expect(layout.listBottomPadding, tokens.spaceSmall);
    });

    testWidgets(
      'opaque system nav increases FAB offset when player dismissed',
      (
        tester,
      ) async {
        const double systemBottomInset = 34;
        const QuranPlayerShellChrome shellChrome = QuranPlayerShellChrome(
          bottomNavBarHeight: 0,
          isKeyboardOpen: false,
          isAudioBindingDeferred: false,
          hostAbsorbsBottomSafeArea: false,
        );

        final ReciterDetailsFabLayout layout = await _resolveLayout(
          tester,
          shellChrome: shellChrome,
          audioState: const AudioPlayerState(status: AudioPlayerStatus.initial),
          viewPadding: const EdgeInsets.only(bottom: systemBottomInset),
        );

        final TilawaDesignTokens tokens = TilawaDesignTokens.light();
        final double floatingPadding = systemBottomInset + tokens.spaceSmall;
        final double expectedFabOffset =
            (floatingPadding > kTilawaMinInteractiveDimension
                ? floatingPadding
                : kTilawaMinInteractiveDimension) +
            tokens.spaceLarge;

        expect(layout.fabBottomOffset, expectedFabOffset);
        expect(
          layout.fabBottomOffset,
          greaterThan(kTilawaMinInteractiveDimension),
        );
      },
    );
  });
}
