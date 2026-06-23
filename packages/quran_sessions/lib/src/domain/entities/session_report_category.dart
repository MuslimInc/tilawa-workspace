/// Abuse / safety report categories — mirrors CF `ReportCategory`.
enum SessionReportCategory {
  safetyConcern('safety_concern'),
  abuseOrHarassment('abuse_or_harassment'),
  inappropriateContent('inappropriate_content'),
  childSafety('child_safety'),
  fraudOrScam('fraud_or_scam'),
  other('other');

  const SessionReportCategory(this.cfValue);

  final String cfValue;
}
