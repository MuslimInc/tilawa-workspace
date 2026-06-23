import { RtcRole, RtcTokenBuilder } from "agora-token";

const DEFAULT_TOKEN_TTL_SECONDS = 3600;

export interface AgoraRtcCredentials {
  appId: string;
  appCertificate: string;
}

export function readAgoraRtcCredentials(): AgoraRtcCredentials | null {
  const appId = process.env.AGORA_APP_ID?.trim() ?? "";
  const appCertificate = process.env.AGORA_APP_CERTIFICATE?.trim() ?? "";
  if (!appId || !appCertificate) {
    return null;
  }
  return { appId, appCertificate };
}

export function buildAgoraRtcToken(params: {
  credentials: AgoraRtcCredentials;
  channelName: string;
  uid: number;
  ttlSeconds?: number;
}): string {
  const ttl = params.ttlSeconds ?? DEFAULT_TOKEN_TTL_SECONDS;

  return RtcTokenBuilder.buildTokenWithUid(
    params.credentials.appId,
    params.credentials.appCertificate,
    params.channelName,
    params.uid,
    RtcRole.PUBLISHER,
    ttl,
    ttl,
  );
}

export function agoraUidForFirebaseUser(userId: string): number {
  let hash = 0;
  for (let i = 0; i < userId.length; i += 1) {
    hash = (hash * 31 + userId.charCodeAt(i)) >>> 0;
  }
  const uid = hash & 0x7fffffff;
  return uid === 0 ? 1 : uid;
}
