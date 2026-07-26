// The contract. This is the single source of truth the frontend (built from the
// Figma design) codes against. Keep request/response shapes stable; swap the
// implementation behind each route one commit at a time.

export type TaskType = "photo" | "clip";

export interface Task {
  id: string;
  title: string; // "📸 Entrance sign, low angle"
  type: TaskType;
  instruction: string; // one concrete framing instruction
  suggestedLine: string; // a line the Regisseur offers so nobody has to improvise
  order: number;
}

export interface Capture {
  taskId: string;
  mediaUrl: string; // storage URL returned by POST /api/media/upload
  kind: TaskType;
}

export interface Review {
  taskId: string;
  transcript: string; // what the creator said about this shot/place
  summary: string; // 1-sentence summary (agent-provided later)
}

export type SessionStatus =
  | "brief"
  | "shooting"
  | "interview"
  | "rendering"
  | "done";

export interface ShootSession {
  status: SessionStatus;
  currentTaskIndex: number;
  tasks: Task[];
  captures: Capture[];
  reviews: Review[];
  videoUrl?: string;
  postUrl?: string;
  caption?: string;
  hashtags?: string[];
}

// --- Endpoint payloads ---

export interface GenerateTasksRequest {
  business: Business;
}

/** One capture part in the stroll render shape (video / audio / text / images). */
export interface StrollRenderPart {
  images?: string[];
  videoUrl?: string;
  audioUrl?: string;
  text?: string;
  script?: string;
  /** Creator's RAW voice note — transcribed → cleaned → re-voiced (see below). */
  voiceNoteUrl?: string;
}

/**
 * POST /api/render body. Preferred stroll shape is a flat mix of
 * images/videoUrl/audioUrl/text/script (or `parts[]` for multi-stop).
 * Legacy `shots` / `captures`+`reviews` still work.
 */
export interface RenderRequest {
  captures?: Capture[];
  reviews?: Review[];
  business?: Business;
  /** Preferred paired shots: each mediaUrl + its script part. */
  shots?: { mediaUrl: string; kind?: "photo" | "clip"; script?: string }[];
  /** Flat stroll inputs (any mix). */
  images?: string[];
  videoUrl?: string;
  audioUrl?: string;
  text?: string;
  script?: string;
  /** Multi-stop stroll: one entry per scene/part. */
  parts?: StrollRenderPart[];
  /** Whole-video narration track, used AS-IS (bypasses per-shot TTS). */
  voiceoverUrl?: string;
  /**
   * Creator's RAW spoken voice note. Unlike `voiceoverUrl`, this is NOT used as
   * the final audio — it is transcribed (ElevenLabs Scribe), polished into a
   * narration script (LLM), and re-voiced by TTS. So the finished narration
   * carries the creator's own opinions, in the AI voice.
   */
  voiceNoteUrl?: string;
  /** Async Supabase job id. */
  jobId?: string;
  /** Client-supplied id to report/poll live render progress (see lib/progress). */
  renderId?: string;
}

/** Post package returned by POST /api/render. */
export interface RenderResult {
  videoUrl: string;
  caption: string;
  hashtags: string[];
  script: string;
}

export interface PublishRequest {
  videoUrl: string;
  transcript: string;
}
export interface PublishResult {
  postUrl: string;
  caption: string;
  hashtags: string[];
}

export interface UploadResult {
  mediaUrl: string;
}

export interface Business {
  slug: string;
  name: string;
  venue: string;
  incentive: string;
  vibe: string;
  style: string;
}

// ---------------------------------------------------------------------------
// Strolling contract (Figma Make "CursorStutt" v5 + script templates).
// Mirrors frontend/lib/core/models.dart and script_templates.dart — keep in sync.
// ---------------------------------------------------------------------------

export type BusinessCategory = "cafe" | "food" | "drinks" | "culture" | "market";

export interface StrollBusiness {
  id: string;
  name: string;
  category: BusinessCategory;
  description: string;
  walkMinutes: number;
  rating: number;
  lat: number; // real-world position (WGS84)
  lng: number;
  narration: string;
  perkTitle?: string; // absent → roam-only stop, no obligations
  perkValue?: number; // €
  deliverable?: string; // "1 photo + 1 story post"
}

/** How a script task ends — the capture card the app opens. */
export type CaptureAction = "photo" | "video" | "voice" | "text";

export interface ScriptAction {
  kind: CaptureAction;
  prompt: string; // "Facade dead-center. Nothing may lean."
  required: boolean; // required by the perk deliverable — gates posting
}

/** Narrative beat or inline capture card on the step screen. */
export interface SceneBlock {
  kind: "narrative" | "capture";
  narrative?: string;
  captureTitle?: string;
  capturePrompt?: string;
  captureKind?: CaptureAction;
}

export interface ScriptStep {
  businessId: string;
  sceneTitle: string; // "SCENE 2 · THE MARKET HALL, SYMMETRICAL"
  direction: string; // themed staging instruction
  line: string; // line to deliver (voice/caption seed)
  perkCallout: string | null; // "Deliver 1 photo + 1 story → 2 free coffees (€7)"
  actions: ScriptAction[];
  /** Area overview shown above capture blocks (Flutter step UI). */
  locationTitle?: string | null;
  locationBody?: string | null;
  /** Ordered narrative + capture cards; empty → client fills from local templates. */
  blocks?: SceneBlock[];
}

export interface ScriptTemplateInfo {
  id: string; // wes | kubrick | doku | viral
  name: string;
  tagline: string;
  emoji: string;
  color: string; // hex, for the picker card accent
  vibe: string;
}

export interface GenerateScriptRequest {
  stopIds: string[]; // ordered picks from the map
  templateId: string;
}

export interface GenerateScriptResponse {
  templateId: string;
  steps: ScriptStep[];
}

// ---------------------------------------------------------------------------
// Creator + business marketplace contract (offers, claims, posts, portal).
// Mirrors migration #2 (profiles/social_accounts/offers/posts + perk alters).
// ⚠️ MOCK auth: there is none for the hackathon — userId travels in the body /
// query string and defaults to 'demo-user'.
// TODO(REAL:auth): derive userId from the Supabase JWT (Authorization header).
// ---------------------------------------------------------------------------

/** social_platform enum in Postgres. */
export type SocialPlatform = "instagram" | "facebook" | "tiktok";

/** post_platform enum in Postgres (migration #1). */
export type PostPlatform = "instagram" | "tiktok" | "facebook";

/** offer_type enum in Postgres. */
export type OfferType = "in_kind" | "cash";

/**
 * perk_status enum after migration #2 extends it. Lifecycle:
 * en_route → arrived → posted → approved (business) → redeemed.
 * ('pending' remains from migration #1 for legacy perk rows.)
 */
export type ClaimStatus =
  | "pending"
  | "en_route"
  | "arrived"
  | "posted"
  | "approved"
  | "redeemed";

/** profiles table — one row per auth user. */
export interface Profile {
  id: string;
  name: string;
  city: string;
  interests: string[];
  score: number; // creator score, e.g. 4.8
  createdAt: string; // ISO timestamp
}

/** social_accounts table — connected creator platform accounts. */
export interface SocialAccount {
  id: string;
  userId: string;
  platform: SocialPlatform;
  handle: string; // '@sophie.explores'
  followers: number;
  connectedAt: string; // ISO timestamp
}

/** Business info joined onto an offer (map pin essentials). */
export interface OfferBusiness {
  id: string;
  name: string;
  category: string; // business_category or a free-form category for new signups
  lat: number;
  lng: number;
}

/** offers table — what a business puts on the marketplace. */
export interface Offer {
  id: string;
  businessId: string;
  perkTitle: string; // '3 free craft beers'
  perkValue: number; // €
  offerType: OfferType;
  deliverable: string; // '1 story + tag'
  minFollowers: number;
  slotsTotal: number;
  slotsRemaining: number;
  active: boolean;
  business?: OfferBusiness; // present on GET /api/offers
}

/** A claim = a perks row (+ mock ETA). The creator's side of an offer. */
export interface Claim {
  id: string;
  userId: string;
  businessId: string;
  offerId: string | null; // null → claim predates offers / created via post
  status: ClaimStatus;
  etaMin: number; // ⚠️ MOCK: no live location — fixed/derived minutes
}

/** posts table — a published social post the business can see. */
export interface PublishedPost {
  id: string;
  userId: string;
  businessId: string;
  platform: PostPlatform;
  url?: string;
  caption?: string;
  reach: number;
  likes: number;
  comments: number;
  postedAt: string; // ISO timestamp
}

/** GET /api/business/:id/stats — derived from claims + posts + offers. */
export interface BusinessStats {
  creatorsHosted: number;
  posts: number;
  totalReach: number;
  costEur: number; // Σ perkValue of offers whose claims reached 'posted'+
}
