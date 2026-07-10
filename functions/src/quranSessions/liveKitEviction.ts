import { RoomServiceClient } from "livekit-server-sdk";
import * as logger from "firebase-functions/logger";

import type { LiveKitRtcCredentials } from "./livekitTokenService";

/**
 * LiveKit targeted eviction — ADR-008 Phase 2.
 *
 * When a user takes over a live session from another device, the server evicts
 * the old device's LiveKit participant by identity (`uid#deviceId`) via
 * `RoomServiceClient.removeParticipant`. Agora has no reliable per-device
 * eviction, so it stays deny-only (the old device drops at token expiry).
 */
export interface EvictLiveKitParticipantInput {
  credentials: LiveKitRtcCredentials;
  roomName: string;
  identity: string;
}

export type LiveKitEvictionFn = (
  input: EvictLiveKitParticipantInput,
) => Promise<void>;

/**
 * Evicts a LiveKit participant by identity. Best-effort: a failure logs but
 * does **not** fail the RTC token issuance — the Firestore lock is already the
 * source of truth, and the old device's token expires at `leaseUntil`.
 */
export const evictLiveKitParticipant: LiveKitEvictionFn = async (input) => {
  const client = new RoomServiceClient(
    input.credentials.serverUrl,
    input.credentials.apiKey,
    input.credentials.apiSecret,
  );
  try {
    await client.removeParticipant(input.roomName, input.identity);
  } catch (error) {
    logger.warn("livekit removeParticipant failed", {
      room: input.roomName,
      identity: input.identity,
      error: error instanceof Error ? error.message : String(error),
    });
  }
};
