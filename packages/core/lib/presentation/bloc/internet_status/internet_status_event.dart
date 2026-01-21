import 'package:freezed_annotation/freezed_annotation.dart';

part 'internet_status_event.freezed.dart';

@freezed
abstract class InternetStatusEvent with _$InternetStatusEvent {
  const factory InternetStatusEvent.statusChanged(bool isConnected) =
      _StatusChanged;
}
