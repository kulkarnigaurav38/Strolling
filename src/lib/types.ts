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
