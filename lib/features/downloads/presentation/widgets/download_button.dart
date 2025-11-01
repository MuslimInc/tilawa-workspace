import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/premium/presentation/widgets/premium_upgrade_dialog.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router_config.dart';

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
      if (isDownloaded) return;

      context.read<DownloadsBloc>().add(
        DownloadSurahEvent(
          surahId: surahId,
          surahTitle: surahTitle,
          reciterName: reciterName,
        ),
      );

      // Show success message with View Downloads action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $surahTitle...'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.viewDownloads,
            onPressed: () {
              const DownloadsRoute().push(context);
            },
          ),
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
