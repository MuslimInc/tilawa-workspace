import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import '../../helpers/reciter_helper.dart';
import '../../router/app_router_config.dart';

class ViewReciterButton extends StatelessWidget {
  const ViewReciterButton({super.key, required this.audio});
  final AudioEntity audio;

  @override
  Widget build(BuildContext context) {
    Future<void> navigateToReciterDetails(
      BuildContext context,
      AudioEntity audio,
    ) async {
      try {
        final ReciterEntity? reciter =
            await ReciterHelper.getReciterFromAudioEntity(audio);
        if (reciter != null && context.mounted) {
          // Use GoRouter to navigate to reciter details
          await ReciterDetailsRoute(
            reciterId: reciter.id.toString(),
            $extra: reciter,
          ).push(context);
        } else {
          if (context.mounted) {
            ToastUtils.showToast(msg: context.l10n.reciterInfoNotAvailable);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ToastUtils.showErrorToast(
            context.l10n.errorLoadingReciter(e.toString()),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12),
      child: TextButton.icon(
        icon: const Icon(FluentIcons.person_24_regular, size: 18),
        label: Text('${audio.artist}'),
        onPressed: () => navigateToReciterDetails(context, audio),
      ),
    );
  }
}
