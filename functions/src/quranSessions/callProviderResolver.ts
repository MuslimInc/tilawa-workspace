/**
 * Resolves call provider metadata when a booking is created.
 *
 * Free Beta: external meetings use teacher/platform URL; voice/video use mock
 * until Agora/WebRTC are enabled server-side.
 */
export type SessionCallProviderKind =
  | "external"
  | "mock"
  | "agora"
  | "webrtc";

export interface ResolvedCallProvider {
  callProvider: SessionCallProviderKind;
  providerSessionId: string | null;
  meetingLink: string | null;
  joinToken: string | null;
}

const ALLOWED_CALL_TYPES = new Set([
  "externalMeeting",
  "voiceCall",
  "videoCall",
]);

const FREE_BETA_PROVIDERS = new Set<SessionCallProviderKind>([
  "external",
  "mock",
]);

export function assertValidCallType(callType: string): void {
  if (!ALLOWED_CALL_TYPES.has(callType)) {
    throw new Error(`unsupported_session_mode:${callType}`);
  }
}

export function resolveCallProviderForBooking(params: {
  callType: string;
  sessionId: string;
  teacherProfile: Record<string, unknown>;
  platformConfig: Record<string, unknown>;
  clientCallProvider?: string;
}): ResolvedCallProvider {
  const { callType, sessionId, teacherProfile, platformConfig } = params;

  assertValidCallType(callType);

  if (params.clientCallProvider === "agora" || params.clientCallProvider === "webrtc") {
    throw new Error("unsupported_call_provider");
  }

  if (callType === "externalMeeting") {
    const meetingLink = resolveExternalMeetingUrl(teacherProfile, platformConfig);
    return {
      callProvider: "external",
      providerSessionId: null,
      meetingLink,
      joinToken: null,
    };
  }

  const enabledRtc =
    platformConfig.enabledCallProviders === undefined
      ? FREE_BETA_PROVIDERS
      : new Set(
          (platformConfig.enabledCallProviders as string[]).filter((p) =>
            FREE_BETA_PROVIDERS.has(p as SessionCallProviderKind),
          ),
        );

  if (!enabledRtc.has("mock")) {
    throw new Error("unsupported_call_provider");
  }

  return {
    callProvider: "mock",
    providerSessionId: sessionId,
    meetingLink: null,
    joinToken: null,
  };
}

function resolveExternalMeetingUrl(
  teacherProfile: Record<string, unknown>,
  platformConfig: Record<string, unknown>,
): string | null {
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
