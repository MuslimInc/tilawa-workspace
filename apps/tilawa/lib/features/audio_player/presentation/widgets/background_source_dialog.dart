import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/player_background_configuration.dart';
import '../cubit/player_background_cubit.dart';
import '../cubit/player_background_state.dart';

class BackgroundSourceDialog extends StatelessWidget {
  const BackgroundSourceDialog({super.key, required this.onSourceSelected});

  final ValueChanged<ImageSource> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return AlertDialog(
      title: Text(
        context.l10n.chooseBackgroundSource,
        style: context.textTheme.titleLarge,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SourceOption(
            icon: FluentIcons.image_24_regular,
            label: context.l10n.gallery,
            onTap: () {
              Navigator.pop(context);
              onSourceSelected(ImageSource.gallery);
            },
          ),
          SizedBox(height: tokens.spaceSmall),
          _SourceOption(
            icon: FluentIcons.camera_24_regular,
            label: context.l10n.camera,
            onTap: () {
              Navigator.pop(context);
              onSourceSelected(ImageSource.camera);
            },
          ),
          BlocBuilder<PlayerBackgroundCubit, PlayerBackgroundState>(
            builder: (context, state) {
              if (state.config.type == PlayerBackgroundType.defaultType) {
                return const SizedBox.shrink();
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  _SourceOption(
                    icon: FluentIcons.delete_24_regular,
                    label: context.l10n.resetToDefault,
                    onTap: () {
                      Navigator.pop(context);
                      context.read<PlayerBackgroundCubit>().resetToDefault();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.close),
        ),
      ],
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      onTap: onTap,
    );
  }
}
