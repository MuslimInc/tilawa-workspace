import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';

import '../cubit/session_validity_cubit.dart';

/// Shows signed-in-elsewhere dialog when [SessionValidityCubit] revokes session.
class SessionRevokedNavigationListener extends StatelessWidget {
  const SessionRevokedNavigationListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionValidityCubit, SessionValidityState>(
      listenWhen:
          (SessionValidityState previous, SessionValidityState current) {
            return !previous.revoked && current.revoked;
          },
      listener: (BuildContext context, SessionValidityState state) {
        _scheduleSignedInElsewhereDialog(context);
      },
      child: child,
    );
  }
}

void _scheduleSignedInElsewhereDialog(BuildContext listenerContext) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!listenerContext.mounted) {
      return;
    }
    _showSignedInElsewhereDialog(listenerContext);
  });
}

void _showSignedInElsewhereDialog(BuildContext listenerContext) {
  if (_shouldSuppressSessionRevokedDialog(listenerContext)) {
    return;
  }

  final BuildContext? dialogHost = AppRouter.navigatorKey.currentContext;
  if (dialogHost == null || !dialogHost.mounted) {
    return;
  }

  final AppLocalizations l10n = _resolveSessionRevokedL10n(
    dialogHost,
    listenerContext,
  );

  unawaited(
    showDialog<void>(
      context: dialogHost,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.authSignedInElsewhereTitle),
          content: Text(l10n.authSignedInElsewhereBody),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final loginLocation = const LoginRoute().location;
                final String? currentLocation = AppRouter.safeActivePath;
                if (currentLocation != loginLocation) {
                  AppRouter.router.go(loginLocation);
                }
              },
              child: Text(l10n.authSignedInElsewhereAction),
            ),
          ],
        );
      },
    ),
  );
}

bool _shouldSuppressSessionRevokedDialog(BuildContext listenerContext) {
  try {
    if (listenerContext.read<AuthBloc>().state is AuthLoading) {
      return true;
    }
  } on Object {
    // Tests may omit [AuthBloc].
  }

  if (getIt.isRegistered<GoogleSignInSessionTracker>() &&
      getIt<GoogleSignInSessionTracker>().inFlight) {
    return true;
  }

  return false;
}

AppLocalizations _resolveSessionRevokedL10n(
  BuildContext dialogHost,
  BuildContext listenerContext,
) {
  final AppLocalizations? localized = Localizations.of<AppLocalizations>(
    dialogHost,
    AppLocalizations,
  );
  if (localized != null) {
    return localized;
  }

  return lookupAppLocalizations(_resolveLocale(dialogHost, listenerContext));
}

Locale _resolveLocale(BuildContext dialogHost, BuildContext listenerContext) {
  try {
    return Localizations.localeOf(dialogHost);
  } on Object {
    // dialogHost may lack a [Localizations] ancestor during early startup.
  }

  try {
    return listenerContext.read<LocalizationBloc>().state.locale;
  } on Object {
    // Tests or bootstrap may omit [LocalizationBloc].
  }

  return const Locale('ar');
}
