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
}): Promise<string> {
  const token = new AccessToken(
    params.credentials.apiKey,
    params.credentials.apiSecret,
    { identity: params.identity },
  );
  token.addGrant({
    roomJoin: true,
    room: params.roomName,
    canPublish: true,
    canSubscribe: true,
  });
  return token.toJwt();
}
