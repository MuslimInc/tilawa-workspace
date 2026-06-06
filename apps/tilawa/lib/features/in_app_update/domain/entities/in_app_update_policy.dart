import 'package:flutter/foundation.dart';

/// Remote policy for Google Play in-app updates.
///
/// Defaults to optional (flexible) updates. Set [forceUpdate] to `true` in
/// Firestore `app_config/in_app_update` to block the app with an immediate
/// update when Play allows it.
@immutable
class InAppUpdatePolicy {
  const InAppUpdatePolicy({this.forceUpdate = false});

  final bool forceUpdate;
}
