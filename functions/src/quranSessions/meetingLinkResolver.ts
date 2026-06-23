/**
 * Resolves the external meeting URL copied onto a session at booking time.
 *
 * Priority: teacher `externalMeetingUrl` → platform `defaultExternalMeetingUrl`.
 */
export function resolveMeetingLink(
  callType: string,
  teacherProfile: Record<string, unknown>,
  platformConfig: Record<string, unknown>,
): string | null {
  if (callType !== "externalMeeting") {
    return null;
  }

  const teacherUrl =
    typeof teacherProfile.externalMeetingUrl === "string"
      ? teacherProfile.externalMeetingUrl.trim()
      : "";
  if (teacherUrl.length > 0) {
    return teacherUrl;
  }

  const platformUrl =
    typeof platformConfig.defaultExternalMeetingUrl === "string"
      ? platformConfig.defaultExternalMeetingUrl.trim()
      : "";
  if (platformUrl.length > 0) {
    return platformUrl;
  }

  return null;
}
