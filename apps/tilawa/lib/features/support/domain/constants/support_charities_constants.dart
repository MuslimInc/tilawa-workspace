/// Partner charity entry opened from Support Tilawa trust copy.
class SupportPartnerCharity {
  const SupportPartnerCharity({
    required this.id,
    required this.url,
  });

  /// Localization key suffix: [SupportPartnerCharityId.name].
  final SupportPartnerCharityId id;

  final String url;
}

/// Known partner charity IDs for localized display names.
enum SupportPartnerCharityId {
  darAlArqam,
  islaheg,
}

/// Partner charities receiving part of voluntary support contributions.
abstract final class SupportCharitiesConstants {
  static const List<SupportPartnerCharity> partners = <SupportPartnerCharity>[
    SupportPartnerCharity(
      id: SupportPartnerCharityId.darAlArqam,
      url: 'https://www.facebook.com/profile.php?id=100087077444451',
    ),
    SupportPartnerCharity(
      id: SupportPartnerCharityId.islaheg,
      url: 'https://islaheg.com/',
    ),
  ];

  static bool get hasPartners => partners.isNotEmpty;
}
