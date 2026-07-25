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
