import { randomUUID } from "node:crypto";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { config } from "../config";
import { STROLL_BUSINESSES } from "./seed";
import type {
  BusinessStats,
  Claim,
  ClaimStatus,
  Offer,
  OfferBusiness,
  OfferType,
  PostPlatform,
  Profile,
  PublishedPost,
  SocialAccount,
  SocialPlatform,
} from "./types";

// ---------------------------------------------------------------------------
// Data layer behind the marketplace routes (offers / claims / posts / business
// portal). Two implementations of one Store interface:
//   - MemoryStore  — ⚠️ MOCK branch (default): in-memory, seeded to mirror the
//     React business-dashboard demo. Zero credentials, resets on restart.
//   - SupabaseStore — real branch (service role). Where a table is missing
//     (migration #2 not applied yet) reads fall back to the memory store and
//     writes surface DbNotReadyError → routes answer 503 { error:'db_not_ready' }.
// getStore() picks per config.
// ---------------------------------------------------------------------------

/** Thrown by SupabaseStore writes when the DB isn't ready (or errored). */
export class DbNotReadyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DbNotReadyError";
  }
}

/** Thrown when a claim is attempted on an inactive / sold-out offer. → 409 */
export class OfferUnavailableError extends Error {
  constructor() {
    super("offer is inactive or sold out");
    this.name = "OfferUnavailableError";
  }
}

/** Thrown on an invalid claim status transition (e.g. approved → arrived). → 409 */
export class ClaimTransitionError extends Error {
  constructor(from: ClaimStatus, to: ClaimStatus) {
    super(`invalid transition ${from} → ${to}`);
    this.name = "ClaimTransitionError";
  }
}

/** Lifecycle order — transitions may only move forward. */
const CLAIM_RANK: Record<ClaimStatus, number> = {
  pending: 0,
  en_route: 1,
  arrived: 2,
  posted: 3,
  approved: 4,
  redeemed: 5,
};

/**
 * Guard a claim transition. 'redeemed' additionally requires the claim to be
 * 'approved' first (you can't redeem an unapproved perk).
 */
function assertTransition(from: ClaimStatus, to: ClaimStatus): void {
  if (CLAIM_RANK[to] <= CLAIM_RANK[from]) throw new ClaimTransitionError(from, to);
  if (to === "redeemed" && from !== "approved") throw new ClaimTransitionError(from, to);
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface OfferInput {
  perkTitle: string;
  perkValue: number;
  offerType: OfferType;
  deliverable: string;
  minFollowers?: number;
  slotsTotal?: number;
}

export interface OfferPatch {
  perkTitle?: string;
  perkValue?: number;
  offerType?: OfferType;
  deliverable?: string;
  minFollowers?: number;
  slotsTotal?: number;
  slotsRemaining?: number;
  active?: boolean;
}

export interface PostInput {
  userId: string;
  businessId: string;
  platform: PostPlatform;
  url?: string;
  caption?: string;
}

/** Row for GET /api/business/:id/creators. */
export interface BusinessCreatorRow {
  name: string;
  handle: string;
  followers: number;
  status: ClaimStatus;
  etaMin: number;
}

export type BusinessPostRow = PublishedPost & { creatorHandle: string };

export interface RegisteredBusiness {
  businessId: string;
  verified: boolean;
}

export interface Store {
  listOffers(followers?: number): Promise<Offer[]>;
  /** null → offer not found. Throws OfferUnavailableError when sold out/paused. */
  createClaim(userId: string, offerId: string): Promise<Claim | null>;
  /** null → claim not found. Throws ClaimTransitionError on backwards moves. */
  updateClaimStatus(
    claimId: string,
    status: "arrived" | "posted" | "redeemed",
  ): Promise<Claim | null>;
  /** null → business not found. */
  createPost(input: PostInput): Promise<{ post: PublishedPost; claim: Claim } | null>;
  listUserClaims(userId: string): Promise<Claim[]>;
  connectSocialAccount(
    userId: string,
    platform: SocialPlatform,
    handle: string,
  ): Promise<SocialAccount>;
  registerBusiness(name: string, email: string): Promise<RegisteredBusiness>;
  /** null → business not found. */
  verifyBusiness(businessId: string): Promise<RegisteredBusiness | null>;
  listBusinessOffers(businessId: string): Promise<Offer[]>;
  createBusinessOffer(businessId: string, input: OfferInput): Promise<Offer>;
  /** null → offer not found. */
  updateOffer(offerId: string, patch: OfferPatch): Promise<Offer | null>;
  listBusinessCreators(businessId: string): Promise<BusinessCreatorRow[]>;
  listBusinessPosts(businessId: string): Promise<BusinessPostRow[]>;
  getBusinessStats(businessId: string): Promise<BusinessStats>;
  /** null → perk/claim not found. */
  approvePerk(perkId: string): Promise<Claim | null>;
}

// ---------------------------------------------------------------------------
// Mock helpers (deterministic where the demo needs stability)
// ---------------------------------------------------------------------------

/**
 * ⚠️ MOCK: deterministic follower count from the handle (800..48000).
 * TODO(REAL:social): read real follower counts via the Instagram Graph /
 * TikTok / Facebook APIs after an OAuth connect flow.
 */
export function mockFollowersFor(handle: string): number {
  let h = 0;
  for (let i = 0; i < handle.length; i++) {
    h = (h * 31 + handle.charCodeAt(i)) >>> 0;
  }
  return 800 + (h % 47201); // 800..48000 inclusive
}

/** ⚠️ MOCK: no live location — a plausible walking ETA. */
function mockEtaMin(): number {
  return 5 + Math.floor(Math.random() * 11); // 5..15
}

/**
 * ⚠️ MOCK post metrics. TODO(REAL:social): pull reach/likes/comments from the
 * platform insights APIs for the posted URL.
 */
function mockPostMetrics(): { reach: number; likes: number; comments: number } {
  const reach = 1200 + Math.floor(Math.random() * (45000 - 1200 + 1));
  const likes = Math.round(reach * (0.03 + Math.random() * 0.03));
  const comments = Math.round(likes * (0.03 + Math.random() * 0.05));
  return { reach, likes, comments };
}

function slugify(name: string): string {
  return (
    name
      .toLowerCase()
      .normalize("NFKD")
      .replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "") || "business"
  );
}

// ---------------------------------------------------------------------------
// MemoryStore — ⚠️ MOCK. Seeded to mirror the React dashboard demo exactly:
// creators Sophie M. (en_route, 12 min) / Lukas K. (arrived) / Anna B.
// (posted); offers '3 free craft beers' + '€25 cash payment'; posts by
// @anna.explores and @cityguidemax. Stats derive from these rows.
// ---------------------------------------------------------------------------

interface MemBusiness extends OfferBusiness {
  verified: boolean;
  email?: string;
}

export const DEMO_BUSINESS_ID = "demo";
const SEED_TS = "2026-07-25T09:00:00.000Z";

export class MemoryStore implements Store {
  private businesses = new Map<string, MemBusiness>();
  private profiles = new Map<string, Profile>();
  private socialAccounts: SocialAccount[] = [];
  private offers: Offer[] = [];
  private claims: Claim[] = [];
  private posts: PublishedPost[] = [];

  constructor() {
    this.seed();
  }

  private seed(): void {
    // The demo business the React dashboard shows ('demo' id, per contract).
    this.businesses.set(DEMO_BUSINESS_ID, {
      id: DEMO_BUSINESS_ID,
      name: "Bar Soleil",
      category: "drinks",
      lat: 48.7768,
      lng: 9.183,
      verified: true,
    });
    // Real businesses are the map-pin slugs from the Strolling seed.
    for (const b of STROLL_BUSINESSES) {
      this.businesses.set(b.id, {
        id: b.id,
        name: b.name,
        category: b.category,
        lat: b.lat,
        lng: b.lng,
        verified: true,
      });
    }

    const users: Array<{
      id: string;
      name: string;
      platform: SocialPlatform;
      handle: string;
      followers: number;
    }> = [
      // 'demo-user' IS Sophie — the app's default no-auth creator.
      { id: "demo-user", name: "Sophie M.", platform: "instagram", handle: "@sophie.explores", followers: 8500 },
      { id: "user-lukas", name: "Lukas K.", platform: "instagram", handle: "@lukasinthewild", followers: 22000 },
      { id: "user-anna-b", name: "Anna B.", platform: "instagram", handle: "@byannab", followers: 41000 },
      { id: "user-anna-e", name: "Anna E.", platform: "instagram", handle: "@anna.explores", followers: 45200 },
      { id: "user-max", name: "Max C.", platform: "tiktok", handle: "@cityguidemax", followers: 68000 },
    ];
    for (const u of users) {
      this.profiles.set(u.id, {
        id: u.id,
        name: u.name,
        city: "Stuttgart",
        interests: ["coffee", "food", "city"],
        score: 4.2,
        createdAt: SEED_TS,
      });
      this.socialAccounts.push({
        id: `sa-${u.id}`,
        userId: u.id,
        platform: u.platform,
        handle: u.handle,
        followers: u.followers,
        connectedAt: SEED_TS,
      });
    }

    // Demo offers (mirror the dashboard's offer cards).
    this.offers.push(
      {
        id: "offer-demo-beers",
        businessId: DEMO_BUSINESS_ID,
        perkTitle: "3 free craft beers",
        perkValue: 15,
        offerType: "in_kind",
        deliverable: "1 story + tag",
        minFollowers: 0,
        slotsTotal: 20,
        slotsRemaining: 8,
        active: true,
      },
      {
        id: "offer-demo-cash",
        businessId: DEMO_BUSINESS_ID,
        perkTitle: "€25 cash payment",
        perkValue: 25,
        offerType: "cash",
        deliverable: "1 post + 1 reel",
        minFollowers: 10000,
        slotsTotal: 5,
        slotsRemaining: 3,
        active: true,
      },
    );
    // Every perk stop on the map is also a live in-kind offer.
    for (const b of STROLL_BUSINESSES) {
      if (!b.perkTitle) continue;
      this.offers.push({
        id: `offer-${b.id}`,
        businessId: b.id,
        perkTitle: b.perkTitle,
        perkValue: b.perkValue ?? 0,
        offerType: "in_kind",
        deliverable: b.deliverable ?? "1 photo",
        minFollowers: 0,
        slotsTotal: 10,
        slotsRemaining: 10,
        active: true,
      });
    }

    // Live creators at the demo business (dashboard "Creators" card).
    this.claims.push(
      {
        id: "claim-sophie",
        userId: "demo-user",
        businessId: DEMO_BUSINESS_ID,
        offerId: "offer-demo-beers",
        status: "en_route",
        etaMin: 12,
      },
      {
        id: "claim-lukas",
        userId: "user-lukas",
        businessId: DEMO_BUSINESS_ID,
        offerId: "offer-demo-beers",
        status: "arrived",
        etaMin: 0,
      },
      {
        id: "claim-anna",
        userId: "user-anna-b",
        businessId: DEMO_BUSINESS_ID,
        offerId: "offer-demo-cash",
        status: "posted",
        etaMin: 0,
      },
    );

    // Published posts (dashboard "Recent posts" card).
    this.posts.push(
      {
        id: "post-anna",
        userId: "user-anna-e",
        businessId: DEMO_BUSINESS_ID,
        platform: "instagram",
        url: "https://instagram.com/p/mock-anna",
        caption: "Golden hour at the best rooftop in Stuttgart 🍻",
        reach: 38200,
        likes: 1240,
        comments: 87,
        postedAt: SEED_TS,
      },
      {
        id: "post-max",
        userId: "user-max",
        businessId: DEMO_BUSINESS_ID,
        platform: "tiktok",
        url: "https://tiktok.com/@cityguidemax/video/mock",
        caption: "POV: you found the beer spot 🎥",
        reach: 61000,
        likes: 3850,
        comments: 214,
        postedAt: SEED_TS,
      },
    );
  }

  private businessJoin(businessId: string): OfferBusiness | undefined {
    const b = this.businesses.get(businessId);
    if (!b) return undefined;
    return { id: b.id, name: b.name, category: b.category, lat: b.lat, lng: b.lng };
  }

  async listOffers(followers?: number): Promise<Offer[]> {
    return this.offers
      .filter((o) => o.active)
      .filter((o) => followers === undefined || o.minFollowers <= followers)
      .map((o) => ({ ...o, business: this.businessJoin(o.businessId) }));
  }

  async createClaim(userId: string, offerId: string): Promise<Claim | null> {
    const offer = this.offers.find((o) => o.id === offerId);
    if (!offer) return null;
    // perks is unique(user_id, business_id) — mirror that: one claim per pair.
    let claim = this.claims.find(
      (c) => c.userId === userId && c.businessId === offer.businessId,
    );
    if (claim) {
      // Re-claiming never regresses a claim that already progressed.
      if (CLAIM_RANK[claim.status] <= CLAIM_RANK.en_route) {
        claim.offerId = offerId;
        claim.status = "en_route";
        claim.etaMin = mockEtaMin();
      }
    } else {
      // New claims only against live offers with slots left.
      if (!offer.active || offer.slotsRemaining <= 0) {
        throw new OfferUnavailableError();
      }
      claim = {
        id: randomUUID(),
        userId,
        businessId: offer.businessId,
        offerId,
        status: "en_route",
        etaMin: mockEtaMin(),
      };
      this.claims.push(claim);
      offer.slotsRemaining -= 1;
      if (offer.slotsRemaining <= 0) {
        offer.slotsRemaining = 0;
        offer.active = false; // sold out
      }
    }
    return { ...claim };
  }

  async updateClaimStatus(
    claimId: string,
    status: "arrived" | "posted" | "redeemed",
  ): Promise<Claim | null> {
    const claim = this.claims.find((c) => c.id === claimId);
    if (!claim) return null;
    assertTransition(claim.status, status);
    claim.status = status;
    claim.etaMin = 0;
    return { ...claim };
  }

  async createPost(
    input: PostInput,
  ): Promise<{ post: PublishedPost; claim: Claim } | null> {
    if (!this.businesses.has(input.businessId)) return null;
    const post: PublishedPost = {
      id: randomUUID(),
      userId: input.userId,
      businessId: input.businessId,
      platform: input.platform,
      url: input.url,
      caption: input.caption,
      ...mockPostMetrics(), // ⚠️ MOCK metrics
      postedAt: new Date().toISOString(),
    };
    this.posts.push(post);

    // Advance this user's claim at the business to 'posted' (create if none) —
    // but never regress one that is already approved/redeemed.
    let claim = this.claims.find(
      (c) => c.userId === input.userId && c.businessId === input.businessId,
    );
    if (claim) {
      if (CLAIM_RANK[claim.status] < CLAIM_RANK.posted) {
        claim.status = "posted";
        claim.etaMin = 0;
      }
    } else {
      claim = {
        id: randomUUID(),
        userId: input.userId,
        businessId: input.businessId,
        offerId: null,
        status: "posted",
        etaMin: 0,
      };
      this.claims.push(claim);
    }
    return { post, claim: { ...claim } };
  }

  async listUserClaims(userId: string): Promise<Claim[]> {
    return this.claims.filter((c) => c.userId === userId).map((c) => ({ ...c }));
  }

  async connectSocialAccount(
    userId: string,
    platform: SocialPlatform,
    handle: string,
  ): Promise<SocialAccount> {
    const normalized = handle.startsWith("@") ? handle : `@${handle}`;
    let account = this.socialAccounts.find(
      (a) => a.userId === userId && a.platform === platform,
    );
    const followers = mockFollowersFor(normalized); // ⚠️ MOCK
    if (account) {
      account.handle = normalized;
      account.followers = followers;
    } else {
      account = {
        id: randomUUID(),
        userId,
        platform,
        handle: normalized,
        followers,
        connectedAt: new Date().toISOString(),
      };
      this.socialAccounts.push(account);
    }
    return { ...account };
  }

  async registerBusiness(name: string, email: string): Promise<RegisteredBusiness> {
    let id = slugify(name);
    let n = 2;
    while (this.businesses.has(id)) id = `${slugify(name)}-${n++}`;
    this.businesses.set(id, {
      id,
      name,
      category: "cafe",
      lat: 48.7758, // ⚠️ MOCK: central Stuttgart until the business sets a pin
      lng: 9.1829,
      verified: false,
      email,
    });
    return { businessId: id, verified: false };
  }

  async verifyBusiness(businessId: string): Promise<RegisteredBusiness | null> {
    const b = this.businesses.get(businessId);
    if (!b) return null;
    b.verified = true; // ⚠️ MOCK — TODO(REAL): Google Business Profile API check
    return { businessId, verified: true };
  }

  async listBusinessOffers(businessId: string): Promise<Offer[]> {
    return this.offers.filter((o) => o.businessId === businessId).map((o) => ({ ...o }));
  }

  async createBusinessOffer(businessId: string, input: OfferInput): Promise<Offer> {
    const slotsTotal = input.slotsTotal ?? 10;
    const offer: Offer = {
      id: randomUUID(),
      businessId,
      perkTitle: input.perkTitle,
      perkValue: input.perkValue,
      offerType: input.offerType,
      deliverable: input.deliverable,
      minFollowers: input.minFollowers ?? 0,
      slotsTotal,
      slotsRemaining: slotsTotal,
      active: true,
    };
    this.offers.push(offer);
    return { ...offer };
  }

  async updateOffer(offerId: string, patch: OfferPatch): Promise<Offer | null> {
    const offer = this.offers.find((o) => o.id === offerId);
    if (!offer) return null;
    if (patch.perkTitle !== undefined) offer.perkTitle = patch.perkTitle;
    if (patch.perkValue !== undefined) offer.perkValue = patch.perkValue;
    if (patch.offerType !== undefined) offer.offerType = patch.offerType;
    if (patch.deliverable !== undefined) offer.deliverable = patch.deliverable;
    if (patch.minFollowers !== undefined) offer.minFollowers = patch.minFollowers;
    if (patch.slotsTotal !== undefined) offer.slotsTotal = patch.slotsTotal;
    if (patch.slotsRemaining !== undefined) offer.slotsRemaining = patch.slotsRemaining;
    if (patch.active !== undefined) offer.active = patch.active;
    return { ...offer };
  }

  /**
   * The 'demo' dashboard also shows live rows from the hackathon-venue
   * business so a phone posting to 'cursor-hackathon' appears on the
   * projector's dashboard during the stage demo.
   */
  private dashboardIds(businessId: string): Set<string> {
    return businessId === DEMO_BUSINESS_ID
      ? new Set([DEMO_BUSINESS_ID, "cursor-hackathon"])
      : new Set([businessId]);
  }

  async listBusinessCreators(businessId: string): Promise<BusinessCreatorRow[]> {
    const ids = this.dashboardIds(businessId);
    return this.claims
      .filter((c) => ids.has(c.businessId))
      .map((c) => {
        const profile = this.profiles.get(c.userId);
        const account = this.socialAccounts.find((a) => a.userId === c.userId);
        return {
          name: profile?.name ?? c.userId,
          handle: account?.handle ?? `@${c.userId}`,
          followers: account?.followers ?? 0,
          status: c.status,
          etaMin: c.etaMin,
        };
      });
  }

  async listBusinessPosts(businessId: string): Promise<BusinessPostRow[]> {
    const ids = this.dashboardIds(businessId);
    return this.posts
      .filter((p) => ids.has(p.businessId))
      .map((p) => {
        const account =
          this.socialAccounts.find(
            (a) => a.userId === p.userId && a.platform === p.platform,
          ) ?? this.socialAccounts.find((a) => a.userId === p.userId);
        return { ...p, creatorHandle: account?.handle ?? `@${p.userId}` };
      });
  }

  async getBusinessStats(businessId: string): Promise<BusinessStats> {
    const ids = this.dashboardIds(businessId);
    const claims = this.claims.filter((c) => ids.has(c.businessId));
    const posts = this.posts.filter((p) => ids.has(p.businessId));
    // Cost = value of every offer whose claim got at least to 'posted'.
    const costEur = claims
      .filter((c) => c.status === "posted" || c.status === "approved" || c.status === "redeemed")
      .reduce((sum, c) => {
        const offer = this.offers.find((o) => o.id === c.offerId);
        return sum + (offer?.perkValue ?? 0);
      }, 0);
    return {
      creatorsHosted: new Set(claims.map((c) => c.userId)).size,
      posts: posts.length,
      totalReach: posts.reduce((sum, p) => sum + p.reach, 0),
      costEur,
    };
  }

  async approvePerk(perkId: string): Promise<Claim | null> {
    const claim = this.claims.find((c) => c.id === perkId);
    if (!claim) return null;
    assertTransition(claim.status, "approved");
    claim.status = "approved";
    return { ...claim };
  }
}

// ---------------------------------------------------------------------------
// SupabaseStore — the real branch (service-role client, bypasses RLS).
// snake_case columns ↔ camelCase API fields. If a query errors (e.g. the
// migration isn't applied yet): reads fall back to the memory store, writes
// throw DbNotReadyError (routes → 503 { error: 'db_not_ready' }).
// ⚠️ MOCK: businessId 'demo' always maps to the seeded in-memory demo data.
// ---------------------------------------------------------------------------

interface OfferRow {
  id: string;
  business_id: string;
  perk_title: string;
  perk_value: number;
  offer_type: OfferType;
  deliverable: string;
  min_followers: number;
  slots_total: number;
  slots_remaining: number;
  active: boolean;
  business?: { id: string; name: string; category: string; lat: number; lng: number } | null;
}

interface PerkRow {
  id: string;
  user_id: string;
  business_id: string;
  offer_id: string | null;
  status: ClaimStatus;
}

interface PostRow {
  id: string;
  user_id: string;
  business_id: string;
  platform: PostPlatform;
  url: string | null;
  caption: string | null;
  reach: number;
  likes: number;
  comments: number;
  posted_at: string;
}

function mapOffer(row: OfferRow): Offer {
  return {
    id: row.id,
    businessId: row.business_id,
    perkTitle: row.perk_title,
    perkValue: row.perk_value,
    offerType: row.offer_type,
    deliverable: row.deliverable,
    minFollowers: row.min_followers,
    slotsTotal: row.slots_total,
    slotsRemaining: row.slots_remaining,
    active: row.active,
    business: row.business
      ? {
          id: row.business.id,
          name: row.business.name,
          category: row.business.category,
          lat: row.business.lat,
          lng: row.business.lng,
        }
      : undefined,
  };
}

function mapClaim(row: PerkRow): Claim {
  return {
    id: row.id,
    userId: row.user_id,
    businessId: row.business_id,
    offerId: row.offer_id ?? null,
    status: row.status,
    // ⚠️ MOCK: perks has no eta column — synthesize from status.
    etaMin: row.status === "en_route" ? 12 : 0,
  };
}

function mapPost(row: PostRow): PublishedPost {
  return {
    id: row.id,
    userId: row.user_id,
    businessId: row.business_id,
    platform: row.platform,
    url: row.url ?? undefined,
    caption: row.caption ?? undefined,
    reach: row.reach,
    likes: row.likes,
    comments: row.comments,
    postedAt: row.posted_at,
  };
}

export class SupabaseStore implements Store {
  private client: SupabaseClient;

  constructor(private fallback: MemoryStore) {
    this.client = createClient(config.supabaseUrl, config.supabaseServiceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }

  /** Reads: log + fall back to the in-memory result. */
  private readFallback<T>(ctx: string, message: string, result: Promise<T>): Promise<T> {
    console.warn(`[store] ⚠️ supabase read failed (${ctx}) — falling back to memory: ${message}`);
    return result;
  }

  async listOffers(followers?: number): Promise<Offer[]> {
    let query = this.client
      .from("offers")
      .select("*, business:businesses(id,name,category,lat,lng)")
      .eq("active", true);
    if (followers !== undefined) query = query.lte("min_followers", followers);
    const { data, error } = await query;
    if (error) {
      return this.readFallback("listOffers", error.message, this.fallback.listOffers(followers));
    }
    return ((data ?? []) as unknown as OfferRow[]).map(mapOffer);
  }

  async createClaim(userId: string, offerId: string): Promise<Claim | null> {
    // Seeded mock ids ('offer-demo-beers', 'offer-markthalle', …) are not
    // uuids — Postgres would 22P02 on the eq() cast. They live in memory.
    if (!UUID_RE.test(offerId)) return this.fallback.createClaim(userId, offerId);
    const { data: offer, error: offerError } = await this.client
      .from("offers")
      .select("*")
      .eq("id", offerId)
      .maybeSingle();
    if (offerError) throw new DbNotReadyError(`createClaim/offer: ${offerError.message}`);
    if (!offer) return null;
    const row = offer as unknown as OfferRow;
    if (!row.active || row.slots_remaining <= 0) throw new OfferUnavailableError();

    // One claim per (user, business): never regress an existing one; only a
    // genuinely new claim burns a slot (parity with MemoryStore).
    const { data: existing, error: existingError } = await this.client
      .from("perks")
      .select("*")
      .eq("user_id", userId)
      .eq("business_id", row.business_id)
      .maybeSingle();
    if (existingError) throw new DbNotReadyError(`createClaim/existing: ${existingError.message}`);
    const existingRow = existing as unknown as PerkRow | null;
    if (existingRow && CLAIM_RANK[existingRow.status] > CLAIM_RANK.en_route) {
      return mapClaim(existingRow);
    }

    const { data, error } = await this.client
      .from("perks")
      .upsert(
        { user_id: userId, business_id: row.business_id, offer_id: offerId, status: "en_route" },
        { onConflict: "user_id,business_id" },
      )
      .select()
      .single();
    if (error) throw new DbNotReadyError(`createClaim: ${error.message}`);

    if (!existingRow) {
      // Conditional burn: only while slots remain; deactivate on the last one.
      await this.client
        .from("offers")
        .update({
          slots_remaining: row.slots_remaining - 1,
          active: row.slots_remaining - 1 > 0,
        })
        .eq("id", offerId)
        .gt("slots_remaining", 0);
    }

    return { ...mapClaim(data as unknown as PerkRow), etaMin: mockEtaMin() };
  }

  async updateClaimStatus(
    claimId: string,
    status: "arrived" | "posted" | "redeemed",
  ): Promise<Claim | null> {
    if (!UUID_RE.test(claimId)) return this.fallback.updateClaimStatus(claimId, status);
    const { data: current, error: readError } = await this.client
      .from("perks")
      .select("*")
      .eq("id", claimId)
      .maybeSingle();
    if (readError) throw new DbNotReadyError(`updateClaimStatus/read: ${readError.message}`);
    if (!current) return null;
    assertTransition((current as unknown as PerkRow).status, status);
    const { data, error } = await this.client
      .from("perks")
      .update({ status })
      .eq("id", claimId)
      .select()
      .maybeSingle();
    if (error) throw new DbNotReadyError(`updateClaimStatus: ${error.message}`);
    if (!data) return null;
    return mapClaim(data as unknown as PerkRow);
  }

  async createPost(
    input: PostInput,
  ): Promise<{ post: PublishedPost; claim: Claim } | null> {
    // The 'demo' dashboard business lives only in memory.
    if (input.businessId === DEMO_BUSINESS_ID) return this.fallback.createPost(input);
    const { data: business, error: bizError } = await this.client
      .from("businesses")
      .select("id")
      .eq("id", input.businessId)
      .maybeSingle();
    if (bizError) throw new DbNotReadyError(`createPost/business: ${bizError.message}`);
    if (!business) return null;

    const metrics = mockPostMetrics(); // ⚠️ MOCK metrics even on the real branch
    const { data, error } = await this.client
      .from("posts")
      .insert({
        user_id: input.userId,
        business_id: input.businessId,
        platform: input.platform,
        url: input.url ?? null,
        caption: input.caption ?? null,
        ...metrics,
      })
      .select()
      .single();
    if (error) throw new DbNotReadyError(`createPost: ${error.message}`);

    // Advance the claim without regressing approved/redeemed ones.
    const { data: existingPerk, error: perkReadError } = await this.client
      .from("perks")
      .select("*")
      .eq("user_id", input.userId)
      .eq("business_id", input.businessId)
      .maybeSingle();
    if (perkReadError) throw new DbNotReadyError(`createPost/perkRead: ${perkReadError.message}`);
    const existingRow = existingPerk as unknown as PerkRow | null;
    if (existingRow && CLAIM_RANK[existingRow.status] >= CLAIM_RANK.posted) {
      return { post: mapPost(data as unknown as PostRow), claim: mapClaim(existingRow) };
    }

    const { data: perk, error: perkError } = await this.client
      .from("perks")
      .upsert(
        { user_id: input.userId, business_id: input.businessId, status: "posted" },
        { onConflict: "user_id,business_id" },
      )
      .select()
      .single();
    if (perkError) throw new DbNotReadyError(`createPost/perk: ${perkError.message}`);

    return {
      post: mapPost(data as unknown as PostRow),
      claim: mapClaim(perk as unknown as PerkRow),
    };
  }

  async listUserClaims(userId: string): Promise<Claim[]> {
    const { data, error } = await this.client.from("perks").select("*").eq("user_id", userId);
    if (error) {
      return this.readFallback("listUserClaims", error.message, this.fallback.listUserClaims(userId));
    }
    return ((data ?? []) as unknown as PerkRow[]).map(mapClaim);
  }

  async connectSocialAccount(
    userId: string,
    platform: SocialPlatform,
    handle: string,
  ): Promise<SocialAccount> {
    const normalized = handle.startsWith("@") ? handle : `@${handle}`;
    const followers = mockFollowersFor(normalized); // ⚠️ MOCK follower count
    const { data, error } = await this.client
      .from("social_accounts")
      .upsert(
        { user_id: userId, platform, handle: normalized, followers },
        { onConflict: "user_id,platform" },
      )
      .select()
      .single();
    if (error) throw new DbNotReadyError(`connectSocialAccount: ${error.message}`);
    const row = data as unknown as {
      id: string;
      user_id: string;
      platform: SocialPlatform;
      handle: string;
      followers: number;
      connected_at: string;
    };
    return {
      id: row.id,
      userId: row.user_id,
      platform: row.platform,
      handle: row.handle,
      followers: row.followers,
      connectedAt: row.connected_at,
    };
  }

  async registerBusiness(name: string, email: string): Promise<RegisteredBusiness> {
    // NOTE: the businesses table has no email column — email is accepted for
    // the API contract but not persisted. TODO(REAL): store owner contact +
    // send a verification email.
    void email;
    const id = `${slugify(name)}-${randomUUID().slice(0, 8)}`;
    const { error } = await this.client.from("businesses").insert({
      id,
      name,
      category: "cafe",
      description: "",
      walk_minutes: 5,
      rating: 4.5,
      lat: 48.7758,
      lng: 9.1829,
      narration: "",
      verified: false,
    });
    if (error) throw new DbNotReadyError(`registerBusiness: ${error.message}`);
    return { businessId: id, verified: false };
  }

  async verifyBusiness(businessId: string): Promise<RegisteredBusiness | null> {
    // ⚠️ MOCK verification — TODO(REAL): Google Business Profile API ownership check.
    const { data, error } = await this.client
      .from("businesses")
      .update({ verified: true })
      .eq("id", businessId)
      .select("id")
      .maybeSingle();
    if (error) throw new DbNotReadyError(`verifyBusiness: ${error.message}`);
    if (!data) return null;
    return { businessId, verified: true };
  }

  async listBusinessOffers(businessId: string): Promise<Offer[]> {
    if (businessId === DEMO_BUSINESS_ID) return this.fallback.listBusinessOffers(businessId);
    const { data, error } = await this.client
      .from("offers")
      .select("*")
      .eq("business_id", businessId);
    if (error) {
      return this.readFallback(
        "listBusinessOffers",
        error.message,
        this.fallback.listBusinessOffers(businessId),
      );
    }
    return ((data ?? []) as unknown as OfferRow[]).map(mapOffer);
  }

  async createBusinessOffer(businessId: string, input: OfferInput): Promise<Offer> {
    // The 'demo' dashboard business lives only in memory.
    if (businessId === DEMO_BUSINESS_ID) {
      return this.fallback.createBusinessOffer(businessId, input);
    }
    const slotsTotal = input.slotsTotal ?? 10;
    const { data, error } = await this.client
      .from("offers")
      .insert({
        business_id: businessId,
        perk_title: input.perkTitle,
        perk_value: input.perkValue,
        offer_type: input.offerType,
        deliverable: input.deliverable,
        min_followers: input.minFollowers ?? 0,
        slots_total: slotsTotal,
        slots_remaining: slotsTotal,
        active: true,
      })
      .select()
      .single();
    if (error) throw new DbNotReadyError(`createBusinessOffer: ${error.message}`);
    return mapOffer(data as unknown as OfferRow);
  }

  async updateOffer(offerId: string, patch: OfferPatch): Promise<Offer | null> {
    if (!UUID_RE.test(offerId)) return this.fallback.updateOffer(offerId, patch);
    const update: Record<string, unknown> = {};
    if (patch.perkTitle !== undefined) update.perk_title = patch.perkTitle;
    if (patch.perkValue !== undefined) update.perk_value = patch.perkValue;
    if (patch.offerType !== undefined) update.offer_type = patch.offerType;
    if (patch.deliverable !== undefined) update.deliverable = patch.deliverable;
    if (patch.minFollowers !== undefined) update.min_followers = patch.minFollowers;
    if (patch.slotsTotal !== undefined) update.slots_total = patch.slotsTotal;
    if (patch.slotsRemaining !== undefined) update.slots_remaining = patch.slotsRemaining;
    if (patch.active !== undefined) update.active = patch.active;
    const { data, error } = await this.client
      .from("offers")
      .update(update)
      .eq("id", offerId)
      .select()
      .maybeSingle();
    if (error) throw new DbNotReadyError(`updateOffer: ${error.message}`);
    if (!data) return null;
    return mapOffer(data as unknown as OfferRow);
  }

  async listBusinessCreators(businessId: string): Promise<BusinessCreatorRow[]> {
    if (businessId === DEMO_BUSINESS_ID) return this.fallback.listBusinessCreators(businessId);
    const { data, error } = await this.client
      .from("perks")
      .select("*")
      .eq("business_id", businessId);
    if (error) {
      return this.readFallback(
        "listBusinessCreators",
        error.message,
        this.fallback.listBusinessCreators(businessId),
      );
    }
    const perks = (data ?? []) as unknown as PerkRow[];
    if (perks.length === 0) return [];
    const userIds = [...new Set(perks.map((p) => p.user_id))];
    const [{ data: profiles }, { data: accounts }] = await Promise.all([
      this.client.from("profiles").select("id,name").in("id", userIds),
      this.client.from("social_accounts").select("user_id,handle,followers").in("user_id", userIds),
    ]);
    const profileById = new Map(
      ((profiles ?? []) as Array<{ id: string; name: string }>).map((p) => [p.id, p]),
    );
    const accountByUser = new Map(
      ((accounts ?? []) as Array<{ user_id: string; handle: string; followers: number }>).map(
        (a) => [a.user_id, a],
      ),
    );
    return perks.map((p) => {
      const claim = mapClaim(p);
      return {
        name: profileById.get(p.user_id)?.name ?? p.user_id,
        handle: accountByUser.get(p.user_id)?.handle ?? `@${p.user_id}`,
        followers: accountByUser.get(p.user_id)?.followers ?? 0,
        status: claim.status,
        etaMin: claim.etaMin,
      };
    });
  }

  async listBusinessPosts(businessId: string): Promise<BusinessPostRow[]> {
    if (businessId === DEMO_BUSINESS_ID) return this.fallback.listBusinessPosts(businessId);
    const { data, error } = await this.client
      .from("posts")
      .select("*")
      .eq("business_id", businessId);
    if (error) {
      return this.readFallback(
        "listBusinessPosts",
        error.message,
        this.fallback.listBusinessPosts(businessId),
      );
    }
    const posts = ((data ?? []) as unknown as PostRow[]).map(mapPost);
    if (posts.length === 0) return [];
    const userIds = [...new Set(posts.map((p) => p.userId))];
    const { data: accounts } = await this.client
      .from("social_accounts")
      .select("user_id,platform,handle")
      .in("user_id", userIds);
    const rows = (accounts ?? []) as Array<{
      user_id: string;
      platform: SocialPlatform;
      handle: string;
    }>;
    return posts.map((p) => {
      const account =
        rows.find((a) => a.user_id === p.userId && a.platform === p.platform) ??
        rows.find((a) => a.user_id === p.userId);
      return { ...p, creatorHandle: account?.handle ?? `@${p.userId}` };
    });
  }

  async getBusinessStats(businessId: string): Promise<BusinessStats> {
    if (businessId === DEMO_BUSINESS_ID) return this.fallback.getBusinessStats(businessId);
    const [perksRes, postsRes, offersRes] = await Promise.all([
      this.client.from("perks").select("user_id,offer_id,status").eq("business_id", businessId),
      this.client.from("posts").select("reach").eq("business_id", businessId),
      this.client.from("offers").select("id,perk_value").eq("business_id", businessId),
    ]);
    const firstError = perksRes.error ?? postsRes.error ?? offersRes.error;
    if (firstError) {
      return this.readFallback(
        "getBusinessStats",
        firstError.message,
        this.fallback.getBusinessStats(businessId),
      );
    }
    const perks = (perksRes.data ?? []) as Array<{
      user_id: string;
      offer_id: string | null;
      status: ClaimStatus;
    }>;
    const posts = (postsRes.data ?? []) as Array<{ reach: number }>;
    const valueByOffer = new Map(
      ((offersRes.data ?? []) as Array<{ id: string; perk_value: number }>).map((o) => [
        o.id,
        o.perk_value,
      ]),
    );
    const costEur = perks
      .filter((p) => p.status === "posted" || p.status === "approved" || p.status === "redeemed")
      .reduce((sum, p) => sum + (p.offer_id ? valueByOffer.get(p.offer_id) ?? 0 : 0), 0);
    return {
      creatorsHosted: new Set(perks.map((p) => p.user_id)).size,
      posts: posts.length,
      totalReach: posts.reduce((sum, p) => sum + p.reach, 0),
      costEur,
    };
  }

  async approvePerk(perkId: string): Promise<Claim | null> {
    if (!UUID_RE.test(perkId)) return this.fallback.approvePerk(perkId);
    const { data: current, error: readError } = await this.client
      .from("perks")
      .select("*")
      .eq("id", perkId)
      .maybeSingle();
    if (readError) throw new DbNotReadyError(`approvePerk/read: ${readError.message}`);
    if (!current) return null;
    assertTransition((current as unknown as PerkRow).status, "approved");
    const { data, error } = await this.client
      .from("perks")
      .update({ status: "approved", approved_at: new Date().toISOString() })
      .eq("id", perkId)
      .select()
      .maybeSingle();
    if (error) throw new DbNotReadyError(`approvePerk: ${error.message}`);
    if (!data) return null;
    return mapClaim(data as unknown as PerkRow);
  }
}

// ---------------------------------------------------------------------------
// getStore() — the switch. MOCK=1 (default) → MemoryStore; MOCK=0 + Supabase
// creds → SupabaseStore; MOCK=0 without creds → MemoryStore + a warning.
// ---------------------------------------------------------------------------

let memoryInstance: MemoryStore | null = null;
let storeInstance: Store | null = null;

export function getMemoryStore(): MemoryStore {
  if (!memoryInstance) memoryInstance = new MemoryStore();
  return memoryInstance;
}

export function getStore(): Store {
  if (storeInstance) return storeInstance;
  if (config.mock) {
    storeInstance = getMemoryStore(); // ⚠️ MOCK branch (default)
  } else if (config.supabaseUrl && config.supabaseServiceKey) {
    storeInstance = new SupabaseStore(getMemoryStore());
  } else {
    console.warn(
      "[store] ⚠️ MOCK: MOCK=0 but SUPABASE_URL / service key are missing — using the in-memory store",
    );
    storeInstance = getMemoryStore();
  }
  return storeInstance;
}
