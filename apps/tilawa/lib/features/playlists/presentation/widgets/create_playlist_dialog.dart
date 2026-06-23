import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/playlists_bloc.dart';

class CreatePlaylistDialog extends StatefulWidget {
  const CreatePlaylistDialog({super.key});

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final tokens = Theme.of(context).tokens;

    return BlocListener<PlaylistsBloc, PlaylistsState>(
      listener: (context, state) {
        state.whenOrNull(
          playlistCreated: (playlist, playlists) {
            Navigator.of(context).pop();
            TilawaFeedback.showToast(
              context,
              message: l10n.playlistCreated,
              variant: TilawaFeedbackVariant.success,
            );
          },
          error: (message) {
            TilawaFeedback.showToast(
              context,
              message: message,
              variant: TilawaFeedbackVariant.error,
            );
          },
        );
      },
      child: AlertDialog(
        title: Text(l10n.createNewPlaylist),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TilawaTextField(
                controller: _nameController,
                label: l10n.playlistName,
                hintText: l10n.playlistNameHint,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.playlistNameRequired;
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: tokens.spaceLarge),
              TilawaTextField(
                controller: _descriptionController,
                label: l10n.playlistDescription,
                hintText: l10n.playlistDescriptionHint,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.playlistDescriptionRequired;
                  }
                  return null;
                },
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: tokens.spaceLarge),
              SwitchListTile(
                title: Text(l10n.public),
                subtitle: Text(l10n.private),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TilawaButton(
            text: l10n.cancel,
            variant: TilawaButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          BlocBuilder<PlaylistsBloc, PlaylistsState>(
            builder: (context, state) {
              final isLoading = state is PlaylistsLoading;
              return TilawaButton(
                text: l10n.save,
                variant: TilawaButtonVariant.primary,
                isLoading: isLoading,
                onPressed: isLoading ? null : _createPlaylist,
              );
            },
          ),
        ],
      ),
    );
  }

  void _createPlaylist() {
    if (_formKey.currentState!.validate()) {
      context.read<PlaylistsBloc>().add(
        CreatePlaylistEvent(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isPublic: _isPublic,
        ),
      );
    }
  }
}
