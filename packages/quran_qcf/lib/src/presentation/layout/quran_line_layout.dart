import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class QuranLineVisualBounds extends Equatable {
  const QuranLineVisualBounds({required this.left, required this.right});

  final double left;
  final double right;

  double get width => right - left;
  double get center => left + (width / 2);

  QuranLineVisualBounds shift(double dx) {
    return QuranLineVisualBounds(left: left + dx, right: right + dx);
  }

  @override
  List<Object?> get props => [left, right];
}

@immutable
class QuranLineAlignment extends Equatable {
  const QuranLineAlignment({required this.source, required this.target});

  final QuranLineVisualBounds source;
  final QuranLineVisualBounds target;

  bool get isValid =>
      source.width.isFinite &&
      source.width > 0 &&
      target.width.isFinite &&
      target.width > 0;

  // Preserve the original QCF glyph geometry; only align lines by position.
  double get scaleX => 1.0;

  double get translateX => isValid ? target.center - source.center : 0.0;

  Offset inverse(Offset visualOffset) {
    if (!isValid) return visualOffset;
    return Offset(visualOffset.dx - translateX, visualOffset.dy);
  }

  @override
  List<Object?> get props => [source, target];
}

QuranLineVisualBounds? quranLineVisualBoundsFor(TextPainter painter) {
  final String text = painter.text?.toPlainText() ?? '';
  if (text.isEmpty) return null;

  final List<TextBox> boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  if (boxes.isEmpty) return null;

  double left = boxes.first.left;
  double right = boxes.first.right;
  for (final TextBox box in boxes.skip(1)) {
    if (box.left < left) left = box.left;
    if (box.right > right) right = box.right;
  }

  return QuranLineVisualBounds(left: left, right: right);
}

QuranLineVisualBounds? quranLineTargetBoundsFor(
  Iterable<QuranLineVisualBounds?> bounds,
) {
  final Iterator<QuranLineVisualBounds> iterator = bounds
      .whereType<QuranLineVisualBounds>()
      .iterator;
  if (!iterator.moveNext()) return null;

  double left = iterator.current.left;
  double right = iterator.current.right;
  while (iterator.moveNext()) {
    final QuranLineVisualBounds current = iterator.current;
    if (current.left < left) left = current.left;
    if (current.right > right) right = current.right;
  }

  return QuranLineVisualBounds(left: left, right: right);
}
