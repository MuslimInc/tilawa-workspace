import { AccessToken } from "livekit-server-sdk";

export interface LiveKitRtcCredentials {
  apiKey: string;
  apiSecret: string;
  serverUrl: string;
}

export function readLiveKitRtcCredentials(): LiveKitRtcCredentials | null {
  const apiKey = process.env.LIVEKIT_API_KEY;
  const apiSecret = process.env.LIVEKIT_API_SECRET;
  const serverUrl = process.env.LIVEKIT_URL;
  if (
    apiKey == null
    || apiKey.trim() === ""
    || apiSecret == null
    || apiSecret.trim() === ""
    || serverUrl == null
    || serverUrl.trim() === ""
  ) {
    return null;
  }
  return {
    apiKey: apiKey.trim(),
    apiSecret: apiSecret.trim(),
    serverUrl: serverUrl.trim(),
  };
}

export async function buildLiveKitRtcToken(params: {
  credentials: LiveKitRtcCredentials;
  roomName: string;
  identity: string;
  /**
   * Token lifetime in seconds. When omitted, LiveKit's SDK default applies.
   * The live-session device lock sets this so the lease TTL equals the token
   * TTL (ADR-008 Phase 2), making lock renewal piggyback on token refresh.
   */
  ttlSeconds?: number;
}): Promise<string> {
  const options: { identity: string; ttl?: number } = { identity: params.identity };
  if (params.ttlSeconds != null) {
    options.ttl = params.ttlSeconds;
  }
  const token = new AccessToken(
    params.credentials.apiKey,
    params.credentials.apiSecret,
    options,
  );
  token.addGrant({
    roomJoin: true,
    room: params.roomName,
    canPublish: true,
    canSubscribe: true,
  });
  return token.toJwt();
}
