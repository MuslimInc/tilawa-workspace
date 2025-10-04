import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/bloc/reciter_details/reciter_details_bloc.dart';
import 'package:muzakri/bloc/reciters/reciters_bloc.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/widgets/app_with_bottom_player.dart';
import 'package:muzakri/widgets/arabic_alphabet_scrollbar.dart';
import 'package:muzakri/widgets/language_switcher.dart';
import 'package:rxdart/rxdart.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<RecitersBloc>().add(const LoadReciters());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLetterSelected(String letter) {
    context.read<RecitersBloc>().add(FilterByLetter(letter));
    _searchController.clear();
  }

  void _clearLetterFilter() {
    context.read<RecitersBloc>().add(const ClearLetterFilter());
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecitersBloc, RecitersState>(
      builder: (context, state) {
        return AppWithBottomPlayer(
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.reciters),
              actions: const [LanguageSwitcher(), SizedBox(width: 8)],
            ),
            body: Column(
              children: [
                // Search bar and letter filter
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Letter filter indicator
                      if (state is RecitersLoaded &&
                          state.selectedLetter != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.filteredByLetter,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                state.selectedLetter!,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _clearLetterFilter,
                                color: Theme.of(context).primaryColor,
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                      // Search field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchReciters,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              (state is RecitersLoaded &&
                                  state.searchQuery.isNotEmpty)
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<RecitersBloc>().add(
                                      const ClearSearch(),
                                    );
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          context.read<RecitersBloc>().add(
                            SearchReciters(value),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main content
                      Expanded(
                        child: state is RecitersLoading
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.loadingReciters,
                                    ),
                                  ],
                                ),
                              )
                            : state is RecitersError
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      size: 64,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(state.message),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<RecitersBloc>().add(
                                          const LoadReciters(),
                                        );
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.retry,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : state is RecitersLoaded &&
                                  state.filteredReciters.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.searchQuery.isEmpty
                                          ? AppLocalizations.of(
                                              context,
                                            )!.noRecitersFound
                                          : AppLocalizations.of(
                                              context,
                                            )!.noRecitersMatchSearch,
                                    ),
                                  ],
                                ),
                              )
                            : state is RecitersLoaded
                            ? ListView.builder(
                                controller: _scrollController,
                                itemCount: state.filteredReciters.length,
                                itemBuilder: (context, index) {
                                  final reciter = state.filteredReciters[index];
                                  return _buildReciterCard(reciter);
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      // Arabic alphabet scrollbar
                      if (state is RecitersLoaded &&
                          state.reciters.isNotEmpty &&
                          state.searchQuery.isEmpty)
                        ReciterAlphabetScrollbar(
                          reciters: state
                              .reciters, // Use full list for alphabet generation
                          scrollController: _scrollController,
                          onLetterSelected: _onLetterSelected,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReciterCard(Reciter reciter) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            reciter.letter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          reciter.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${reciter.moshaf.length} recitation(s) available'),
            if (reciter.moshaf.isNotEmpty)
              Text(
                reciter.moshaf.first.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.pushNamed(
            'reciterDetails',
            pathParameters: {'reciterId': reciter.id.toString()},
            extra: reciter,
          );
        },
      ),
    );
  }
}

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
                      : StreamBuilder<MediaItem?>(
                          stream: globalAudioHandler.mediaItem,
                          builder: (context, snapshot) {
                            final hasAudio = snapshot.data != null;
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
    return StreamBuilder<Map<String, dynamic>>(
      stream:
          Rx.combineLatest2<MediaItem?, PlaybackState, Map<String, dynamic>>(
            globalAudioHandler.mediaItem,
            globalAudioHandler.playbackState,
            (mediaItem, playbackState) => {
              'mediaItem': mediaItem,
              'playbackState': playbackState,
            },
          ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final currentMediaItem = data?['mediaItem'] as MediaItem?;
        final playbackState = data?['playbackState'] as PlaybackState?;
        // Highlight if the surah is selected (clicked) or currently playing
        final isSelected = state.selectedSurahId == surah.id;
        final isCurrentlyPlaying =
            currentMediaItem?.id == surah.id &&
            (playbackState?.playing ?? false);
        final shouldHighlight = isSelected || isCurrentlyPlaying;

        var roundedRectangleBorder = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        );
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: shouldHighlight ? Colors.purple.withValues(alpha: 0.1) : null,
          shape: roundedRectangleBorder,
          elevation: 0,
          child: ListTile(
            shape: roundedRectangleBorder,
            leading: CircleAvatar(
              backgroundColor: shouldHighlight
                  ? Colors.purple
                  : Theme.of(context).primaryColor,
              child: shouldHighlight
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
                color: shouldHighlight ? Colors.purple[800] : null,
              ),
            ),
            subtitle: Text(
              surah.album ?? '',
              style: TextStyle(
                color: shouldHighlight ? Colors.purple[600] : null,
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
                        globalAudioHandler.pause();
                      } else {
                        globalAudioHandler.play();
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
                  globalAudioHandler.pause();
                } else {
                  globalAudioHandler.play();
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
    } catch (e) {
      print('_playSurah error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing surah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
