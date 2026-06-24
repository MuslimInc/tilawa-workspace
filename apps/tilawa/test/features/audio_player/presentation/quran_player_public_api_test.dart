import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/quran_player/quran_player_widget.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

const AudioEntity _tAudio = AudioEntity(
  id: '1',
  title: 'Al-Fatihah',
  url: 'https://example.com/1.mp3',
  duration: Duration.zero,
);

Widget _wrapRouter({
  required Widget child,
  EdgeInsets viewPadding = EdgeInsets.zero,
  String initialLocation = '/downloads',
  AudioPlayerBloc? audioPlayerBloc,
}) {
  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(path: '/downloads', builder: (context, state) => child),
    ],
  );

  Widget app = MaterialApp.router(
    theme: ThemeData(
      extensions: <ThemeExtension<dynamic>>[
        TilawaDesignTokens.light(),
      ],
    ),
    routerConfig: router,
  );

  if (audioPlayerBloc != null) {
    app = BlocProvider<AudioPlayerBloc>.value(
      value: audioPlayerBloc,
      child: app,
    );
  }

  return MediaQuery(
    data: MediaQueryData(viewPadding: viewPadding),
    child: ChangeNotifierProvider<QuranPlayerChromeNotifier>(
      create: (_) => QuranPlayerChromeNotifier(),
      child: app,
    ),
  );
}

void main() {
  group('QuranPlayerWidget public layout API', () {
    testWidgets(
      'collapsedFootprint uses player height + spacing on shell routes',
      (
        tester,
      ) async {
        late double footprint;
        await tester.pumpWidget(
          _wrapRouter(
            child: Builder(
              builder: (BuildContext context) {
                footprint = QuranPlayerWidget.collapsedFootprint(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final TilawaDesignTokens tokens = TilawaDesignTokens.light();
        expect(
          footprint,
          tokens.playerCollapsedHeight + tokens.spaceExtraLarge,
        );
      },
    );

    testWidgets('fabBottomOffset returns footprint off shell phone layout', (
      tester,
    ) async {
      late double offset;
      await tester.pumpWidget(
        _wrapRouter(
          initialLocation: '/downloads',
          child: Builder(
            builder: (BuildContext context) {
              offset = QuranPlayerWidget.fabBottomOffset(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(offset, greaterThan(0));
    });

    testWidgets(
      'fabBottomOffset uses small margin when shell footer owns mini player',
      (tester) async {
        final QuranPlayerChromeNotifier notifier = QuranPlayerChromeNotifier();
        addTearDown(notifier.dispose);
        notifier.updateShellChrome(
          const QuranPlayerShellChrome(
            bottomNavBarHeight: 0,
            isKeyboardOpen: false,
            isAudioBindingDeferred: false,
            hostAbsorbsBottomSafeArea: false,
          ),
        );
        final MockAudioPlayerBloc audioPlayerBloc = MockAudioPlayerBloc();
        when(() => audioPlayerBloc.state).thenReturn(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: _tAudio,
          ),
        );
        when(
          () => audioPlayerBloc.stream,
        ).thenAnswer((_) => const Stream.empty());
        late double offset;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
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
                          return Builder(
                            builder: (BuildContext context) {
                              offset = QuranPlayerWidget.fabBottomOffset(
                                context,
                              );
                              return const SizedBox.shrink();
                            },
                          );
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

        final TilawaDesignTokens tokens = TilawaDesignTokens.light();
        expect(offset, tokens.spaceSmall);
        expect(
          offset,
          lessThan(tokens.playerCollapsedHeight),
          reason: 'must not double-count footer mini-player height',
        );
      },
    );

    testWidgets(
      'fabBottomOffset clears system nav when shell footer has no mini player',
      (tester) async {
        final QuranPlayerChromeNotifier notifier = QuranPlayerChromeNotifier();
        addTearDown(notifier.dispose);
        notifier.updateShellChrome(
          const QuranPlayerShellChrome(
            bottomNavBarHeight: 0,
            isKeyboardOpen: false,
            isAudioBindingDeferred: false,
            hostAbsorbsBottomSafeArea: false,
          ),
        );
        final MockAudioPlayerBloc audioPlayerBloc = MockAudioPlayerBloc();
        when(() => audioPlayerBloc.state).thenReturn(
          const AudioPlayerState(status: AudioPlayerStatus.initial),
        );
        when(
          () => audioPlayerBloc.stream,
        ).thenAnswer((_) => const Stream.empty());

        const double systemBottomInset = 34;
        late double offset;
        late double floatingPadding;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              viewPadding: EdgeInsets.only(bottom: systemBottomInset),
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
                          return Builder(
                            builder: (BuildContext context) {
                              offset = QuranPlayerWidget.fabBottomOffset(
                                context,
                              );
                              floatingPadding = context.floatingBottomPadding;
                              return const SizedBox.shrink();
                            },
                          );
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

        expect(offset, floatingPadding);
        expect(offset, greaterThan(TilawaDesignTokens.light().spaceSmall));
      },
    );

    testWidgets('collapsedHeight reads design token', (tester) async {
      late double height;
      await tester.pumpWidget(
        _wrapRouter(
          child: Builder(
            builder: (BuildContext context) {
              height = QuranPlayerWidget.collapsedHeight(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(height, TilawaDesignTokens.light().playerCollapsedHeight);
    });
  });

  group('QuranPlayerExpandedPageContent', () {
    test('is a StatelessWidget with required callbacks', () {
      const Widget widget = QuranPlayerExpandedPageContent(
        expandAnimation: AlwaysStoppedAnimation<double>(0),
        onCollapse: _noop,
        onDismiss: _noop,
        onExpandDragStart: _noop,
        onExpandDragUpdate: _noopDouble,
        onExpandDragEnd: _noopDragEnd,
      );
      expect(widget, isA<StatelessWidget>());
    });
  });
}

void _noop() {}

void _noopDouble(double _) {}

void _noopDragEnd(DragEndDetails _) {}
