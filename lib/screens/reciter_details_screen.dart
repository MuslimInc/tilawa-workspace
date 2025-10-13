import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/core/di/injection.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/presentation/widgets/download_button.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:muzakri/features/surah/domain/entities/surah.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/shared/widgets/bottom_player.dart';

class ReciterDetailsScreen extends StatefulWidget {
  final Reciter reciter;

  const ReciterDetailsScreen({super.key, required this.reciter});

  @override
  State<ReciterDetailsScreen> createState() => _ReciterDetailsScreenState();
}

class _ReciterDetailsScreenState extends State<ReciterDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final selectedMoshaf = widget.reciter.moshaf.first;
    context.read<ReciterDetailsBloc>().add(
      LoadSurahList(reciter: widget.reciter, moshaf: selectedMoshaf),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReciterDetailsBloc, ReciterDetailsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.reciter.name),
            actions: [
              if (state is ReciterDetailsLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Moshaf selector
              if (widget.reciter.moshaf.length > 1)
                Builder(
                  builder: (context) {
                    // Remove duplicates and get unique moshaf list
                    final uniqueMoshaf = widget.reciter.moshaf.toSet().toList();
                    final selectedMoshaf = state is ReciterDetailsLoaded
                        ? state.selectedMoshaf
                        : uniqueMoshaf.first;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<Mosahf>(
                        initialValue: uniqueMoshaf.contains(selectedMoshaf)
                            ? selectedMoshaf
                            : uniqueMoshaf.first,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.selectRecitation,
                          border: const OutlineInputBorder(),
                        ),
                        items: uniqueMoshaf.map((moshaf) {
                          return DropdownMenuItem<Mosahf>(
                            value: moshaf,
                            child: Text(moshaf.name),
                          );
                        }).toList(),
                        onChanged: (Mosahf? moshaf) {
                          if (moshaf != null) {
                            context.read<ReciterDetailsBloc>().add(
                              LoadSurahList(
                                reciter: widget.reciter,
                                moshaf: moshaf,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),

              // Content
              Expanded(
                child: state is ReciterDetailsLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading surah list...'),
                          ],
                        ),
                      )
                    : state is ReciterDetailsError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(state.message),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<ReciterDetailsBloc>().add(
                                  LoadSurahList(
                                    reciter: widget.reciter,
                                    moshaf: widget.reciter.moshaf.first,
                                  ),
                                );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : state is ReciterDetailsLoaded && state.surahList.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noSurahsAvailable,
                        ),
                      )
                    : BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                        builder: (context, audioState) {
                          return state is ReciterDetailsLoaded
                              ? ListView.builder(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  itemCount: state.surahList.length,
                                  itemBuilder: (context, index) {
                                    final surah = state.surahList[index];
                                    return _buildSurahCard(surah, index, state);
                                  },
                                )
                              : const SizedBox.shrink();
                        },
                      ),
              ),
            ],
          ),
          bottomNavigationBar: BottomPlayer(),
        );
      },
    );
  }

  Widget _buildSurahCard(Surah surah, int index, ReciterDetailsLoaded state) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, audioState) {
        if (audioState.status != AudioPlayerStatus.success) {
          // Return basic card without highlighting
          var roundedRectangleBorder = RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          );
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: roundedRectangleBorder,
            elevation: 0,
            child: ListTile(
              shape: roundedRectangleBorder,
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                surah.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                surah.reciterName,
                style: const TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  // Play surah logic here
                },
              ),
              onTap: () {
                // Play surah logic here
              },
            ),
          );
        }

        final currentMediaItem = audioState.mediaItem;
        final playbackState = audioState.playbackState;
        // Highlight if the surah is selected (clicked) or currently playing
        // final isSelected = state.selectedSurahId == surah.id;
        final isCurrentlyPlaying = currentMediaItem?.id == surah.id;

        var roundedRectangleBorder = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        );
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isCurrentlyPlaying
              ? Colors.purple.withValues(alpha: 0.1)
              : null,
          shape: roundedRectangleBorder,
          elevation: 0,
          child: ListTile(
            shape: roundedRectangleBorder,
            leading: CircleAvatar(
              backgroundColor: isCurrentlyPlaying
                  ? Colors.purple
                  : Theme.of(context).primaryColor,
              child: isCurrentlyPlaying
                  ? const Icon(Icons.music_note, color: Colors.white, size: 20)
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(
              surah.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCurrentlyPlaying ? Colors.purple[800] : null,
              ),
            ),
            subtitle: Text(
              surah.reciterName,
              style: TextStyle(
                color: isCurrentlyPlaying ? Colors.purple[600] : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Download status indicator
                FutureBuilder<bool>(
                  future: _isSurahDownloaded(surah),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return const Icon(
                        Icons.download_done,
                        color: Colors.green,
                        size: 20,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(width: 4),
                // Download button
                DownloadButton(
                  surahId: surah.id,
                  surahTitle: surah.name,
                  reciterName: widget.reciter.name,
                  url: surah.url,
                ),
                const SizedBox(width: 8),
                // Play button
                isCurrentlyPlaying
                    ? IconButton(
                        icon: Icon(
                          playbackState?.playing == true
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.purple,
                        ),
                        onPressed: () {
                          if (playbackState?.playing == true) {
                            context.read<AudioPlayerBloc>().add(
                              const AudioPlayerEvent.pauseAudio(),
                            );
                          } else {
                            context.read<AudioPlayerBloc>().add(
                              const AudioPlayerEvent.playAudio(),
                            );
                          }
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          _playSurah(surah, state);
                        },
                      ),
              ],
            ),
            onTap: () {
              if (isCurrentlyPlaying) {
                // Toggle play/pause if this is the current surah
                if (playbackState?.playing == true) {
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.pauseAudio(),
                  );
                } else {
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.playAudio(),
                  );
                }
              } else {
                // Play this surah
                _playSurah(surah, state);
              }
            },
          ),
        );
      },
    );
  }

  /// Check if a surah is downloaded and get its file path
  Future<String?> _getDownloadedFilePath(Surah surah) async {
    try {
      final downloadsRepository = getIt<DownloadsRepository>();
      // Extract surah ID from the title (assuming format like "001 Al-Fatiha")
      final surahId = surah.name.split(' ').first;
      final filePath = await downloadsRepository.getDownloadedFilePath(
        surahId,
        widget.reciter.name,
      );

      if (filePath != null) {
        // Validate that the file actually exists
        final file = File(filePath);
        if (await file.exists()) {
          print('_getDownloadedFilePath: file exists at $filePath');
          return filePath;
        } else {
          print('_getDownloadedFilePath: file does not exist at $filePath');
          return null;
        }
      }

      return null;
    } catch (e) {
      print('Error checking downloaded file: $e');
      return null;
    }
  }

  /// Check if a surah is downloaded
  Future<bool> _isSurahDownloaded(Surah surah) async {
    try {
      final downloadsRepository = getIt<DownloadsRepository>();
      // Extract surah ID from the title (assuming format like "001 Al-Fatiha")
      final surahId = surah.name.split(' ').first;
      return await downloadsRepository.isSurahDownloaded(
        surahId,
        widget.reciter.name,
      );
    } catch (e) {
      print('Error checking if surah is downloaded: $e');
      return false;
    }
  }

  /// Create a MediaItem with local file path for downloaded surahs
  MediaItem _createLocalMediaItem(Surah originalSurah, String filePath) {
    try {
      // Convert file path to proper file:// URI
      final fileUri = Uri.file(filePath).toString();

      print('_createLocalMediaItem: original file path: $filePath');
      print('_createLocalMediaItem: file URI: $fileUri');

      return MediaItem(
        id: fileUri, // Use file URI as ID for local files
        title: originalSurah.name,
        artist: originalSurah.reciterName,
        album: originalSurah.reciterName,
        duration: originalSurah.mediaItem.duration,
        artUri: originalSurah.mediaItem.artUri,
        extras: {
          ...?originalSurah.mediaItem.extras,
          'isDownloaded': true,
          'originalId': originalSurah.id, // Keep original ID for reference
          'localFilePath': filePath, // Keep original file path for reference
        },
      );
    } catch (e) {
      print('_createLocalMediaItem error: $e');
      print('_createLocalMediaItem: falling back to original surah');
      // Fallback to original surah if file URI creation fails
      return originalSurah.mediaItem;
    }
  }

  Future<void> _playSurah(Surah surah, ReciterDetailsLoaded state) async {
    try {
      // Check if the surah is downloaded
      final downloadedFilePath = await _getDownloadedFilePath(surah);

      // Set the selected surah immediately for instant highlighting
      if (mounted) {
        context.read<ReciterDetailsBloc>().add(SelectSurah(surah.id));
      }

      final audioHandler = getIt<AudioPlayerHandler>();

      // Validate surah data
      if (surah.id.isEmpty) {
        throw Exception('Invalid surah: missing ID');
      }

      // Find the index of the selected surah in the full list
      final surahIndex = state.surahList.indexWhere(
        (item) => item.id == surah.id,
      );

      print(
        '_playSurah: selected surah=${surah.name}, index=$surahIndex, total surahs=${state.surahList.length}',
      );
      print('_playSurah: downloaded file path: $downloadedFilePath');

      if (downloadedFilePath != null) {
        final fileUri = Uri.file(downloadedFilePath).toString();
        print('_playSurah: file URI: $fileUri');
      }

      if (surahIndex != -1) {
        // Create a list of surahs, using downloaded files when available
        final List<MediaItem> surahListWithDownloads = [];
        for (int i = 0; i < state.surahList.length; i++) {
          final currentSurah = state.surahList[i];
          if (i == surahIndex && downloadedFilePath != null) {
            // Use downloaded file for the selected surah
            surahListWithDownloads.add(
              _createLocalMediaItem(currentSurah, downloadedFilePath),
            );
          } else {
            // Check if this surah is also downloaded
            final otherDownloadedPath = await _getDownloadedFilePath(
              currentSurah,
            );
            if (otherDownloadedPath != null) {
              surahListWithDownloads.add(
                _createLocalMediaItem(currentSurah, otherDownloadedPath),
              );
            } else {
              surahListWithDownloads.add(currentSurah.mediaItem);
            }
          }
        }

        // Update queue with the surah list (with downloaded files where available)
        print(
          '_playSurah: updating queue with ${surahListWithDownloads.length} surahs',
        );

        try {
          await audioHandler.updateQueue(surahListWithDownloads);

          // Ensure we're paused before seeking to prevent unwanted playback
          await audioHandler.pause();

          // Skip to the selected surah
          print('_playSurah: skipping to surah at index $surahIndex');
          await audioHandler.skipToQueueItem(surahIndex);

          // Now start playing the selected surah
          await audioHandler.play();
        } catch (e) {
          print(
            '_playSurah: error playing with downloaded files, falling back to streaming',
          );
          // Fallback to original surah list if downloaded files fail
          await audioHandler.updateQueue(
            state.surahList.map((s) => s.mediaItem).toList(),
          );
          await audioHandler.pause();
          await audioHandler.skipToQueueItem(surahIndex);
          await audioHandler.play();
        }
      } else {
        // Fallback: just play the single surah
        print('_playSurah: surah not found in list, playing single surah');
        final surahToPlay = downloadedFilePath != null
            ? _createLocalMediaItem(surah, downloadedFilePath)
            : surah.mediaItem;

        try {
          await audioHandler.updateQueue([surahToPlay]);
          await audioHandler.pause();
          await audioHandler.skipToQueueItem(0);
          await audioHandler.play();
        } catch (e) {
          print(
            '_playSurah: error playing single downloaded surah, falling back to streaming',
          );
          // Fallback to original surah if downloaded file fails
          await audioHandler.updateQueue([surah.mediaItem]);
          await audioHandler.pause();
          await audioHandler.skipToQueueItem(0);
          await audioHandler.play();
        }
      }
    } catch (e, stackTrace) {
      print('_playSurah error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing surah: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
