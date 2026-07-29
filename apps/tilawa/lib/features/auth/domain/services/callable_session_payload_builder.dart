import 'session_epoch_provider.dart';

class CallableSessionPayloadBuilder {
  CallableSessionPayloadBuilder(this._sessionEpochProvider);

  final SessionEpochProvider _sessionEpochProvider;

  Future<Map<String, dynamic>> withSessionEpoch(
    Map<String, dynamic> payload,
  ) async {
    final epoch = await _sessionEpochProvider.getSessionEpoch();
    return {
      ...payload,
      'sessionEpoch': epoch,
    };
  }
}
