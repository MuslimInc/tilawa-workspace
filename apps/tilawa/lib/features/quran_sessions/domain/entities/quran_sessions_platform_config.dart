import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class QuranSessionsPlatformConfig extends Equatable {
  const QuranSessionsPlatformConfig({
    required this.quranSessionsEnabled,
    required this.studentEntryEnabled,
    required this.bookingEnabled,
    required this.bookingMode,
    required this.sessionMode,
    required this.enabledCallProviders,
    this.teacherApplicationEntryEnabled = false,
    this.homeTeacherApplicationCardEnabled = false,
    this.teacherApplicationEnabled = false,
    this.teacherApplicationDiscoverability = 'none',
    this.walletEnabled = false,
  });

  final bool quranSessionsEnabled;
  final bool studentEntryEnabled;
  final bool bookingEnabled;
  final String bookingMode;
  final String sessionMode;
  final Set<String> enabledCallProviders;
  final bool teacherApplicationEntryEnabled;
  final bool homeTeacherApplicationCardEnabled;
  final bool teacherApplicationEnabled;
  final String teacherApplicationDiscoverability;
  final bool walletEnabled;

  static const safeFallback = QuranSessionsPlatformConfig(
    quranSessionsEnabled: false,
    studentEntryEnabled: false,
    bookingEnabled: false,
    bookingMode: 'requiresTutorApproval',
    sessionMode: 'videoOnly',
    enabledCallProviders: {'external', 'mock'},
  );

  factory QuranSessionsPlatformConfig.fromJson(Map<String, Object?> json) {
    return QuranSessionsPlatformConfig(
      quranSessionsEnabled: json['quranSessionsEnabled'] == true,
      studentEntryEnabled: json['studentEntryEnabled'] == true,
      bookingEnabled: json['bookingEnabled'] == true,
      // `bookingMode` is canonical; the other names are legacy read aliases.
      bookingMode: _stringValue(
        json['bookingMode'] ??
            json['quranTutorBookingMode'] ??
            json['defaultBookingMode'],
        fallback: 'requiresTutorApproval',
      ),
      sessionMode: _stringValue(json['sessionMode'], fallback: 'videoOnly'),
      enabledCallProviders: _providersFromJson(json['enabledCallProviders']),
      teacherApplicationEntryEnabled:
          json['teacherApplicationEntryEnabled'] == true,
      homeTeacherApplicationCardEnabled:
          json['homeTeacherApplicationCardEnabled'] == true,
      teacherApplicationEnabled: json['teacherApplicationEnabled'] == true,
      teacherApplicationDiscoverability: _stringValue(
        json['teacherApplicationDiscoverability'],
        fallback: 'none',
      ),
      walletEnabled: json['walletEnabled'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'quranSessionsEnabled': quranSessionsEnabled,
    'studentEntryEnabled': studentEntryEnabled,
    'bookingEnabled': bookingEnabled,
    'bookingMode': bookingMode,
    'sessionMode': sessionMode,
    'enabledCallProviders': enabledCallProviders.toList()..sort(),
    'teacherApplicationEntryEnabled': teacherApplicationEntryEnabled,
    'homeTeacherApplicationCardEnabled': homeTeacherApplicationCardEnabled,
    'teacherApplicationEnabled': teacherApplicationEnabled,
    'teacherApplicationDiscoverability': teacherApplicationDiscoverability,
    'walletEnabled': walletEnabled,
  };

  @override
  List<Object?> get props => [
    quranSessionsEnabled,
    studentEntryEnabled,
    bookingEnabled,
    bookingMode,
    sessionMode,
    enabledCallProviders.toList()..sort(),
    teacherApplicationEntryEnabled,
    homeTeacherApplicationCardEnabled,
    teacherApplicationEnabled,
    teacherApplicationDiscoverability,
    walletEnabled,
  ];
}

String _stringValue(Object? raw, {required String fallback}) {
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  return fallback;
}

Set<String> _providersFromJson(Object? raw) {
  if (raw is Iterable) {
    final values = raw
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (values.isNotEmpty) {
      return values;
    }
  }
  if (raw is String) {
    return _parseProviders(raw);
  }
  return {'external', 'mock'};
}

Set<String> _parseProviders(String csv) {
  final values = csv
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
  return values.isEmpty ? {'external', 'mock'} : values;
}
