import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../application/account_deletion_flow_tracker.dart';

/// Shows a non-dismissible progress dialog while [DeleteAccountEvent] runs.
Future<void> showDeleteAccountProgressDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: context.l10n.deleteAccountInProgress,
    builder: (BuildContext dialogContext) {
      return const DeleteAccountProgressDialog();
    },
  );
}

/// Centered card with loading state for account deletion.
class DeleteAccountProgressDialog extends StatefulWidget {
  const DeleteAccountProgressDialog({super.key});

  @override
  State<DeleteAccountProgressDialog> createState() =>
      _DeleteAccountProgressDialogState();
}

class _DeleteAccountProgressDialogState
    extends State<DeleteAccountProgressDialog> {
  AccountDeletionFlowTracker? _tracker;
  Animation<double>? _pendingRouteAnimation;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<AccountDeletionFlowTracker>()) {
      _tracker = getIt<AccountDeletionFlowTracker>();
      _tracker!.addListener(_onDeletionFlowChanged);
      _onDeletionFlowChanged();
    }
  }

  @override
  void dispose() {
    _tracker?.removeListener(_onDeletionFlowChanged);
    _pendingRouteAnimation?.removeStatusListener(_onRouteAnimationStatus);
    super.dispose();
  }

  void _onDeletionFlowChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_tracker?.deletionInProgress != false) {
      return;
    }
    if (_tracker?.pendingLoginNavigationAfterDeletion == true) {
      // Successful deletion navigates to login; popping here races GoRouter.
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _dismissWhenRouteSettled(),
    );
  }

  /// Pops only once the dialog's push transition has finished.
  ///
  /// Popping while the route is still animating in leaves its Navigator
  /// history entry in a non-idle lifecycle state, which trips the
  /// `entry.currentState == _RouteLifecycle.idle` assertion.
  void _dismissWhenRouteSettled() {
    if (!mounted || _pendingRouteAnimation != null) {
      return;
    }
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route == null || !route.isActive) {
      return;
    }
    final Animation<double>? animation = route.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      _dismissIfStillMounted();
      return;
    }
    _pendingRouteAnimation = animation;
    animation.addStatusListener(_onRouteAnimationStatus);
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _pendingRouteAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _pendingRouteAnimation = null;
    _dismissIfStillMounted();
  }

  void _dismissIfStillMounted() {
    if (!mounted) {
      return;
    }
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route == null || !route.isActive) {
      return;
    }
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final String message = context.l10n.deleteAccountInProgress;
    final double maxWidth = tokens.contentMaxWidthForm * 0.78;

    return PopScope(
      canPop: _tracker?.deletionInProgress != true,
      child: Dialog(
        backgroundColor: colorScheme.surface,
        insetPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceExtraLarge,
          vertical: tokens.spaceExtraLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            tokens.resolveRadius(family: TilawaRadiusFamily.card),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceExtraLarge),
            child: Semantics(
              label: message,
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const ExcludeSemantics(
                    child: TilawaLoadingIndicator(),
                  ),
                  SizedBox(height: tokens.spaceMedium),
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
