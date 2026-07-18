import 'package:equatable/equatable.dart';

/// Category chip for the reels feed.
///
/// [id] `null` means "All". Known API ids: 2 (Prophet ﷺ), 3 (faith), 4 (Ramadan).
final class ReelCategory extends Equatable {
  const ReelCategory({
    required this.id,
    required this.label,
  });

  /// `null` = All categories.
  final int? id;
  final String label;

  static const ReelCategory all = ReelCategory(id: null, label: '');

  @override
  List<Object?> get props => [id, label];
}
