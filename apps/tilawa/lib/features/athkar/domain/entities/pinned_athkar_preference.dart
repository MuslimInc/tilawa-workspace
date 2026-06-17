import 'package:equatable/equatable.dart';

/// Ordered Home athkar shortcut preference.
class PinnedAthkarPreference extends Equatable {
  const PinnedAthkarPreference({
    required this.categoryIds,
    required this.isCustomized,
  });

  /// Ordered category IDs to show on Home.
  final List<int> categoryIds;

  /// Whether the user has explicitly saved their own selection.
  final bool isCustomized;

  @override
  List<Object?> get props => [categoryIds, isCustomized];
}
