import 'package:equatable/equatable.dart';

import 'word_match_status.dart';

/// One target word and how the user's recitation matched it.
class ComparedWord extends Equatable {
  const ComparedWord({
    required this.word,
    required this.status,
  });

  final String word;
  final WordMatchStatus status;

  @override
  List<Object?> get props => [word, status];
}
