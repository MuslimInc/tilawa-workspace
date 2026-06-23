import { resolveMeetingLink } from "./meetingLinkResolver";
import { lifecycleError } from "./lifecycleErrors";

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
    const meetingLink = resolveMeetingLink(
      callType,
      teacherProfile,
      platformConfig,
    );
    return {
      callProvider: "external",
      providerSessionId: null,
      meetingLink,
      joinToken: null,
    };
  }

  const enabledRtc = parseEnabledRtcProviders(platformConfig.enabledCallProviders);

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

function parseEnabledRtcProviders(raw: unknown): Set<SessionCallProviderKind> {
  if (raw === undefined || raw === null) {
    return FREE_BETA_PROVIDERS;
  }
  if (!Array.isArray(raw)) {
    throw new Error("invalid_enabled_call_providers");
  }
  return new Set(
    raw.filter(
      (provider): provider is SessionCallProviderKind =>
        typeof provider === "string"
        && FREE_BETA_PROVIDERS.has(provider as SessionCallProviderKind),
    ),
  );
}

/** Maps resolver failures to lifecycle-safe HttpsError codes. */
export function mapCallProviderResolverError(
  error: unknown,
  clientCallProvider?: string,
): never {
  const message = error instanceof Error ? error.message : "";
  if (message === "unsupported_call_provider") {
    throw lifecycleErrorFromCode(
      "unsupported_call_provider",
      "Call provider is not enabled for Free Beta.",
      clientCallProvider == null ? undefined : { callProvider: clientCallProvider },
    );
  }
  if (message === "invalid_enabled_call_providers") {
    throw lifecycleErrorFromCode(
      "unsupported_call_provider",
      "Call provider configuration is invalid.",
      clientCallProvider == null ? undefined : { callProvider: clientCallProvider },
    );
  }
  if (message.startsWith("unsupported_session_mode:")) {
    throw lifecycleErrorFromCode(
      "unsupported_session_mode",
      "Unsupported session mode.",
      { callType: message.split(":")[1] ?? "unknown" },
    );
  }
  throw error;
}

function lifecycleErrorFromCode(
  code: "unsupported_call_provider" | "unsupported_session_mode",
  message: string,
  details?: Record<string, unknown>,
): never {
  throw lifecycleError(code, message, details);
}
