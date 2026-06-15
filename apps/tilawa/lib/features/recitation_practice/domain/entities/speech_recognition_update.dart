import 'package:equatable/equatable.dart';

/// A partial or final transcript emitted by the speech recognizer.
class SpeechRecognitionUpdate extends Equatable {
  const SpeechRecognitionUpdate({
    required this.transcript,
    required this.isFinal,
  });

  final String transcript;
  final bool isFinal;

  @override
  List<Object?> get props => [transcript, isFinal];
}
