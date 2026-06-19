import 'package:flutter/foundation.dart';

import '../domain/home_hero_gradient_resolver.dart';

/// Debug-only override for previewing home hero gradient phases.
abstract final class HomeHeroGradientDebug {
  const HomeHeroGradientDebug._();

  /// When non-null, [HomeHeroGradientResolver] returns this phase instead of
  /// prayer-time resolution. Debug builds only.
  static final ValueNotifier<HomeHeroDayPhase?> phaseOverride =
      ValueNotifier<HomeHeroDayPhase?>(null);

  /// Cycles Auto → Day → Dusk → Night → Auto.
  static void cyclePhase() {
    phaseOverride.value = switch (phaseOverride.value) {
      null => HomeHeroDayPhase.day,
      HomeHeroDayPhase.day => HomeHeroDayPhase.dusk,
      HomeHeroDayPhase.dusk => HomeHeroDayPhase.night,
      HomeHeroDayPhase.night => null,
    };
  }

  static String labelFor(HomeHeroDayPhase? phase) {
    return switch (phase) {
      null => 'Auto (prayer times)',
      HomeHeroDayPhase.day => 'Day',
      HomeHeroDayPhase.dusk => 'Dusk',
      HomeHeroDayPhase.night => 'Night',
    };
  }
}
