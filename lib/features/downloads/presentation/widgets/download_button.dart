import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../premium/presentation/widgets/premium_upgrade_dialog.dart';
import '../../domain/entities/download_item.dart';
import '../bloc/downloads_bloc.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.surahId,
    required this.surahTitle,
    required this.reciterName,
  });

  final String surahId;
  final String surahTitle;
  final String reciterName;

  void _downloadSurah(BuildContext context) {
    context.read<DownloadsBloc>().add(
      DownloadSurahEvent(
        surahId: surahId,
        surahTitle: surahTitle,
        reciterName: reciterName,
      ),
    );

    ToastUtils.showToast(msg: 'Downloading $surahTitle...');
  }

  void _showPremiumUpgradeDialog(BuildContext context, String message) {
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

  DownloadItem? _getDownloadItem(DownloadsState state) {
    final Map<String, List<DownloadItem>>? downloadsByReciter = state.maybeMap(
      loaded: (s) => s.downloadsByReciter,
      downloadStarted: (s) => s.downloadsByReciter,
      premiumRequired: (s) => s.downloadsByReciter,
      playbackInitiated: (s) => s.downloadsByReciter,
      orElse: () => null,
    );

    if (downloadsByReciter != null) {
      final List<DownloadItem> downloads =
          downloadsByReciter[reciterName] ?? [];

      // Construct the expected composite ID: URL_ReciterName
      final expectedId = '${surahId}_${reciterName.replaceAll(' ', '_')}';

      try {
        return downloads.firstWhere((download) => download.id == expectedId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadsBloc, DownloadsState>(
      listener: (context, state) {
        if (state is PremiumRequired) {
          _showPremiumUpgradeDialog(context, state.message);
        }
      },
      child: BlocBuilder<DownloadsBloc, DownloadsState>(
        builder: (context, state) {
          // Check for download item in loaded state
          final DownloadItem? downloadItem = _getDownloadItem(state);

          final bool isDownloading =
              (downloadItem?.status == DownloadStatus.downloading) ||
              (downloadItem?.status == DownloadStatus.pending);
          final isDownloaded = downloadItem?.status == DownloadStatus.completed;
          final double progress = downloadItem?.progress ?? 0.0;

          if (isDownloaded) {
            return IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: AppLocalizations.of(context)!.downloaded,
              onPressed: null, // Or logic to delete/play
            );
          }

          if (isDownloading) {
            return SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progress > 0
                          ? progress
                          : null, // Indeterminate if 0
                      strokeWidth: 2,
                    ),
                  ),
                  if (progress > 0)
                    Text(
                      '${(progress * 100).toInt()}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            );
          }

          return IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: AppLocalizations.of(context)!.download,
            onPressed: () => _downloadSurah(context),
          );
        },
      ),
    );
  }
}
