import 'package:equatable/equatable.dart';

class TasbeehDhikr extends Equatable {
  const TasbeehDhikr({
    required this.id,
    required this.text,
    required this.count,
    required this.targetCount,
    required this.targetReachedNotified,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String text;
  final int count;
  final int targetCount;
  final bool targetReachedNotified;
  final DateTime createdAt;
  final DateTime updatedAt;

  TasbeehDhikr copyWith({
    String? id,
    String? text,
    int? count,
    int? targetCount,
    bool? targetReachedNotified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TasbeehDhikr(
      id: id ?? this.id,
      text: text ?? this.text,
      count: count ?? this.count,
      targetCount: targetCount ?? this.targetCount,
      targetReachedNotified:
          targetReachedNotified ?? this.targetReachedNotified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    text,
    count,
    targetCount,
    targetReachedNotified,
    createdAt,
    updatedAt,
  ];
}
