import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../helpers/reciter_helper.dart';
import '../../router/app_router_config.dart';
import '../models/reciter_model.dart';

class ViewReciterButton extends StatelessWidget {
  const ViewReciterButton({super.key, required this.mediaItem});
  final MediaItem mediaItem;

  @override
  Widget build(BuildContext context) {
    Future<void> navigateToReciterDetails(
      BuildContext context,
      MediaItem mediaItem,
    ) async {
      try {
        final Reciter? reciter = await ReciterHelper.getReciterFromMediaItem(
          mediaItem,
        );
        if (reciter != null && context.mounted) {
          // Use GoRouter to navigate to reciter details
          await ReciterDetailsRoute(
            reciterId: reciter.id.toString(),
            reciter: reciter,
          ).push(context);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reciter information not available'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading reciter: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12),
      child: TextButton.icon(
        icon: const Icon(FluentIcons.person_24_regular, size: 18),
        label: Text('${mediaItem.artist}'),
        onPressed: () => navigateToReciterDetails(context, mediaItem),
      ),
    );
  }
}
