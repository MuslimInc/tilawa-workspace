import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/bloc/audio_player/audio_player_bloc.dart';
import 'package:muzakri/bloc/reciter_details/reciter_details_bloc.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/widgets/app_with_bottom_player.dart';

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
        return AppWithBottomPlayer(
          child: Scaffold(
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
                      final uniqueMoshaf = widget.reciter.moshaf
                          .toSet()
                          .toList();
                      final selectedMoshaf = state is ReciterDetailsLoaded
                          ? state.selectedMoshaf
                          : uniqueMoshaf.first;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButtonFormField<Mosahf>(
                          initialValue: uniqueMoshaf.contains(selectedMoshaf)
                              ? selectedMoshaf
                              : uniqueMoshaf.first,
                          decoration: const InputDecoration(
                            labelText: 'Select Recitation',
                            border: OutlineInputBorder(),
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
                      ? const Center(child: Text('No surahs available'))
                      : BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                          builder: (context, audioState) {
                            final hasAudio =
                                audioState.status ==
                                    AudioPlayerStatus.success &&
                                audioState.mediaItem != null;
                            // Calculate dynamic padding based on screen size and bottom player visibility
                            final screenHeight = MediaQuery.of(
                              context,
                            ).size.height;
                            final bottomPadding = hasAudio
                                ? (screenHeight * 0.20).clamp(
                                    80.0,
                                    200.0,
                                  ) // 20% of screen height, min 80px, max 200px
                                : 0.0;

                            return state is ReciterDetailsLoaded
                                ? ListView.builder(
                                    padding: EdgeInsets.only(
                                      bottom: bottomPadding,
                                    ),
                                    itemCount: state.surahList.length,
                                    itemBuilder: (context, index) {
                                      final surah = state.surahList[index];
                                      return _buildSurahCard(
                                        surah,
                                        index,
                                        state,
                                      );
                                    },
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahCard(
    MediaItem surah,
    int index,
    ReciterDetailsLoaded state,
  ) {
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
                surah.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                surah.artist ?? '',
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
        final isCurrentlyPlaying =
            currentMediaItem?.id == surah.id &&
            (playbackState?.playing ?? false);

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
              surah.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCurrentlyPlaying ? Colors.purple[800] : null,
              ),
            ),
            subtitle: Text(
              surah.album ?? '',
              style: TextStyle(
                color: isCurrentlyPlaying ? Colors.purple[600] : null,
              ),
            ),
            trailing: isCurrentlyPlaying
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

  Future<void> _playSurah(MediaItem surah, ReciterDetailsLoaded state) async {
    try {
      // Set the selected surah immediately for instant highlighting
      context.read<ReciterDetailsBloc>().add(SelectSurah(surah.id));

      final audioHandler = getIt<AudioPlayerHandlerImpl>();

      // Validate surah data
      if (surah.id.isEmpty) {
        throw Exception('Invalid surah: missing ID');
      }

      // Find the index of the selected surah in the full list
      final surahIndex = state.surahList.indexWhere(
        (item) => item.id == surah.id,
      );

      print(
        '_playSurah: selected surah=${surah.title}, index=$surahIndex, total surahs=${state.surahList.length}',
      );

      if (surahIndex != -1) {
        // Update queue with the entire surah list
        print(
          '_playSurah: updating queue with ${state.surahList.length} surahs',
        );
        await audioHandler.updateQueue(state.surahList);

        // Ensure we're paused before seeking to prevent unwanted playback
        await audioHandler.pause();

        // Skip to the selected surah
        print('_playSurah: skipping to surah at index $surahIndex');
        await audioHandler.skipToQueueItem(surahIndex);

        // Now start playing the selected surah
        await audioHandler.play();
      } else {
        // Fallback: just play the single surah
        print('_playSurah: surah not found in list, playing single surah');
        await audioHandler.updateQueue([surah]);
        await audioHandler.pause();
        await audioHandler.skipToQueueItem(0);
        await audioHandler.play();
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
