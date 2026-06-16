import { onCall, HttpsError } from "firebase-functions/v2/https";

interface VerifyRecitationAudioRequest {
  surahNumber?: number;
  ayahNumber?: number;
  pageNumber?: number;
  expectedText?: string;
  audio?: string;
  audioFormat?: string;
  sampleRate?: number;
}

interface RecitationWordResult {
  word: string;
  status: "correct" | "incorrect" | "missing";
}

interface VerifyRecitationAudioResponse {
  score: number;
  feedbackText: string;
  words: RecitationWordResult[];
}

const MAX_AUDIO_BYTES = 4 * 1024 * 1024;
const DEFAULT_TIMEOUT_MS = 30000;
const ALINA_PROTOCOL = "alina-fastapi";

/**
 * Proxies a captured recitation clip to the acoustic verifier service.
 *
 * The verifier service should compare the supplied WAV audio against the
 * expected ayah using an audio-alignment model, then return a normalized score.
 */
export const verifyRecitationAudio = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 60,
    memory: "512MiB",
    // Keep development builds usable while Play Integrity/App Check is being
    // configured. Enable enforcement after debug and release attestations pass.
    enforceAppCheck: false,
  },
  async (request): Promise<VerifyRecitationAudioResponse> => {
    const data = request.data as VerifyRecitationAudioRequest;
    if (!data) {
      throw new HttpsError("invalid-argument", "Request data is required.");
    }
    const payload = validateRequest(data);
    const verifierUrl = process.env.RECITATION_VERIFIER_URL?.trim();

    if (!verifierUrl) {
      throw new HttpsError(
        "failed-precondition",
        "Recitation verifier service is not configured."
      );
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);

    try {
      const result =
        verifierProtocol() === ALINA_PROTOCOL
          ? await requestAlinaVerifier(payload, verifierUrl, controller.signal)
          : await requestJsonVerifier(payload, verifierUrl, controller.signal);
      return result;
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      const message =
        error instanceof Error && error.name === "AbortError"
          ? "Recitation verifier timed out."
          : "Recitation verifier request failed.";
      throw new HttpsError("unavailable", message);
    } finally {
      clearTimeout(timeout);
    }
  }
);

function validateRequest(
  data: VerifyRecitationAudioRequest
): Required<VerifyRecitationAudioRequest> {
  const surahNumber = validatePositiveInt(data.surahNumber, "surahNumber");
  const ayahNumber = validatePositiveInt(data.ayahNumber, "ayahNumber");
  const pageNumber = validatePositiveInt(data.pageNumber, "pageNumber");
  const expectedText = data.expectedText?.trim();
  const audio = data.audio?.trim();
  const audioFormat = data.audioFormat?.trim().toLowerCase() || "wav";
  const sampleRate = validatePositiveInt(data.sampleRate, "sampleRate");

  if (!expectedText) {
    throw new HttpsError("invalid-argument", "expectedText is required.");
  }
  if (!audio) {
    throw new HttpsError("invalid-argument", "audio is required.");
  }
  if (audioFormat !== "wav") {
    throw new HttpsError("invalid-argument", "Only WAV audio is supported.");
  }
  if (sampleRate < 8000 || sampleRate > 48000) {
    throw new HttpsError("invalid-argument", "sampleRate is unsupported.");
  }

  const audioBytes = Buffer.from(audio, "base64");
  if (audioBytes.length === 0 || audioBytes.length > MAX_AUDIO_BYTES) {
    throw new HttpsError("invalid-argument", "audio size is unsupported.");
  }

  return {
    surahNumber,
    ayahNumber,
    pageNumber,
    expectedText,
    audio,
    audioFormat,
    sampleRate,
  };
}

function validatePositiveInt(value: unknown, fieldName: string): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    throw new HttpsError("invalid-argument", `${fieldName} is required.`);
  }
  return value;
}

function verifierHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  const apiKey = process.env.RECITATION_VERIFIER_API_KEY?.trim();
  if (apiKey) {
    headers.Authorization = `Bearer ${apiKey}`;
  }
  return headers;
}

function verifierProtocol(): string {
  return process.env.RECITATION_VERIFIER_PROTOCOL?.trim().toLowerCase() ?? "";
}

async function requestJsonVerifier(
  payload: Required<VerifyRecitationAudioRequest>,
  verifierUrl: string,
  signal: AbortSignal
): Promise<VerifyRecitationAudioResponse> {
  const response = await fetch(verifierUrl, {
    method: "POST",
    headers: verifierHeaders(),
    body: JSON.stringify(payload),
    signal,
  });

  if (!response.ok) {
    const message = await response.text();
    throw new HttpsError(
      "internal",
      message || `Verifier failed with status ${response.status}.`
    );
  }

  const result = (await response.json()) as unknown;
  return normalizeVerifierResponse(result);
}

async function requestAlinaVerifier(
  payload: Required<VerifyRecitationAudioRequest>,
  verifierUrl: string,
  signal: AbortSignal
): Promise<VerifyRecitationAudioResponse> {
  const audioBytes = Buffer.from(payload.audio, "base64");
  const form = new FormData();
  form.append(
    "file",
    new Blob([new Uint8Array(audioBytes)], { type: "audio/wav" }),
    recitationFileName(payload)
  );

  const response = await fetch(resolveAlinaEndpoint(verifierUrl), {
    method: "POST",
    headers: verifierAuthHeaders(),
    body: form,
    signal,
  });

  if (!response.ok) {
    const message = await response.text();
    throw new HttpsError(
      "internal",
      message || `Alina verifier failed with status ${response.status}.`
    );
  }

  const result = (await response.json()) as unknown;
  return normalizeAlinaResponse(result, payload.expectedText);
}

function verifierAuthHeaders(): Record<string, string> {
  const apiKey = process.env.RECITATION_VERIFIER_API_KEY?.trim();
  return apiKey ? { Authorization: `Bearer ${apiKey}` } : {};
}

function recitationFileName(
  payload: Required<VerifyRecitationAudioRequest>
): string {
  return `surah-${payload.surahNumber}-ayah-${payload.ayahNumber}.wav`;
}

function resolveAlinaEndpoint(verifierUrl: string): string {
  const url = new URL(verifierUrl);
  if (url.pathname === "/" || url.pathname === "") {
    url.pathname = "/speechrecognition";
  }
  return url.toString();
}

function normalizeVerifierResponse(
  result: unknown
): VerifyRecitationAudioResponse {
  if (!isRecord(result)) {
    throw new HttpsError(
      "internal",
      "Verifier returned an invalid response."
    );
  }

  const rawScore = result.score ?? result.overallScore;
  if (typeof rawScore !== "number" || Number.isNaN(rawScore)) {
    throw new HttpsError("internal", "Verifier did not return a score.");
  }

  const score = rawScore > 1 ? rawScore / 100 : rawScore;
  return {
    score: clamp(score, 0, 1),
    feedbackText:
      typeof result.feedbackText === "string" ? result.feedbackText : "",
    words: parseWords(result.words),
  };
}

function parseWords(rawWords: unknown): RecitationWordResult[] {
  if (!Array.isArray(rawWords)) {
    return [];
  }

  return rawWords.flatMap((rawWord) => {
    if (!isRecord(rawWord)) {
      return [];
    }
    const word = rawWord.word ?? rawWord.text;
    if (typeof word !== "string" || word.trim().length === 0) {
      return [];
    }
    return [
      {
        word,
        status: parseStatus(rawWord.status),
      },
    ];
  });
}

function parseStatus(rawStatus: unknown): RecitationWordResult["status"] {
  return rawStatus === "correct" ||
    rawStatus === "incorrect" ||
    rawStatus === "missing"
    ? rawStatus
    : "missing";
}

function normalizeAlinaResponse(
  result: unknown,
  expectedText: string
): VerifyRecitationAudioResponse {
  const record = firstVerifierRecord(result);
  const words = alinaWords(record.combinewordsresult);
  const score = alinaScore(record, words);
  if (score === null) {
    throw new HttpsError(
      "internal",
      "Alina verifier did not return a usable score."
    );
  }

  return {
    score,
    feedbackText: alinaFeedbackText(record),
    words: words.length > 0 ? words : missingWords(expectedText),
  };
}

function firstVerifierRecord(result: unknown): Record<string, unknown> {
  const value = Array.isArray(result) ? result[0] : result;
  if (!isRecord(value)) {
    throw new HttpsError(
      "internal",
      "Alina verifier returned an invalid response."
    );
  }
  return value;
}

function alinaWords(rawWords: unknown): RecitationWordResult[] {
  if (!Array.isArray(rawWords)) {
    return [];
  }

  return rawWords.flatMap((rawWord) => {
    if (!isRecord(rawWord)) {
      return [];
    }
    const word = rawWord.word ?? rawWord.text;
    if (typeof word !== "string" || word.trim().length === 0) {
      return [];
    }
    return [
      {
        word,
        status: alinaWordStatus(rawWord),
      },
    ];
  });
}

function alinaWordStatus(
  rawWord: Record<string, unknown>
): RecitationWordResult["status"] {
  if (rawWord.status !== undefined) {
    return parseStatus(rawWord.status);
  }

  const score = normalizedScore(rawWord.score);
  if (score === null) {
    return "missing";
  }
  if (score >= 0.8) {
    return "correct";
  }
  return score > 0 ? "incorrect" : "missing";
}

function alinaScore(
  record: Record<string, unknown>,
  words: RecitationWordResult[]
): number | null {
  const explicitScore = normalizedScore(record.score ?? record.overallScore);
  if (explicitScore !== null) {
    return explicitScore;
  }

  if (words.length === 0) {
    return null;
  }
  const correctWords = words.filter((word) => word.status === "correct");
  return correctWords.length / words.length;
}

function normalizedScore(rawScore: unknown): number | null {
  if (typeof rawScore !== "number" || Number.isNaN(rawScore)) {
    return null;
  }
  const score = rawScore > 1 ? rawScore / 100 : rawScore;
  return clamp(score, 0, 1);
}

function alinaFeedbackText(record: Record<string, unknown>): string {
  const status = record.status;
  if (typeof status === "string" && status.trim()) {
    return status.trim();
  }
  const combinedWords = record.combinewordsresult ?? record.combineWordsResult;
  if (typeof combinedWords === "string" && combinedWords.trim()) {
    return combinedWords.trim();
  }
  const surahVerse = record.surahverse ?? record.surahVerse;
  return typeof surahVerse === "string" ? surahVerse.trim() : "";
}

function missingWords(text: string): RecitationWordResult[] {
  return splitWords(text).map((word) => ({
    word,
    status: "missing",
  }));
}

function splitWords(text: string): string[] {
  return text
    .split(/\s+/)
    .map((word) => word.trim())
    .filter((word) => word.length > 0);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
