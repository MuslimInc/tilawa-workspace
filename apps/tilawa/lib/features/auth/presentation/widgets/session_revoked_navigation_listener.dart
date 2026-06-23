import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

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
        final l10n = AppLocalizations.of(context);
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(l10n.authSignedInElsewhereTitle),
                content: Text(l10n.authSignedInElsewhereBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.authSignedInElsewhereAction),
                  ),
                ],
              );
            },
          ),
        );
      },
      child: child,
    );
  }
}
