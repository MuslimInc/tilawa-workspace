import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_verification_cubit.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Non-blocking top banner shown while the session is being re-verified after a
/// transient auth/App Check hiccup. Overlays route content without capturing
/// input, and animates away the moment the session recovers.
///
/// Mount once, high in the tree (inside [MaterialApp.router]'s `builder`), so
/// every route shares it. Reads [SessionVerificationCubit]; renders nothing
/// unless `showBanner` is set (which only happens past the "slow" threshold).
class SessionVerificationBanner extends StatelessWidget {
  const SessionVerificationBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child:
              BlocBuilder<SessionVerificationCubit, SessionVerificationState>(
                buildWhen: (previous, current) =>
                    previous.showBanner != current.showBanner,
                builder: (context, state) {
                  return IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: context.tokens.durationMedium,
                      switchInCurve: context.tokens.curveStandard,
                      switchOutCurve: context.tokens.curveStandard,
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.topCenter,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: state.showBanner
                          ? const _VerifyingBar()
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}

class _VerifyingBar extends StatelessWidget {
  const _VerifyingBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: tokens.iconSizeSmall,
                child: CircularProgressIndicator(
                  strokeWidth: tokens.borderWidthThin * 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    scheme.onSecondaryContainer,
                  ),
                ),
              ),
              SizedBox(width: tokens.spaceSmall),
              Flexible(
                child: Text(
                  context.l10n.authSessionVerifying,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
