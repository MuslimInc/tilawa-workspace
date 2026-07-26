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
import '../widgets/onboarding_page_scroll_fade.dart';

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
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _pageController.jumpToPage(index);
      return;
    }
    unawaited(
      _pageController.animateToPage(
        index,
        duration: tokens.durationMedium,
        curve: tokens.curveEmphasized,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<OnboardingContent> pages = <OnboardingContent>[
      OnboardingContent(
        imagePath: 'assets/lottie/muslim_man_praying_mosque.json',
        title: context.l10n.onboardingTitle1,
        description: context.l10n.onboardingDesc1,
        heroStyle: OnboardingHeroStyle.lottie,
      ),
      OnboardingContent(
        imagePath: '',
        title: context.l10n.onboardingTitle2,
        description: context.l10n.onboardingDesc2,
        heroStyle: OnboardingHeroStyle.devicePreview,
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
            final bool isLastPage = _currentPage == pageCount - 1;
            void completeOnboarding() =>
                context.read<OnboardingCubit>().completeOnboarding();
            return Scaffold(
              backgroundColor: pageBackground,
              body: TilawaThumbReachLayout(
                useSafeArea: true,
                // Dots stay in the content band so primary CTA Y matches
                // Welcome / PrayerAlerts. Top padding separates copy from dots.
                content: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: tokens.spaceLarge,
                        end: tokens.spaceLarge,
                        top: tokens.spaceExtraSmall,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: isLastPage
                            ? SizedBox(height: tokens.minInteractiveDimension)
                            : TilawaButton(
                                text: context.l10n.onboardingSkip,
                                variant: TilawaButtonVariant.ghost,
                                size: TilawaButtonSize.small,
                                semanticLabel: context.l10n.onboardingSkip,
                                onPressed: completeOnboarding,
                              ),
                      ),
                    ),
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
                          return OnboardingPageScrollFade(
                            controller: _pageController,
                            index: index,
                            child: OnboardingPage(
                              content: pages[index],
                              isActive: index == _currentPage,
                              semanticsLabel: context.l10n
                                  .onboardingPageSemantics(
                                    index + 1,
                                    pageCount,
                                  ),
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
                        label: context.l10n.onboardingPageSemantics(
                          _currentPage + 1,
                          pageCount,
                        ),
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
                  onComplete: completeOnboarding,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
