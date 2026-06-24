const TEACHER_MEETING_URL_FIELDS = [
  "externalMeetingUrl",
  "meetingLink",
  "external_meeting_url",
  "meeting_link",
] as const;

/** Reads the first non-empty teacher meeting URL field (legacy keys included). */
export function readTeacherExternalMeetingUrl(
  teacherProfile: Record<string, unknown>,
): string | null {
  for (const key of TEACHER_MEETING_URL_FIELDS) {
    const raw = teacherProfile[key];
    if (typeof raw === "string") {
      const trimmed = raw.trim();
      if (trimmed.length > 0) {
        return trimmed;
      }
    }
  }
  return null;
}

function readPlatformDefaultMeetingUrl(
  platformConfig: Record<string, unknown>,
): string | null {
  const raw = platformConfig.defaultExternalMeetingUrl;
  if (typeof raw !== "string") {
    return null;
  }
  const trimmed = raw.trim();
  return trimmed.length > 0 ? trimmed : null;
}

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

  const teacherUrl = readTeacherExternalMeetingUrl(teacherProfile);
  if (teacherUrl != null) {
    return teacherUrl;
  }

  return readPlatformDefaultMeetingUrl(platformConfig);
}
