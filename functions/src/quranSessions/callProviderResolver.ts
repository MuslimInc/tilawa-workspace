import { resolveMeetingLink } from "./meetingLinkResolver";
import { lifecycleError } from "./lifecycleErrors";

/**
 * Resolves call provider metadata when a booking is created.
 *
 * Free Beta default: external + mock. When platform config enables Agora or
 * WebRTC, voice/video bookings lock to the highest-priority enabled RTC provider.
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

const ALL_CALL_PROVIDERS = new Set<SessionCallProviderKind>([
  "external",
  "mock",
  "agora",
  "webrtc",
]);

const FREE_BETA_PROVIDERS = new Set<SessionCallProviderKind>([
  "external",
  "mock",
]);

const RTC_PROVIDER_PRIORITY: SessionCallProviderKind[] = [
  "agora",
  "webrtc",
  "mock",
];

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

  const enabledProviders = parseEnabledCallProviders(
    platformConfig.enabledCallProviders,
  );
  const rtcProviders = rtcProvidersFromEnabled(enabledProviders);
  const callProvider = resolveRtcProviderForBooking({
    enabledRtcProviders: rtcProviders,
    clientCallProvider: params.clientCallProvider,
  });

  return {
    callProvider,
    providerSessionId: sessionId,
    meetingLink: null,
    joinToken: null,
  };
}

export function parseEnabledCallProviders(raw: unknown): Set<SessionCallProviderKind> {
  if (raw === undefined || raw === null) {
    return FREE_BETA_PROVIDERS;
  }
  if (!Array.isArray(raw)) {
    throw new Error("invalid_enabled_call_providers");
  }
  const parsed = raw.filter(
    (provider): provider is SessionCallProviderKind =>
      typeof provider === "string"
      && ALL_CALL_PROVIDERS.has(provider as SessionCallProviderKind),
  );
  if (parsed.length === 0) {
    throw new Error("invalid_enabled_call_providers");
  }
  return new Set(parsed);
}

function rtcProvidersFromEnabled(
  enabled: Set<SessionCallProviderKind>,
): Set<SessionCallProviderKind> {
  return new Set(
    [...enabled].filter((provider) => provider !== "external"),
  );
}

export function resolveRtcProviderForBooking(params: {
  enabledRtcProviders: Set<SessionCallProviderKind>;
  clientCallProvider?: string;
}): SessionCallProviderKind {
  const { enabledRtcProviders, clientCallProvider } = params;

  if (enabledRtcProviders.size === 0) {
    throw new Error("unsupported_call_provider");
  }

  if (clientCallProvider != null && clientCallProvider.trim() !== "") {
    const requested = clientCallProvider.trim() as SessionCallProviderKind;
    if (requested === "external") {
      throw new Error("unsupported_call_provider");
    }
    if (!ALL_CALL_PROVIDERS.has(requested)) {
      throw new Error("unsupported_call_provider");
    }
    if (!enabledRtcProviders.has(requested)) {
      throw new Error("unsupported_call_provider");
    }
    return requested;
  }

  for (const provider of RTC_PROVIDER_PRIORITY) {
    if (enabledRtcProviders.has(provider)) {
      return provider;
    }
  }

  throw new Error("unsupported_call_provider");
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
      "Call provider is not enabled for this platform configuration.",
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
