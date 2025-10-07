import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/widgets/reciter_downloads_section.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.downloads),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showClearAllDialog(context);
            },
          ),
        ],
      ),
      body: BlocListener<DownloadsBloc, DownloadsState>(
        listener: (context, state) {
          // Handle states that should show snackbars or other UI feedback
          if (state is PlaybackInitiated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is DownloadsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: BlocBuilder<DownloadsBloc, DownloadsState>(
          builder: (context, state) {
            return state.when(
              initial: () => Center(
                child: Text(AppLocalizations.of(context)!.noDownloadsYet),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (downloadsByReciter) {
                if (downloadsByReciter.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noDownloadsYet,
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: downloadsByReciter.length,
                  itemBuilder: (context, index) {
                    final reciterName = downloadsByReciter.keys.elementAt(
                      index,
                    );
                    final downloads = downloadsByReciter[reciterName] ?? [];

                    return ReciterDownloadsSection(
                      reciterName: reciterName,
                      downloads: downloads,
                    );
                  },
                );
              },
              error: (message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${AppLocalizations.of(context)!.error}: $message',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DownloadsBloc>().add(
                          const LoadDownloads(),
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
              // Handle new states - these are typically handled by BlocListener
              surahDownloadStatus: (surahId, reciterName, isDownloaded) =>
                  Center(
                    child: Text(
                      AppLocalizations.of(context)!.downloadStatusChecked,
                    ),
                  ),
              fileValidationResult: (downloadId, isValid) => Center(
                child: Text(
                  AppLocalizations.of(context)!.fileValidationCompleted,
                ),
              ),
              validDownloadsLoaded: (reciterName, validDownloads) => Center(
                child: Text(AppLocalizations.of(context)!.validDownloadsLoaded),
              ),
              playbackInitiated: (message) => Center(
                child: Text(AppLocalizations.of(context)!.playbackInitiated),
              ),
              premiumRequired: (String message) {
                return Center(child: Text(message));
              },
            );
          },
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearAllDownloads),
        content: Text(AppLocalizations.of(context)!.clearAllDownloadsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DownloadsBloc>().add(const ClearAllDownloads());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteAll),
          ),
        ],
      ),
    );
  }
}
