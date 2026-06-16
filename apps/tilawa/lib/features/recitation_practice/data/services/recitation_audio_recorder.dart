import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../domain/entities/recitation_target.dart';

/// Captures one ayah recitation as a WAV file for acoustic verification.
@lazySingleton
class RecitationAudioRecorder {
  RecitationAudioRecorder() : _recorder = AudioRecorder();

  static const int _sampleRate = 16000;
  static const int _bitRate = 256000;

  final AudioRecorder _recorder;
  String? _activePath;

  int get sampleRate => _sampleRate;

  Future<void> start(RecitationTarget target) async {
    await cancel();

    final directory = await getTemporaryDirectory();
    final String path =
        '${directory.path}/tilawa_recitation_'
        '${target.surahNumber}_${target.ayahNumber}_'
        '${DateTime.now().microsecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: _sampleRate,
        numChannels: 1,
        bitRate: _bitRate,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: path,
    );
    _activePath = path;
  }

  Future<String?> stop() async {
    final String? path = await _recorder.stop();
    _activePath = null;
    return path;
  }

  Future<void> cancel() async {
    if (_activePath == null && !await _recorder.isRecording()) {
      return;
    }
    await _recorder.cancel();
    _activePath = null;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
