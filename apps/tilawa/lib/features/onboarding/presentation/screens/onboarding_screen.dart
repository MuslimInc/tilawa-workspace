import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../../auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import '../../../prayer_times/presentation/prayer_alerts_permission_navigation.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_footer_bar.dart';
import '../widgets/onboarding_hero_visual.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/onboarding_page_indicator.dart';

/// First-run onboarding carousel before sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyPageSystemChrome(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _applyPageSystemChrome() {
    if (!mounted) {
      return;
    }
    final ThemeData theme = Theme.of(context);
    SystemChrome.setSystemUIOverlayStyle(_systemUiOverlayStyle(theme));
  }

  SystemUiOverlayStyle _systemUiOverlayStyle(ThemeData theme) {
    final Color pageBackground = theme.scaffoldBackgroundColor;
    return AppSystemChromeStyle.buildDefaultAppStyle(
      theme,
      statusBarBackgroundColor: pageBackground,
      navigationBarColor: pageBackground,
    );
  }

  Future<void> _navigateAfterOnboarding(BuildContext context) async {
    unawaited(getIt<PrepareGoogleSignInUseCase>()());
    await PrayerAlertsPermissionNavigation.showAfterOnboarding(context);
    if (!context.mounted) {
      return;
    }
    const LoginRoute().go(context);
  }

  void _goToPage(int index) {
    unawaited(
      _pageController.animateToPage(
        index,
        duration: Theme.of(context).tokens.durationMedium,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<OnboardingContent> pages = <OnboardingContent>[
      OnboardingContent(
        imagePath: 'assets/images/listener.png',
        title: context.l10n.onboardingTitle1,
        description: context.l10n.onboardingDesc1,
        heroStyle: OnboardingHeroStyle.illustration,
      ),
      OnboardingContent(
        imagePath: 'assets/images/reciters.png',
        title: context.l10n.onboardingTitle2,
        description: context.l10n.onboardingDesc2,
        heroStyle: OnboardingHeroStyle.devicePreview,
        visualHint: context.l10n.onboardingVisualHint2,
      ),
      OnboardingContent(
        imagePath: 'assets/images/ahmed.png',
        title: context.l10n.onboardingTitle3,
        description: context.l10n.onboardingDesc3,
        heroStyle: OnboardingHeroStyle.portrait,
      ),
    ];
    final int pageCount = pages.length;
    final ThemeData theme = Theme.of(context);
    final Color pageBackground = theme.scaffoldBackgroundColor;
    final SystemUiOverlayStyle overlayStyle = _systemUiOverlayStyle(theme);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: BlocProvider(
        create: (_) => getIt<OnboardingCubit>(),
        child: BlocConsumer<OnboardingCubit, OnboardingState>(
          listener: (BuildContext context, OnboardingState state) {
            if (state is OnboardingCompleted) {
              unawaited(_navigateAfterOnboarding(context));
            }
          },
          builder: (BuildContext context, OnboardingState state) {
            final MeMuslimDesignTokens tokens = theme.tokens;
            return Scaffold(
              backgroundColor: pageBackground,
              body: TilawaThumbReachLayout(
                useSafeArea: true,
                // Dots stay in the content band so primary CTA Y matches
                // Welcome / PrayerAlerts. Top padding separates copy from dots.
                content: Column(
                  children: <Widget>[
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: pageCount,
                        onPageChanged: (int index) {
                          setState(() => _currentPage = index);
                          _applyPageSystemChrome();
                          context.read<OnboardingCubit>().pageChanged(index);
                          if (index == pageCount - 1) {
                            unawaited(getIt<PrepareGoogleSignInUseCase>()());
                          }
                        },
                        itemBuilder: (BuildContext context, int index) {
                          return OnboardingPage(
                            content: pages[index],
                            semanticsLabel: context.l10n
                                .onboardingPageSemantics(
                                  index + 1,
                                  pageCount,
                                ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: tokens.spaceSmall,
                      ),
                      child: Semantics(
                        label: '${_currentPage + 1} / $pageCount',
                        child: OnboardingPageIndicator(
                          count: pageCount,
                          currentIndex: _currentPage,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: OnboardingFooterBar(
                  pageCount: pageCount,
                  currentPage: _currentPage,
                  backLabel: context.l10n.previous,
                  nextLabel: context.l10n.next,
                  completeLabel: context.l10n.startJourney,
                  onBack: () => _goToPage(_currentPage - 1),
                  onNext: () => _goToPage(_currentPage + 1),
                  onComplete: () =>
                      context.read<OnboardingCubit>().completeOnboarding(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
