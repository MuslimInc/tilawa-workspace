import 'dart:core';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../downloads/data/services/downloads_initialization_service.dart';
import '../../domain/entities/entities.dart';
import '../bloc/word_by_word_audio_bloc.dart';

class SurahTextSection extends StatefulWidget {
  const SurahTextSection({
    super.key,
    required this.words,
    required this.fontSize,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final List<QuranWord> words;
  final double fontSize;
  final int surahNumber;
  final int ayahNumber;

  @override
  State<SurahTextSection> createState() => _SurahTextSectionState();
}

class _SurahTextSectionState extends State<SurahTextSection> {
  final List<TapGestureRecognizer> recognizers = [];

  @override
  void dispose() {
    for (final TapGestureRecognizer r in recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.d(
      '[SurahTextSection] playingWordId: ${context.read<WordByWordAudioBloc>().state.playingWordId}',
    );
    logger.d(
      '[SurahTextSection] building: ${context.read<WordByWordAudioBloc>().state.playingWordId}',
    );
    logger.d('[SurahTextSection] words: ${widget.words.length}');

    return BlocBuilder<WordByWordAudioBloc, WordByWordAudioState>(
      builder: (context, state) {
        _disposeRecognizers();

        final int? playingId = state.playingWordId;

        // Optimized single-pass construction
        final List<InlineSpan> spans = widget.words.expand((ayah) {
          final wordSpans = <InlineSpan>[];

          for (final QuranWord word in widget.words) {
            wordSpans.add(_buildWordSpan(word, playingId));
          }

          return wordSpans;
        }).toList();

        return RichText(
          text: TextSpan(children: spans),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        );
      },
    );
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer r in recognizers) {
      r.dispose();
    }
    recognizers.clear();
  }

  TextSpan _buildWordSpan(QuranWord word, int? playingId) {
    final isPlaying = word.id == playingId;
    final recognizer = TapGestureRecognizer()..onTap = () => _playWord(word);

    recognizers.add(recognizer);

    return TextSpan(
      text: word.renderedText,
      recognizer: recognizer,
      style: TextStyle(
        fontFamily: word.fontFamily,
        fontSize: 30,
        color: isPlaying ? Colors.amber[900] : Colors.black,
        backgroundColor: isPlaying ? Colors.amber.withValues(alpha: 0.2) : null,
      ),
    );
  }

  void _playWord(QuranWord word) {
    final String surahStr = widget.surahNumber.toString().padLeft(3, '0');
    final String ayahStr = widget.ayahNumber.toString().padLeft(3, '0');
    final String wordStr = word.position.toString().padLeft(3, '0');
    final correctedUrl = 'wbw/${surahStr}_${ayahStr}_$wordStr.mp3';

    context.read<WordByWordAudioBloc>().add(
      WordByWordAudioEvent.playWord(correctedUrl, word.id),
    );
  }
}
