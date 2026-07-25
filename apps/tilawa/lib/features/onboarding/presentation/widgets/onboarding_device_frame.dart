import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Platform-accurate phone chrome for the onboarding Home preview.
///
/// - iOS → iPhone 16-style chassis with Dynamic Island + home indicator
/// - Android (and other) → Galaxy flagship-style chassis with hole-punch
class OnboardingDeviceFrame extends StatelessWidget {
  const OnboardingDeviceFrame({
    super.key,
    required this.child,
    this.platformOverride,
  });

  final Widget child;

  /// Test seam — when null, uses [ThemeData.platform].
  final TargetPlatform? platformOverride;

  /// Logical screen aspect inside the bezel (modern ~19.5∶9).
  static const double screenAspectRatio = 9 / 19.5;

  bool _isIos(BuildContext context) {
    final TargetPlatform platform =
        platformOverride ?? Theme.of(context).platform;
    return platform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    if (_isIos(context)) {
      return _Iphone16DeviceFrame(child: child);
    }
    return _SamsungDeviceFrame(child: child);
  }
}

class _Iphone16DeviceFrame extends StatelessWidget {
  const _Iphone16DeviceFrame({required this.child});

  final Widget child;

  /// Outer corner as a fraction of frame width (iPhone 16 continuous curve).
  static const double _outerCornerFactor = 0.22;

  /// Thin flat bezel between glass and chassis.
  static const double _bezelFactor = 0.018;

  /// Dynamic Island width / screen width.
  static const double _islandWidthFactor = 0.34;

  /// Dynamic Island height / island width.
  static const double _islandHeightFactor = 0.29;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final Color chassis = scheme.brightness == Brightness.light
        ? const Color(0xFF1C1C1E)
        : scheme.surfaceContainerHighest;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double frameWidth = constraints.maxWidth;
        final double outerCorner = (frameWidth * _outerCornerFactor).clamp(
          tokens.radiusExtraLarge,
          tokens.radiusExtraLarge * 2.2,
        );
        final double bezel = (frameWidth * _bezelFactor).clamp(2.0, 5.0);
        final double innerCorner = (outerCorner - bezel).clamp(
          tokens.radiusLarge,
          outerCorner,
        );
        final double buttonThickness = (frameWidth * 0.012).clamp(1.5, 3.0);

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // Volume / silent (left rail).
            Positioned(
              left: -buttonThickness * 0.55,
              top: frameWidth * 0.22,
              child: _SideRail(
                width: buttonThickness,
                height: frameWidth * 0.04,
                color: const Color(0xFF2C2C2E),
              ),
            ),
            Positioned(
              left: -buttonThickness * 0.55,
              top: frameWidth * 0.30,
              child: _SideRail(
                width: buttonThickness,
                height: frameWidth * 0.09,
                color: const Color(0xFF2C2C2E),
              ),
            ),
            Positioned(
              left: -buttonThickness * 0.55,
              top: frameWidth * 0.42,
              child: _SideRail(
                width: buttonThickness,
                height: frameWidth * 0.09,
                color: const Color(0xFF2C2C2E),
              ),
            ),
            // Power (right rail).
            Positioned(
              right: -buttonThickness * 0.55,
              top: frameWidth * 0.34,
              child: _SideRail(
                width: buttonThickness,
                height: frameWidth * 0.12,
                color: const Color(0xFF2C2C2E),
              ),
            ),
            _ChassisBody(
              outerRadius: outerCorner,
              bezel: bezel,
              rimColor: Color.lerp(chassis, Colors.white, 0.14)!,
              chassisColor: chassis,
              innerCorner: innerCorner,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  child,
                  const _IphoneDynamicIsland(
                    widthFactor: _islandWidthFactor,
                    heightFactor: _islandHeightFactor,
                  ),
                  const _IosHomeIndicator(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SamsungDeviceFrame extends StatelessWidget {
  const _SamsungDeviceFrame({required this.child});

  final Widget child;

  /// Galaxy flagship squircle — tighter than iPhone continuous curve.
  /// ~9% of width reads like S24/S25 chassis (not capsule).
  static const double _outerCornerFactor = 0.09;

  static const double _bezelFactor = 0.01;

  /// Hole-punch diameter / screen width.
  static const double _punchFactor = 0.045;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final Color chassis = scheme.brightness == Brightness.light
        ? const Color(0xFF2B2B2B)
        : scheme.surfaceContainerHigh;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double frameWidth = constraints.maxWidth;
        final double outerCorner = (frameWidth * _outerCornerFactor).clamp(
          tokens.radiusMedium,
          tokens.radiusExtraLarge,
        );
        final double bezel = (frameWidth * _bezelFactor).clamp(1.5, 3.5);
        final double innerCorner = (outerCorner - bezel * 0.75).clamp(
          tokens.radiusSmall,
          outerCorner,
        );
        final double buttonThickness = (frameWidth * 0.01).clamp(1.2, 2.5);

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: -buttonThickness * 0.55,
              top: frameWidth * 0.32,
              child: _SideRail(
                width: buttonThickness,
                height: frameWidth * 0.14,
                color: const Color(0xFF3A3A3A),
                sharp: true,
              ),
            ),
            Positioned(
              right: -buttonThickness * 0.55,
              top: frameWidth * 0.32,
              child: _SideRail(
                width: buttonThickness,
                height: frameWidth * 0.14,
                color: const Color(0xFF3A3A3A),
                sharp: true,
              ),
            ),
            _ChassisBody(
              outerRadius: outerCorner,
              bezel: bezel,
              rimColor: Color.lerp(chassis, Colors.white, 0.18)!,
              chassisColor: chassis,
              innerCorner: innerCorner,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  child,
                  const _SamsungHolePunch(diameterFactor: _punchFactor),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChassisBody extends StatelessWidget {
  const _ChassisBody({
    required this.outerRadius,
    required this.bezel,
    required this.rimColor,
    required this.chassisColor,
    required this.innerCorner,
    required this.child,
  });

  final double outerRadius;
  final double bezel;
  final Color rimColor;
  final Color chassisColor;
  final double innerCorner;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius outer = BorderRadius.circular(outerRadius);
    final BorderRadius inner = BorderRadius.circular(innerCorner);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: outer,
        border: Border.all(color: rimColor, width: tokens.borderWidthThin),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(chassisColor, Colors.white, 0.08)!,
            chassisColor,
            Color.lerp(chassisColor, Colors.black, 0.22)!,
          ],
          stops: const <double>[0, 0.45, 1],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: tokens.opacitySubtle * 1.6),
            blurRadius: tokens.spaceLarge,
            offset: Offset(0, tokens.spaceSmall),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: tokens.opacitySubtle),
            blurRadius: tokens.spaceMedium,
            offset: tokens.shadowOffsetSmall,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(bezel),
        child: AspectRatio(
          aspectRatio: OnboardingDeviceFrame.screenAspectRatio,
          child: ClipRRect(
            borderRadius: inner,
            clipBehavior: Clip.antiAlias,
            child: ColoredBox(
              color: scheme.surface,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.width,
    required this.height,
    required this.color,
    this.sharp = false,
  });

  final double width;
  final double height;
  final Color color;
  final bool sharp;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(sharp ? 1 : width),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _IphoneDynamicIsland extends StatelessWidget {
  const _IphoneDynamicIsland({
    required this.widthFactor,
    required this.heightFactor,
  });

  final double widthFactor;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double islandWidth = constraints.maxWidth * widthFactor;
        final double islandHeight = islandWidth * heightFactor;

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: tokens.spaceExtraSmall + 2),
            child: DecoratedBox(
              key: const ValueKey<String>('onboarding_iphone_dynamic_island'),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(islandHeight),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SizedBox(width: islandWidth, height: islandHeight),
            ),
          ),
        );
      },
    );
  }
}

class _IosHomeIndicator extends StatelessWidget {
  const _IosHomeIndicator();

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: tokens.spaceExtraSmall + 1),
        child: DecoratedBox(
          key: const ValueKey<String>('onboarding_ios_home_indicator'),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
          ),
          child: SizedBox(
            width: tokens.spaceExtraLarge * 2.2,
            height: 3,
          ),
        ),
      ),
    );
  }
}

class _SamsungHolePunch extends StatelessWidget {
  const _SamsungHolePunch({required this.diameterFactor});

  final double diameterFactor;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double diameter = (constraints.maxWidth * diameterFactor).clamp(
          5.0,
          12.0,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: tokens.spaceSmall),
            child: DecoratedBox(
              key: const ValueKey<String>('onboarding_samsung_hole_punch'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.85),
                  width: 0.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.12),
                    blurRadius: 1,
                    spreadRadius: 0.2,
                  ),
                ],
              ),
              child: SizedBox(width: diameter, height: diameter),
            ),
          ),
        );
      },
    );
  }
}
