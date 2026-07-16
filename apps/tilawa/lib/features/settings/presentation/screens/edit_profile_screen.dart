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
        body: const SizedBox.shrink(),
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

  Future<void> _showPhotoActions(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<EditProfileCubit>();
    final bool hasPhoto = cubit.state.hasPhoto;

    await showTilawaModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: sheetContext.floatingBottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TilawaSheetHandle(),
              ListTile(
                leading: const Icon(FluentIcons.image_24_regular),
                title: Text(l10n.gallery),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(cubit.pickImage(ImageSource.gallery));
                },
              ),
              ListTile(
                leading: const Icon(FluentIcons.camera_24_regular),
                title: Text(l10n.camera),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(cubit.pickImage(ImageSource.camera));
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: Icon(
                    FluentIcons.delete_24_regular,
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                  title: Text(l10n.editProfileRemovePhoto),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    cubit.removePhoto();
                  },
                ),
              Padding(
                padding: TilawaBottomSheetScaffold.resolvedBodyPadding(
                  sheetContext,
                ),
                child: TilawaButton(
                  text: l10n.cancel,
                  variant: TilawaButtonVariant.ghost,
                  isFullWidth: true,
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          final String message = state.errorMessage == 'avatarTooLarge'
              ? l10n.editProfileAvatarTooLarge
              : l10n.editProfileSaveFailed;
          TilawaFeedback.showToast(
            context,
            message: message,
            variant: TilawaFeedbackVariant.error,
          );
        }
      },
      builder: (context, state) {
        final bool saving = state.status == EditProfileStatus.saving;
        final cubit = context.read<EditProfileCubit>();

        return TilawaShellChildScaffold(
          appBar: TilawaAppBar(title: l10n.editProfileTitle),
          body: ListView(
            padding: EdgeInsets.all(tokens.spaceLarge),
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: saving
                          ? null
                          : () => unawaited(_showPhotoActions(context)),
                      child: _EditProfileAvatar(state: state),
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
                errorText: state.nameError
                    ? l10n.editProfileDisplayNameRequired
                    : null,
              ),
              SizedBox(height: tokens.spaceExtraLarge),
              TilawaButton(
                text: l10n.save,
                isLoading: saving,
                onPressed: saving
                    ? null
                    : () => unawaited(cubit.save(widget.user)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditProfileAvatar extends StatelessWidget {
  const _EditProfileAvatar({required this.state});

  final EditProfileState state;

  @override
  Widget build(BuildContext context) {
    const double size = 96;
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
