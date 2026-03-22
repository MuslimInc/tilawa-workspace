
enum NotificationActionType {
  home,
  reciter,
  athkar,
  quran,
  settings,
  unknown;
  
  static NotificationActionType fromString(String? value) {
    return NotificationActionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationActionType.unknown,
    );
  }
}

class NotificationAction {
  final NotificationActionType type;
  final Map<String, dynamic> data;

  NotificationAction({
    required this.type,
    this.data = const {},
  });
}
