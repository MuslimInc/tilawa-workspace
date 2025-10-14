import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/premium/presentation/widgets/premium_upgrade_dialog.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';
import 'package:muzakri/features/surah/presentation/bloc/surah_bloc.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router.dart';

class SurahDownloadButton extends StatefulWidget {
  const SurahDownloadButton({super.key, required this.surah});

  final SurahEntity surah;

  @override
  State<SurahDownloadButton> createState() => _SurahDownloadButtonState();
}

class _SurahDownloadButtonState extends State<SurahDownloadButton> {
  @override
  void initState() {
    super.initState();
    // Check download status when button is created
    context.read<SurahBloc>().add(
      SurahEvent.checkSurahDownloadStatus(
        surahId: widget.surah.id,
        reciterName: widget.surah.reciterName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadsBloc, DownloadsState>(
      listener: (context, state) {
        if (state is DownloadStarted &&
            state.surahId == widget.surah.id &&
            state.reciterName == widget.surah.reciterName) {
          // Update surah to show downloading state
          context.read<SurahBloc>().add(
            SurahEvent.updateSurahDownloadProgress(
              surahId: widget.surah.id,
              reciterName: widget.surah.reciterName,
              isDownloading: true,
              progress: 0.0,
              downloadId: '${widget.surah.id}_${widget.surah.reciterName}',
            ),
          );
        } else if (state is DownloadsLoaded) {
          // Refresh surah status when downloads are loaded
          context.read<SurahBloc>().add(
            SurahEvent.refreshSurahStatus(
              surahId: widget.surah.id,
              reciterName: widget.surah.reciterName,
            ),
          );
        } else if (state is DownloadsError) {
          // Check if this error is related to our surah
          if (state.message.contains(widget.surah.name) &&
              state.message.contains(widget.surah.reciterName)) {
            // Reset downloading state on error
            context.read<SurahBloc>().add(
              SurahEvent.updateSurahDownloadProgress(
                surahId: widget.surah.id,
                reciterName: widget.surah.reciterName,
                isDownloading: false,
                progress: 0.0,
              ),
            );
          }
        } else if (state is PremiumRequired) {
          // Show premium upgrade dialog
          _showPremiumUpgradeDialog(context, state.message);
        }
      },
      child: BlocBuilder<SurahBloc, SurahState>(
        builder: (context, state) {
          // Get the current surah state
          SurahEntity currentSurah = widget.surah;

          if (state is SurahUpdated && state.surah.id == widget.surah.id) {
            currentSurah = state.surah;
          }

          return _buildButton(currentSurah);
        },
      ),
    );
  }

  Widget _buildButton(SurahEntity surah) {
    // Hide the button completely if already downloaded
    if (surah.isDownloaded) {
      return const SizedBox.shrink();
    }

    if (surah.isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (surah.downloadProgress > 0)
            Text(
              '${(surah.downloadProgress * 100).toInt()}%',
              style: const TextStyle(fontSize: 8),
            ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      tooltip: AppLocalizations.of(context)!.download,
      onPressed: () => _downloadSurah(surah),
    );
  }

  void _downloadSurah(SurahEntity surah) {
    context.read<DownloadsBloc>().add(
      DownloadSurahEvent(
        surahId: surah.id,
        surahTitle: surah.name,
        reciterName: surah.reciterName,
      ),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${surah.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPremiumUpgradeDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        title: 'Premium Required',
        message: message,
        onUpgrade: () {
          context.push(AppRouter.premium);
        },
      ),
    );
  }
}
