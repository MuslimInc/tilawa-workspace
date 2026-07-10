import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/email_auth_form_cubit.dart';
import '../services/email_auth_error_messages.dart';

class EmailAuthFields extends StatelessWidget {
  const EmailAuthFields({
    super.key,
    required this.showConfirmPassword,
    required this.enabled,
  });

  final bool showConfirmPassword;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return BlocBuilder<EmailAuthFormCubit, EmailAuthFormState>(
      builder: (BuildContext context, EmailAuthFormState state) {
        final EmailAuthFormCubit cubit = context.read<EmailAuthFormCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceMedium,
          children: <Widget>[
            TilawaTextField(
              label: context.l10n.emailAddress,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: enabled,
              onChanged: cubit.emailChanged,
              errorText: localizedEmailAuthFieldError(
                state.emailErrorKey,
                context.l10n,
              ),
            ),
            TilawaTextField(
              label: context.l10n.password,
              isPassword: true,
              textInputAction: showConfirmPassword
                  ? TextInputAction.next
                  : TextInputAction.done,
              enabled: enabled,
              onChanged: cubit.passwordChanged,
              errorText: localizedEmailAuthFieldError(
                state.passwordErrorKey,
                context.l10n,
              ),
            ),
            if (showConfirmPassword)
              TilawaTextField(
                label: context.l10n.confirmPassword,
                isPassword: true,
                textInputAction: TextInputAction.done,
                enabled: enabled,
                onChanged: cubit.confirmPasswordChanged,
                errorText: localizedEmailAuthFieldError(
                  state.confirmPasswordErrorKey,
                  context.l10n,
                ),
              ),
          ],
        );
      },
    );
  }
}
