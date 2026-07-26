import { config } from "../config";

// ElevenLabs text-to-speech. Turns the cleaned voiceover script into natural
// narration audio. (ElevenLabs is voice-only — the text is cleaned upstream by
// the LLM in scriptCleaner.ts.)

export function isElevenLabsEnabled(): boolean {
  return Boolean(config.elevenLabsApiKey);
}

/** Synthesize speech for `text`; returns MP3 bytes. */
export async function synthesizeSpeech(text: string): Promise<Buffer> {
  if (!config.elevenLabsApiKey) throw new Error("ELEVENLABS_API_KEY is not set");

  const res = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${config.elevenLabsVoiceId}`,
    {
      method: "POST",
      headers: {
        "xi-api-key": config.elevenLabsApiKey,
        "content-type": "application/json",
        accept: "audio/mpeg",
      },
      body: JSON.stringify({
        text,
        model_id: config.elevenLabsModel,
        voice_settings: {
          stability: 0.4,
          similarity_boost: 0.75,
          style: 0.3,
          use_speaker_boost: true,
        },
      }),
    },
  );

  if (!res.ok) {
    const detail = (await res.text()).slice(0, 300);
    throw new Error(`ElevenLabs TTS → HTTP ${res.status}: ${detail}`);
  }
  return Buffer.from(await res.arrayBuffer());
}

/**
 * Speech-to-text (ElevenLabs Scribe). Turns the creator's raw voice note into a
 * transcript — the words they actually said (grammar mistakes and all). That
 * transcript is then polished into narration upstream (scriptCleaner) and spoken
 * back by TTS, so the FINAL narration reflects the creator's own opinions.
 */
export async function transcribeSpeech(
  audio: Buffer,
  filename = "voice.m4a",
): Promise<string> {
  if (!config.elevenLabsApiKey) throw new Error("ELEVENLABS_API_KEY is not set");

  const form = new FormData();
  form.append("model_id", config.elevenLabsSttModel);
  // Uint8Array view keeps the Blob happy regardless of the Buffer's backing store.
  form.append("file", new Blob([new Uint8Array(audio)]), filename);

  const res = await fetch("https://api.elevenlabs.io/v1/speech-to-text", {
    method: "POST",
    headers: { "xi-api-key": config.elevenLabsApiKey },
    body: form,
  });

  if (!res.ok) {
    const detail = (await res.text()).slice(0, 300);
    throw new Error(`ElevenLabs STT → HTTP ${res.status}: ${detail}`);
  }
  const data = (await res.json()) as { text?: string };
  return (data.text ?? "").trim();
}
