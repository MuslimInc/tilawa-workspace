import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/auth_bloc.dart';

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
class DeleteAccountProgressDialog extends StatelessWidget {
  const DeleteAccountProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final String message = context.l10n.deleteAccountInProgress;
    final double maxWidth = tokens.contentMaxWidthForm * 0.78;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (AuthState previous, AuthState current) {
        return previous is AuthLoading && current is! AuthLoading;
      },
      listener: (BuildContext context, AuthState state) {
        Navigator.of(context, rootNavigator: true).pop();
      },
      child: PopScope(
        canPop: false,
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
      ),
    );
  }
}
