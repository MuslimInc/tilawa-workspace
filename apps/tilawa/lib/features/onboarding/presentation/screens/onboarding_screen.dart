import 'package:flutter/material.dart';
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
    // We can rely on context.l10n being available after rebuild
    // But since we just added keys, we might need a rebuild or assuming keys exist.
    // For now we assume generated code will have them.

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
      create: (context) => getIt<OnboardingCubit>(),
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompleted) {
            const LoginRoute().go(context);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.colorScheme.surface,
            body: SafeArea(
              child: Column(
                spacing: 20,
                children: [
                  // Skip button or similar could go here if needed
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                        context.read<OnboardingCubit>().pageChanged(index);
                      },
                      itemBuilder: (context, index) {
                        return OnboardingPage(content: pages[index]);
                      },
                    ),
                  ),
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? context.colorScheme.primary
                              : context.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          IconButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: const Icon(Icons.arrow_back_ios_new),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  context.colorScheme.surfaceContainerHighest,
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        if (_currentPage == pages.length - 1)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                              ), // Add padding if back button is hidden? No, if hidden it's shrunk.
                              // Actually if back button is explicitly visible, we want Start button to take remaining space or be on right.
                              // Design shows "Next" or "Start"
                              child: FilledButton(
                                onPressed: () {
                                  context
                                      .read<OnboardingCubit>()
                                      .completeOnboarding();
                                },
                                style: FilledButton.styleFrom(
                                  minimumSize: Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(context.l10n.startJourney),
                              ),
                            ),
                          )
                        else
                          FilledButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: Size(100, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(context.l10n.next),
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
