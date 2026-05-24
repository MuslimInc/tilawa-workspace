import 'package:dio/dio.dart';

import '../../domain/entities/share_cancel_token.dart';

/// Links a domain [ShareCancelToken] to Dio cancellation for HTTP/FFmpeg.
class ShareCancelTokenBridge {
  ShareCancelTokenBridge(this._domain) : dioToken = CancelToken() {
    _domain.addCancelListener(_cancelDio);
  }

  final ShareCancelToken _domain;
  final CancelToken dioToken;

  bool get isCancelled => _domain.isCancelled || dioToken.isCancelled;

  void _cancelDio() {
    if (!dioToken.isCancelled) {
      dioToken.cancel();
    }
  }

  static ShareCancelTokenBridge? fromDomain(ShareCancelToken? domain) {
    if (domain == null) {
      return null;
    }
    return ShareCancelTokenBridge(domain);
  }
}
