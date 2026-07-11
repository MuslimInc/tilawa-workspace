/// One dhikr entry displayed by the athkar widget.
class AthkarWidgetItem {
  const AthkarWidgetItem({required this.text, required this.count});

  /// Arabic dhikr text (athkar content is Arabic-only by design).
  final String text;

  /// Prescribed repetition count (display badge; the widget advances per
  /// item, not per repetition, in v1).
  final int count;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    'count': count,
  };
}

/// Display-ready content for the morning/evening athkar widget (spec 041,
/// US3). Both sets ship in one snapshot; the native host picks the applicable
/// window by local time so no Dart isolate is needed at flip time.
class AthkarWidgetPayload {
  const AthkarWidgetPayload({
    required this.morningTitle,
    required this.eveningTitle,
    required this.morning,
    required this.evening,
  });

  final String morningTitle;
  final String eveningTitle;
  final List<AthkarWidgetItem> morning;
  final List<AthkarWidgetItem> evening;

  Map<String, Object?> toJson() => <String, Object?>{
    'morningTitle': morningTitle,
    'eveningTitle': eveningTitle,
    'morning': <Object?>[for (final item in morning) item.toJson()],
    'evening': <Object?>[for (final item in evening) item.toJson()],
  };
}
