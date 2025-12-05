import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../premium/presentation/widgets/premium_upgrade_dialog.dart';
import '../bloc/downloads_bloc.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.surahId,
    required this.surahTitle,
    required this.reciterName,
    this.isDownloaded = false,
    this.isDownloading = false,
  });

  final String surahId;
  final String surahTitle;
  final String reciterName;
  final bool isDownloaded;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    void downloadSurah() {
      if (isDownloaded) {
        return;
      }

      context.read<DownloadsBloc>().add(
        DownloadSurahEvent(
          surahId: surahId,
          surahTitle: surahTitle,
          reciterName: reciterName,
        ),
      );
    }

    Widget buildButton() {
      if (isDownloading) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      // Hide the button completely if already downloaded or currently downloading
      if (isDownloaded) {
        return const SizedBox.shrink();
      }

      return IconButton(
        icon: const Icon(Icons.download),
        tooltip: AppLocalizations.of(context)!.download,
        onPressed: isDownloaded ? null : downloadSurah,
      );
    }

    void showPremiumUpgradeDialog(BuildContext context, String message) {
      showDialog(
        context: context,
        builder: (context) => PremiumUpgradeDialog(
          title: 'Premium Required',
          message: message,
          onUpgrade: () {
            const PremiumRoute().push(context);
          },
        ),
      );
    }

    return BlocListener<DownloadsBloc, DownloadsState>(
      listener: (context, state) {
        if (state is SurahDownloadStatus &&
            state.surahId == surahId &&
            state.reciterName == reciterName) {
        } else if (state is DownloadStarted &&
            state.surahId == surahId &&
            state.reciterName == reciterName) {
        } else if (state is DownloadsLoaded) {
        } else if (state is DownloadsError) {
        } else if (state is PremiumRequired) {
          // Show premium upgrade dialog
          showPremiumUpgradeDialog(context, state.message);
        }
      },
      child: buildButton(),
    );
  }
}
