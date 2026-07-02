import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';

import '../../application/account_deletion_flow_tracker.dart';
import '../bloc/auth_bloc.dart';

/// Routes to [LoginRoute] after a successful account deletion, regardless of
/// which screen initiated the delete flow.
class AccountDeletionNavigationListener extends StatelessWidget {
  const AccountDeletionNavigationListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AccountDeletionFlowTracker tracker =
        getIt<AccountDeletionFlowTracker>();

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (AuthState previous, AuthState current) {
        return current is AuthUnauthenticated &&
            tracker.pendingLoginNavigationAfterDeletion;
      },
      listener: (BuildContext context, AuthState state) {
        tracker.clearPendingLoginNavigation();
        final String loginLocation = const LoginRoute().location;
        final String? currentLocation = AppRouter.safeActivePath;
        if (currentLocation == loginLocation) {
          logger.d(
            '[DeleteFirebaseUser] already on login after delete '
            '(location=$currentLocation)',
          );
          return;
        }
        logger.d(
          '[DeleteFirebaseUser] navigating to login after delete '
          '(from=$currentLocation)',
        );
        AppRouter.disableStateRestoration = false;
        AppRouter.router.go(loginLocation);
      },
      child: child,
    );
  }
}
