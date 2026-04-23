import 'package:flutter/foundation.dart';

/// An opaque handle that represents a UI element to be captured.
/// This allows the domain layer to request captures without depending
/// on Flutter-specific types like [GlobalKey].
@immutable
class WidgetCaptureHandle {
  const WidgetCaptureHandle(this.value);

  /// The underlying platform/UI specific key (e.g., a GlobalKey in Flutter).
  final Object value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetCaptureHandle &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
