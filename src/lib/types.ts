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

export interface RenderRequest {
  captures: Capture[];
  reviews: Review[];
  business: Business;
}
export interface RenderResult {
  videoUrl: string;
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

export interface ScriptStep {
  businessId: string;
  sceneTitle: string; // "SCENE 2 · THE MARKET HALL, SYMMETRICAL"
  direction: string; // themed staging instruction
  line: string; // line to deliver (voice/caption seed)
  perkCallout: string | null; // "Deliver 1 photo + 1 story → 2 free coffees (€7)"
  actions: ScriptAction[];
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
