import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/widgets/app_with_bottom_player.dart';
import 'package:rxdart/rxdart.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  List<Reciter> _reciters = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReciters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReciters() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final audioHandler = getIt<AudioPlayerHandlerImpl>();
      final recitersData = await audioHandler.getRecitersData();

      if (recitersData != null) {
        setState(() {
          _reciters = recitersData;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load reciters';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading reciters: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Reciter> get _filteredReciters {
    if (_searchQuery.isEmpty) return _reciters;

    return _reciters.where((reciter) {
      return reciter.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          reciter.letter.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppWithBottomPlayer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quran Reciters'),
          actions: [
            if (_isLoading)
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
            // Welcome section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.library_music,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to Muzakri',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a reciter to start listening to the Holy Quran',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search reciters...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading reciters...'),
                        ],
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadReciters,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _filteredReciters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No reciters found'
                                : 'No reciters match your search',
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredReciters.length,
                      itemBuilder: (context, index) {
                        final reciter = _filteredReciters[index];
                        return _buildReciterCard(reciter);
                      },
                    ),
            ),
          ],
        ),
      ),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReciterDetailsScreen(reciter: reciter),
            ),
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
  List<MediaItem> _surahList = [];
  bool _isLoading = true;
  String? _errorMessage;
  Mosahf? _selectedMoshaf;
  String? _selectedSurahId;

  @override
  void initState() {
    super.initState();
    _selectedMoshaf = widget.reciter.moshaf.first;
    _loadSurahList();
  }

  Future<void> _loadSurahList() async {
    if (_selectedMoshaf == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final audioHandler = getIt<AudioPlayerHandlerImpl>();
      final surahList = await audioHandler.getSurahListForMoshaf(
        _selectedMoshaf!,
      );

      if (surahList != null) {
        setState(() {
          _surahList = surahList;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load surah list';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading surah list: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppWithBottomPlayer(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.reciter.name),
          actions: [
            if (_isLoading)
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
              Container(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<Mosahf>(
                  initialValue: _selectedMoshaf,
                  decoration: const InputDecoration(
                    labelText: 'Select Recitation',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.reciter.moshaf.map((moshaf) {
                    return DropdownMenuItem<Mosahf>(
                      value: moshaf,
                      child: Text(moshaf.name),
                    );
                  }).toList(),
                  onChanged: (Mosahf? moshaf) {
                    if (moshaf != null) {
                      setState(() {
                        _selectedMoshaf = moshaf;
                      });
                      _loadSurahList();
                    }
                  },
                ),
              ),

            // Content
            Expanded(
              child: _isLoading
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
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadSurahList,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _surahList.isEmpty
                  ? const Center(child: Text('No surahs available'))
                  : StreamBuilder<MediaItem?>(
                      stream: globalAudioHandler.mediaItem,
                      builder: (context, snapshot) {
                        final hasAudio = snapshot.data != null;
                        // Calculate dynamic padding based on screen size and bottom player visibility
                        final screenHeight = MediaQuery.of(context).size.height;
                        final bottomPadding = hasAudio
                            ? (screenHeight * 0.14).clamp(
                                80.0,
                                150.0,
                              ) // 12% of screen height, min 80px, max 120px
                            : 0.0;

                        return ListView.builder(
                          padding: EdgeInsets.only(bottom: bottomPadding),
                          itemCount: _surahList.length,
                          itemBuilder: (context, index) {
                            final surah = _surahList[index];
                            return _buildSurahCard(surah, index);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahCard(MediaItem surah, int index) {
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
        final isSelected = _selectedSurahId == surah.id;
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
                      _playSurah(surah);
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
                _playSurah(surah);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _playSurah(MediaItem surah) async {
    try {
      // Set the selected surah immediately for instant highlighting
      setState(() {
        _selectedSurahId = surah.id;
      });

      final audioHandler = getIt<AudioPlayerHandlerImpl>();

      // Find the index of the selected surah in the full list
      final surahIndex = _surahList.indexWhere((item) => item.id == surah.id);

      print(
        '_playSurah: selected surah=${surah.title}, index=$surahIndex, total surahs=${_surahList.length}',
      );

      if (surahIndex != -1) {
        // Update queue with the entire surah list
        print('_playSurah: updating queue with ${_surahList.length} surahs');
        await audioHandler.updateQueue(_surahList);

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
