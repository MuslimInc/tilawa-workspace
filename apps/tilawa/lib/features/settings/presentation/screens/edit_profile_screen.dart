import 'dart:async';
import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/settings/presentation/cubit/edit_profile_cubit.dart';
import 'package:tilawa/shared/widgets/profile_avatar.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserEntity? user = context.select<AuthBloc, UserEntity?>(
      (bloc) => switch (bloc.state) {
        AuthAuthenticated(:final user) => user,
        _ => null,
      },
    );

    if (user == null) {
      return TilawaShellChildScaffold(
        appBar: TilawaAppBar(title: context.l10n.editProfileTitle),
        body: Center(
          child: TilawaIllustratedState(
            icon: FluentIcons.person_24_regular,
            title: context.l10n.editProfileUnavailableTitle,
            subtitle: context.l10n.editProfileUnavailableMessage,
          ),
        ),
      );
    }

    return BlocProvider<EditProfileCubit>(
      create: (_) => getIt<EditProfileCubit>()..init(user),
      child: _EditProfileView(user: user),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView({required this.user});

  final UserEntity user;

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmDiscardIfNeeded() async {
    final EditProfileState state = context.read<EditProfileCubit>().state;
    if (!state.isDirty || state.status == EditProfileStatus.saving) {
      return;
    }

    final l10n = context.l10n;
    final bool? discard = await showTilawaConfirmDialog(
      context: context,
      title: l10n.editProfileDiscardTitle,
      message: l10n.editProfileDiscardMessage,
      confirmLabel: l10n.editProfileDiscardConfirm,
      cancelLabel: l10n.editProfileKeepEditing,
      confirmVariant: TilawaButtonVariant.danger,
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showPhotoActions(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<EditProfileCubit>();
    final bool hasPhoto = cubit.state.hasPhoto;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    await showTilawaModalBottomSheet<void>(
      context: context,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      backgroundColor: theme.colorScheme.surface,
      sheetSemanticsLabel: l10n.editProfilePhotoActionsTitle,
      builder: (sheetContext) {
        return TilawaBottomSheetScaffold(
          topBar: TilawaBottomSheetTitleRow(
            title: l10n.editProfilePhotoActionsTitle,
            trailingClose: true,
            closeSemanticLabel: l10n.close,
          ),
          footer: TilawaButton(
            text: l10n.cancel,
            variant: TilawaButtonVariant.ghost,
            isFullWidth: true,
            onPressed: () => Navigator.pop(sheetContext),
          ),
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.spaceExtraSmall,
              children: [
                TilawaSettingsTile(
                  icon: FluentIcons.image_24_regular,
                  title: l10n.gallery,
                  showDivider: false,
                  trailing: const SizedBox.shrink(),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(cubit.pickImage(ImageSource.gallery));
                  },
                ),
                TilawaSettingsTile(
                  icon: FluentIcons.camera_24_regular,
                  title: l10n.camera,
                  showDivider: false,
                  trailing: const SizedBox.shrink(),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(cubit.pickImage(ImageSource.camera));
                  },
                ),
                if (hasPhoto)
                  TilawaSettingsTile(
                    icon: FluentIcons.delete_24_regular,
                    iconColor: theme.colorScheme.error,
                    title: l10n.editProfileRemovePhoto,
                    showDivider: false,
                    trailing: const SizedBox.shrink(),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      cubit.removePhoto();
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _submit(EditProfileCubit cubit, EditProfileState state) {
    if (!state.canSave) {
      return;
    }
    unawaited(cubit.save(widget.user));
  }

  String _failureMessage(BuildContext context, String? errorMessage) {
    final l10n = context.l10n;
    return switch (errorMessage) {
      'avatarTooLarge' => l10n.editProfileAvatarTooLarge,
      'pickerFailed' => l10n.editProfilePickFailed,
      _ => l10n.editProfileSaveFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == EditProfileStatus.success &&
            state.savedUser != null) {
          context.read<AuthBloc>().add(
            AuthEvent.accountProfileUpdated(user: state.savedUser!),
          );
          TilawaFeedback.showToast(
            context,
            message: l10n.editProfileSaved,
            variant: TilawaFeedbackVariant.success,
          );
          Navigator.of(context).pop();
        } else if (state.status == EditProfileStatus.failure) {
          TilawaFeedback.showToast(
            context,
            message: _failureMessage(context, state.errorMessage),
            variant: TilawaFeedbackVariant.error,
          );
        }
      },
      builder: (context, state) {
        final bool saving = state.status == EditProfileStatus.saving;
        final cubit = context.read<EditProfileCubit>();
        final bool blockPop = state.isDirty || saving;

        return PopScope(
          canPop: !blockPop,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || saving) {
              return;
            }
            unawaited(_confirmDiscardIfNeeded());
          },
          child: TilawaShellChildScaffold(
            appBar: TilawaAppBar(title: l10n.editProfileTitle),
            body: TilawaFormScreenScaffold(
              body: TilawaContentBounds(
                kind: TilawaContentKind.form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          _EditableAvatarButton(
                            state: state,
                            semanticLabel: l10n.editProfileChangePhotoSemantic,
                            enabled: !saving,
                            onPressed: () =>
                                unawaited(_showPhotoActions(context)),
                          ),
                          SizedBox(height: tokens.spaceSmall),
                          TilawaButton(
                            text: l10n.editProfileChangePhoto,
                            variant: TilawaButtonVariant.ghost,
                            onPressed: saving
                                ? null
                                : () => unawaited(_showPhotoActions(context)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraLarge),
                    TilawaTextField(
                      label: l10n.editProfileDisplayName,
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      enabled: !saving,
                      onChanged: cubit.displayNameChanged,
                      onSubmitted: (_) => _submit(cubit, state),
                      errorText: state.nameError
                          ? l10n.editProfileDisplayNameRequired
                          : null,
                    ),
                  ],
                ),
              ),
              // Sticky CTA: TilawaButton (not FormSubmitFooter) so Save can
              // disable when unchanged — FormSubmitFooter is always-enabled.
              footer: TilawaContentBounds(
                kind: TilawaContentKind.form,
                child: TilawaButton(
                  text: l10n.save,
                  isFullWidth: true,
                  size: TilawaButtonSize.large,
                  isLoading: saving,
                  onPressed: state.canSave ? () => _submit(cubit, state) : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditableAvatarButton extends StatelessWidget {
  const _EditableAvatarButton({
    required this.state,
    required this.semanticLabel,
    required this.enabled,
    required this.onPressed,
  });

  final EditProfileState state;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final double size = tokens.iconHubExtent + tokens.spaceLarge;
    final double badgeSize = tokens.minInteractiveDimension * 0.5;
    // Inset into the circle so the badge sits on the rim, not the square corner.
    final double badgeInset = badgeSize * 0.20;
    // Outer padding so overflow paints without being clipped by ancestors.
    final double badgeOutset = badgeSize * 0.20;

    final Widget badge = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.surface,
          width: theme.componentTokens.card.borderWidth,
        ),
      ),
      child: SizedBox.square(
        dimension: badgeSize,
        child: Center(
          child: Icon(
            FluentIcons.camera_20_filled,
            size: tokens.iconSizeSmall,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          end: badgeOutset,
          bottom: badgeOutset,
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: TilawaInteractiveSurface(
                  onTap: enabled ? onPressed : null,
                  semanticLabel: semanticLabel,
                  borderRadius: BorderRadius.circular(size / 2),
                  child: _EditProfileAvatar(state: state, size: size),
                ),
              ),
              PositionedDirectional(
                end: -badgeOutset + badgeInset,
                bottom: -badgeOutset + badgeInset,
                child: TilawaInteractiveSurface(
                  onTap: enabled ? onPressed : null,
                  semanticLabel: semanticLabel,
                  borderRadius: BorderRadius.circular(badgeSize / 2),
                  child: badge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileAvatar extends StatelessWidget {
  const _EditProfileAvatar({required this.state, required this.size});

  final EditProfileState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (state.localImagePath != null && !state.removePhoto) {
      return ClipOval(
        child: Image.file(
          File(state.localImagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return ProfileAvatar(
      photoUrl: state.removePhoto ? null : state.photoUrl,
      displayName: state.displayName,
      size: size,
    );
  }
}
