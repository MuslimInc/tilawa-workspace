import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double indicatorHeight = tokens.spaceSmall - tokens.spaceTiny;
    final double activeIndicatorWidth = tokens.spaceExtraLarge;
    final double inactiveIndicatorWidth = tokens.spaceSmall;
    final double indicatorRadius = tokens.radiusSmall / 2;
    final Color statusBarColor = theme.colorScheme.surface;
    final Brightness statusBarBrightness = ThemeData.estimateBrightnessForColor(
      statusBarColor,
    );
    final Brightness statusBarIconBrightness =
        statusBarBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    final pages = <OnboardingContent>[
      OnboardingContent(
        imagePath: 'assets/images/listener.png',
        title: context.l10n.onboardingTitle1,
        description: context.l10n.onboardingDesc1,
      ),
      OnboardingContent(
        imagePath: 'assets/images/reciters.png',
        title: context.l10n.onboardingTitle2,
        description: context.l10n.onboardingDesc2,
      ),
      OnboardingContent(
        imagePath: 'assets/images/ahmed.png',
        title: context.l10n.onboardingTitle3,
        description: context.l10n.onboardingDesc3,
      ),
    ];

    return BlocProvider(
      create: (_) => getIt<OnboardingCubit>(),
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompleted) {
            const LoginRoute().go(context);
          }
        },
        builder: (context, state) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: statusBarColor,
              statusBarIconBrightness: statusBarIconBrightness,
              statusBarBrightness: statusBarBrightness,
            ),
            child: Scaffold(
              backgroundColor: statusBarColor,
              body: Column(
                spacing: tokens.spaceExtraLarge,
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        context.read<OnboardingCubit>().pageChanged(index);
                      },
                      itemBuilder: (context, index) {
                        return OnboardingPage(content: pages[index]);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: tokens.durationMedium,
                        margin: EdgeInsets.symmetric(
                          horizontal: tokens.spaceExtraSmall,
                        ),
                        height: indicatorHeight,
                        width: _currentPage == index
                            ? activeIndicatorWidth
                            : inactiveIndicatorWidth,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(indicatorRadius),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spaceExtraLarge,
                      0,
                      tokens.spaceExtraLarge,
                      context.floatingBottomPadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          IconButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: tokens.durationMedium,
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: const Icon(Icons.arrow_back_ios_new),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                            tooltip: context.l10n.previous,
                          )
                        else
                          const SizedBox.shrink(),
                        if (_currentPage == pages.length - 1)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: tokens.spaceLarge,
                              ),
                              child: TilawaButton(
                                text: context.l10n.startJourney,
                                variant: TilawaButtonVariant.primary,
                                size: TilawaButtonSize.large,
                                isFullWidth: true,
                                onPressed: () {
                                  context
                                      .read<OnboardingCubit>()
                                      .completeOnboarding();
                                },
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: tokens.spaceExtraLarge * 4,
                            child: TilawaButton(
                              text: context.l10n.next,
                              variant: TilawaButtonVariant.primary,
                              size: TilawaButtonSize.large,
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: tokens.durationMedium,
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
