import 'package:flutter/widgets.dart';
import 'package:tilawa/core/extensions.dart';

import '../domain/constants/support_charities_constants.dart';

/// Localized display name for a [SupportPartnerCharity].
String supportPartnerCharityLabel(
  BuildContext context,
  SupportPartnerCharityId id,
) {
  final l10n = context.l10n;
  return switch (id) {
    SupportPartnerCharityId.darAlArqam => l10n.supportCharityDarAlArqam,
    SupportPartnerCharityId.islaheg => l10n.supportCharityIslaheg,
  };
}
