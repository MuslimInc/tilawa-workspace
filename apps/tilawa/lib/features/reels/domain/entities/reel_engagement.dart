import 'package:equatable/equatable.dart';

import 'reel_reaction.dart';

/// Local engagement counters for ranking and analytics.
final class ReelEngagement extends Equatable {
  const ReelEngagement({
    this.viewsStarted = 0,
    this.viewsCompleted = 0,
    this.reactionCounts = const {},
    this.saves = 0,
    this.shares = 0,
  });

  final int viewsStarted;
  final int viewsCompleted;
  final Map<ReelReaction, int> reactionCounts;
  final int saves;
  final int shares;

  int get totalReactions =>
      reactionCounts.values.fold(0, (sum, count) => sum + count);

  ReelEngagement copyWith({
    int? viewsStarted,
    int? viewsCompleted,
    Map<ReelReaction, int>? reactionCounts,
    int? saves,
    int? shares,
  }) {
    return ReelEngagement(
      viewsStarted: viewsStarted ?? this.viewsStarted,
      viewsCompleted: viewsCompleted ?? this.viewsCompleted,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      saves: saves ?? this.saves,
      shares: shares ?? this.shares,
    );
  }

  Map<String, dynamic> toJson() => {
    'viewsStarted': viewsStarted,
    'viewsCompleted': viewsCompleted,
    'reactionCounts': {
      for (final e in reactionCounts.entries) e.key.name: e.value,
    },
    'saves': saves,
    'shares': shares,
  };

  factory ReelEngagement.fromJson(Map<String, dynamic> json) {
    final raw = json['reactionCounts'] as Map<String, dynamic>? ?? {};
    final Map<ReelReaction, int> counts = {};
    for (final e in raw.entries) {
      final reaction = ReelReaction.values
          .where((r) => r.name == e.key)
          .firstOrNull;
      if (reaction != null) {
        counts[reaction] = e.value as int;
      }
    }
    return ReelEngagement(
      viewsStarted: json['viewsStarted'] as int? ?? 0,
      viewsCompleted: json['viewsCompleted'] as int? ?? 0,
      reactionCounts: counts,
      saves: json['saves'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    viewsStarted,
    viewsCompleted,
    reactionCounts,
    saves,
    shares,
  ];
}
