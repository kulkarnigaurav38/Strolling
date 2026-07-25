import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Camera, Mic, Edit3, ChevronRight, ChevronLeft, Gift,
  User, Map, Plus, X, Check, Share2, Sparkles, ArrowRight,
  Star, Compass, Navigation2, MapPin,
  Clock, Heart, Trophy, Zap, CheckCircle2, Bookmark,
  Play, Pause, RefreshCw, Send, AlignLeft, FileText
} from "lucide-react";

// ─── Types ────────────────────────────────────────────────────────────────────

type Tab = "map" | "stroll" | "perks" | "profile";
type SubScreen = null | "journey" | "step" | "stoppost" | "done";
type MapMode = "explore" | "earn";

interface StopCaptures {
  photo: boolean;
  video: boolean;
  voice: boolean;
  voiceSecs: number;
  text: string;
}

interface StopDraft {
  bizId: number;
  captures: StopCaptures;
  postDone: boolean;
  savedAt: string | null;
}

interface Business {
  id: number; name: string; cat: string;
  desc: string; perk: string | null; perkVal: string | null;
  perkColor: string; required: string | null;
  distance: string; walkMin: number;
  mapX: number; mapY: number; img: string; hasPerk: boolean;
}

// ─── Constants ─────────────────────────────────────────────────────────────────

const CORAL = "#FF5C3A";
const GREEN = "#2DCE89";
const NAVY = "#1B1928";

const BUSINESSES: Business[] = [
  {
    id: 1, name: "Brot & Rösterei", cat: "Café",
    desc: "Third-wave coffee and stone-baked sourdough in the Bohnenviertel. Open from 7am.",
    perk: "2 free coffees", perkVal: "€7", perkColor: "#F5A623",
    required: "1 photo + 1 story post",
    distance: "4 min walk", walkMin: 4,
    mapX: 72, mapY: 178, img: "1495474472930-0de66167e1c9", hasPerk: true,
  },
  {
    id: 2, name: "Weinstube Fröhlich", cat: "Restaurant",
    desc: "Family-run since 1952. Swabian classics and local Trollinger wine, poured generously.",
    perk: "Free Maultaschen lunch", perkVal: "€18", perkColor: CORAL,
    required: "1 video + 1 feed post",
    distance: "8 min walk", walkMin: 8,
    mapX: 205, mapY: 148, img: "1414235077428-338989a2e8c0", hasPerk: true,
  },
  {
    id: 3, name: "Schlossplatz", cat: "Landmark",
    desc: "The heart of Stuttgart. The Neues Schloss dates from 1746 — worth stopping for the light at noon.",
    perk: null, perkVal: null, perkColor: "#888699",
    required: null, distance: "2 min walk", walkMin: 2,
    mapX: 178, mapY: 302, img: "1477959858617-67f85cf4f1df", hasPerk: false,
  },
  {
    id: 4, name: "Markthalle Stuttgart", cat: "Market",
    desc: "Art Nouveau market hall from 1914. Fresh produce, deli goods, and the best pretzels in town.",
    perk: "€15 voucher", perkVal: "€15", perkColor: GREEN,
    required: "1 reel + tag @markthalle",
    distance: "6 min walk", walkMin: 6,
    mapX: 116, mapY: 384, img: "1542838132-92c53300491e", hasPerk: true,
  },
  {
    id: 5, name: "Galerie am Schloss", cat: "Culture",
    desc: "Contemporary local artists in a 19th-century townhouse. Free entry on Thursdays.",
    perk: null, perkVal: null, perkColor: "#888699",
    required: null, distance: "5 min walk", walkMin: 5,
    mapX: 255, mapY: 285, img: "1540575467537-14c55c93a8e8", hasPerk: false,
  },
  {
    id: 6, name: "Brauhaus am Eck", cat: "Bar",
    desc: "Local craft brewery with a rooftop terrace. 12 taps, all brewed on site since 2011.",
    perk: "3 free craft beers", perkVal: "€14", perkColor: "#6C63FF",
    required: "1 video tour + story post",
    distance: "11 min walk", walkMin: 11,
    mapX: 310, mapY: 378, img: "1436076863939-06870fe779c2", hasPerk: true,
  },
  {
    id: 7, name: "Stadtgarten Kiosk", cat: "Outdoors",
    desc: "The kiosk at the edge of the Stadtgarten. Best bench in Stuttgart behind it.",
    perk: "Free pretzel + drink", perkVal: "€6", perkColor: "#F5A623",
    required: "1 photo from the bench",
    distance: "9 min walk", walkMin: 9,
    mapX: 290, mapY: 155, img: "1441974231531-c6227db2b175", hasPerk: true,
  },
];

const STROLL_STEPS = [
  {
    bizId: 1, bizName: "Brot & Rösterei", step: 1, of: 3,
    narration: "Leave the Hauptbahnhof and head south along Königstraße. At the fountain, turn right into the Bohnenviertel — the old bean quarter. Brot & Rösterei is through the second archway on your left. Order the filter coffee and find a spot at the counter by the window.",
    captureHint: "Photo of your coffee or the counter setting",
    perk: "2 free coffees · €7",
  },
  {
    bizId: 4, bizName: "Markthalle Stuttgart", step: 2, of: 3,
    narration: "Head south on Marktstraße for six minutes. The Markthalle was built in 1914 and survived the war completely intact. Step inside and look up at the iron-and-glass ceiling before you do anything else. The pretzel stall on the far side has been in the same family since the 1960s.",
    captureHint: "Video of the hall ceiling or a reel walking through the stalls",
    perk: "€15 voucher",
  },
  {
    bizId: 6, bizName: "Brauhaus am Eck", step: 3, of: 3,
    narration: "Last stop — head east along Esslinger Straße until you see the copper brew tanks through the window. The Rotbier is brewed on Tuesdays. If the tanks are going, get a shot of them. Whatever's on tap today won't be there next week.",
    captureHint: "Video toast or a close-up of the tap handles",
    perk: "3 free craft beers · €14",
  },
];

const PERKS_DATA = [
  { id: 1, biz: "Brot & Rösterei",   perk: "2 free coffees",   val: "€7",  status: "redeemed", date: "Today", color: "#F5A623" },
  { id: 2, biz: "Markthalle",        perk: "€15 voucher",      val: "€15", status: "approved", date: "Today", color: GREEN },
  { id: 3, biz: "Brauhaus am Eck",   perk: "3 craft beers",    val: "€14", status: "pending",  date: "Today", color: "#6C63FF" },
  { id: 4, biz: "Weinstube Fröhlich",perk: "Free lunch",       val: "€18", status: "redeemed", date: "12 Jul",color: CORAL },
];

function emptyCaptures(): StopCaptures {
  return { photo: false, video: false, voice: false, voiceSecs: 0, text: "" };
}

// ─── SVG City Map ──────────────────────────────────────────────────────────────

function CityMap({ mode, cart, selectedId, onPinTap, showRoute }: {
  mode: MapMode; cart: number[]; selectedId: number | null;
  onPinTap: (id: number) => void; showRoute: boolean;
}) {
  const visible = mode === "earn" ? BUSINESSES.filter(b => b.hasPerk) : BUSINESSES;
  const routePoints = cart.map(id => BUSINESSES.find(b => b.id === id)).filter(Boolean) as Business[];
  const routePath = routePoints.length > 1
    ? routePoints.map((b, i) => `${i === 0 ? "M" : "L"}${b.mapX} ${b.mapY}`).join(" ")
    : "";

  return (
    <svg viewBox="0 0 390 560" className="w-full h-full" style={{ display: "block" }}>
      <rect width="390" height="560" fill="#E9E3D6" />
      <rect x="262" y="0" width="128" height="128" fill="#C4DDA0" />
      <rect x="272" y="8" width="108" height="112" fill="#BDDBA0" rx="4" />
      {[[285,25],[305,25],[325,25],[345,25],[285,50],[305,50],[325,50],[345,50],[285,75],[305,75],[325,75],[285,100],[305,100],[325,100]].map(([cx,cy],i) => (
        <circle key={i} cx={cx} cy={cy} r="8" fill="#A8CC88" opacity={0.7} />
      ))}
      <ellipse cx="338" cy="458" rx="32" ry="18" fill="#9DC5D8" opacity={0.8} />
      <ellipse cx="338" cy="458" rx="26" ry="13" fill="#A8CDE0" opacity={0.6} />
      <rect x="142" y="252" width="82" height="80" fill="#DDD8CE" rx="2" />
      <rect x="152" y="262" width="62" height="60" fill="#D4CEBC" rx="2" />
      {[[0,0,58,118],[0,138,58,100],[0,258,58,94],[0,372,58,188],[78,0,110,98],[78,118,110,100],[78,238,110,94],[78,352,110,88],[78,460,110,100],[108,148,48,82],[244,0,48,128],[244,148,48,94],[244,262,90,80],[244,362,90,118],[244,500,90,60],[360,148,30,90],[360,258,30,94],[360,372,30,80],[360,472,30,88]].map(([x,y,w,h],i) => (
        <rect key={i} x={x} y={y} width={w} height={h} fill="#D8D2C4" rx="1" />
      ))}
      <rect x="0" y="118" width="390" height="18" fill="#F5F2EC" />
      <rect x="0" y="238" width="390" height="18" fill="#F5F2EC" />
      <rect x="0" y="352" width="390" height="18" fill="#F5F2EC" />
      <rect x="0" y="460" width="390" height="18" fill="#F5F2EC" />
      <rect x="60" y="0" width="16" height="560" fill="#F5F2EC" />
      <rect x="158" y="0" width="16" height="560" fill="#F5F2EC" />
      <rect x="244" y="0" width="16" height="560" fill="#F5F2EC" />
      <rect x="342" y="0" width="16" height="560" fill="#F5F2EC" />
      <rect x="0" y="180" width="390" height="10" fill="#EDE9E0" />
      <rect x="0" y="320" width="390" height="10" fill="#EDE9E0" />
      <rect x="0" y="420" width="390" height="10" fill="#EDE9E0" />
      <rect x="108" y="0" width="10" height="560" fill="#EDE9E0" />
      <rect x="210" y="0" width="10" height="560" fill="#EDE9E0" />
      <rect x="310" y="0" width="10" height="560" fill="#EDE9E0" />
      <text x="68" y="234" fontSize="7" fill="#B0A898" fontFamily="Nunito,sans-serif" fontWeight="600" letterSpacing="0.08em">KÖNIGSTRASSE</text>
      <text x="68" y="350" fontSize="7" fill="#B0A898" fontFamily="Nunito,sans-serif" fontWeight="600" letterSpacing="0.08em">MARKTSTRASSE</text>
      {showRoute && routePath && (
        <motion.path d={routePath} fill="none" stroke={CORAL} strokeWidth="3"
          strokeLinecap="round" strokeLinejoin="round" strokeDasharray="6 4"
          initial={{ pathLength: 0, opacity: 0 }}
          animate={{ pathLength: 1, opacity: 0.85 }}
          transition={{ duration: 1, ease: "easeInOut" }} />
      )}
      {visible.map(b => {
        const inCart = cart.includes(b.id);
        const isSelected = selectedId === b.id;
        const pinColor = b.hasPerk ? b.perkColor : "#9E9AA8";
        return (
          <motion.g key={b.id} onClick={() => onPinTap(b.id)} style={{ cursor: "pointer" }}
            whileTap={{ scale: 0.85 }}
            animate={isSelected ? { scale: [1, 1.15, 1] } : { scale: 1 }}
            transition={{ duration: 0.3 }}>
            {b.hasPerk && <circle cx={b.mapX} cy={b.mapY} r="16" fill={pinColor} opacity={0.18} />}
            <circle cx={b.mapX} cy={b.mapY} r={inCart ? 13 : 11}
              fill={inCart ? CORAL : (b.hasPerk ? pinColor : "#9E9AA8")}
              stroke="white" strokeWidth="2.5" />
            {inCart
              ? <text x={b.mapX} y={b.mapY + 4.5} textAnchor="middle" fontSize="10" fill="white">✓</text>
              : <text x={b.mapX} y={b.mapY + 4.5} textAnchor="middle" fontSize="9" fill="white">
                  {b.cat === "Café" ? "☕" : b.cat === "Restaurant" ? "🍽" : b.cat === "Bar" ? "🍺" : b.cat === "Market" ? "🧺" : b.cat === "Outdoors" ? "🌿" : "●"}
                </text>
            }
            {b.hasPerk && !inCart && (
              <g>
                <rect x={b.mapX - 16} y={b.mapY - 27} width="32" height="12" rx="6" fill={pinColor} />
                <text x={b.mapX} y={b.mapY - 19} textAnchor="middle" fontSize="7.5" fill="white" fontFamily="Nunito,sans-serif" fontWeight="800">{b.perkVal}</text>
              </g>
            )}
          </motion.g>
        );
      })}
      <motion.circle cx="175" cy="328" r="18" fill={CORAL} opacity={0.12}
        animate={{ r: [14, 22, 14] }} transition={{ repeat: Infinity, duration: 2, ease: "easeInOut" }} />
      <circle cx="175" cy="328" r="9" fill="#4A7FE5" stroke="white" strokeWidth="2.5" />
      <circle cx="175" cy="328" r="3.5" fill="white" />
    </svg>
  );
}

// ─── Onboarding ────────────────────────────────────────────────────────────────

function OnboardingScreen({ onLogin }: { onLogin: () => void }) {
  return (
    <div className="size-full flex flex-col" style={{ background: "#F8F6F2" }}>
      <div className="relative flex-1" style={{ background: "linear-gradient(160deg, #FF5C3A 0%, #FF8C42 60%, #FFB347 100%)" }}>
        <img src="https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=500&h=500&fit=crop&auto=format"
          alt="" className="absolute inset-0 w-full h-full object-cover mix-blend-multiply opacity-25" />
        <div className="relative z-10 flex flex-col items-center justify-center h-full px-8 pb-6 pt-16 text-center">
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}>
            <div className="w-16 h-16 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center mb-5 mx-auto"
              style={{ border: "1.5px solid rgba(255,255,255,0.35)" }}>
              <MapPin size={28} color="white" />
            </div>
            <h1 style={{ fontFamily: "'Fraunces', serif", fontStyle: "italic", fontSize: "3rem", fontWeight: 800, color: "white", lineHeight: 1, letterSpacing: "-0.02em" }}>
              Strolling
            </h1>
            <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "1rem", color: "rgba(255,255,255,0.85)", marginTop: 10, lineHeight: 1.5 }}>
              Walk the city.<br />Get rewarded.
            </p>
          </motion.div>
        </div>
        <div className="absolute bottom-0 left-0 right-0" style={{ height: 40 }}>
          <svg viewBox="0 0 390 40" className="w-full h-full" preserveAspectRatio="none">
            <path d="M0 40 L0 20 Q97.5 0 195 20 Q292.5 40 390 20 L390 40 Z" fill="#F8F6F2" />
          </svg>
        </div>
      </div>
      <div className="px-6 pb-10 pt-2 flex flex-col gap-3">
        <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.78rem", color: "#888699", textAlign: "center", marginBottom: 4 }}>
          Connect to unlock perks and track your reach
        </p>
        {[
          { label: "Continue with Instagram", bg: "linear-gradient(45deg,#F58529,#DD2A7B,#8134AF)", icon: "📸" },
          { label: "Continue with Facebook",  bg: "#1877F2", icon: "f" },
          { label: "Continue with Google",    bg: "white",   icon: "G", outline: true },
        ].map((opt, i) => (
          <motion.button key={opt.label}
            className="w-full py-3.5 rounded-2xl flex items-center justify-center gap-3 font-bold"
            style={{ background: opt.bg, color: opt.outline ? NAVY : "white",
              border: opt.outline ? `1.5px solid rgba(27,25,40,0.12)` : "none",
              fontFamily: "'Nunito', sans-serif", fontSize: "0.9rem", fontWeight: 700,
              boxShadow: opt.outline ? "0 2px 8px rgba(0,0,0,0.06)" : "0 4px 16px rgba(0,0,0,0.15)" }}
            initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 + i * 0.07 }}
            whileTap={{ scale: 0.97 }} onClick={onLogin}>
            <span style={{ fontSize: "1.1rem", width: 20, textAlign: "center" }}>{opt.icon}</span>
            {opt.label}
          </motion.button>
        ))}
        <button style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.8rem", color: "#888699", marginTop: 4 }} onClick={onLogin}>
          Browse without an account →
        </button>
      </div>
    </div>
  );
}

// ─── Business bottom sheet ─────────────────────────────────────────────────────

function BusinessSheet({ biz, inCart, onAdd, onRemove, onClose }: {
  biz: Business; inCart: boolean; onAdd: () => void; onRemove: () => void; onClose: () => void;
}) {
  return (
    <motion.div className="absolute bottom-0 left-0 right-0 rounded-t-3xl overflow-hidden"
      style={{ background: "white", zIndex: 30, boxShadow: "0 -8px 40px rgba(0,0,0,0.14)" }}
      initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }}
      transition={{ type: "spring", damping: 28, stiffness: 320 }}>
      <div className="flex justify-center pt-3 pb-1">
        <div className="w-10 h-1 rounded-full" style={{ background: "rgba(27,25,40,0.12)" }} />
      </div>
      <div className="relative mx-4 rounded-2xl overflow-hidden" style={{ height: 160 }}>
        <img src={`https://images.unsplash.com/photo-${biz.img}?w=500&h=320&fit=crop&auto=format`}
          alt={biz.name} className="w-full h-full object-cover" />
        {biz.hasPerk && (
          <div className="absolute top-3 left-3 px-3 py-1.5 rounded-full flex items-center gap-1.5"
            style={{ background: biz.perkColor, boxShadow: `0 2px 10px ${biz.perkColor}60` }}>
            <Gift size={12} color="white" />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 800, color: "white" }}>{biz.perk}</span>
          </div>
        )}
        <button className="absolute top-3 right-3 w-8 h-8 rounded-full flex items-center justify-center"
          style={{ background: "rgba(0,0,0,0.4)" }} onClick={onClose}>
          <X size={16} color="white" />
        </button>
      </div>
      <div className="px-5 pt-4 pb-6">
        <div className="flex items-start justify-between mb-1">
          <div>
            <h2 style={{ fontFamily: "'Fraunces', serif", fontSize: "1.4rem", fontWeight: 700, color: NAVY }}>{biz.name}</h2>
            <div className="flex items-center gap-2 mt-0.5">
              <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", color: "#888699" }}>{biz.cat}</span>
              <span style={{ color: "#CCC8C0" }}>·</span>
              <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", color: "#888699" }}>{biz.distance}</span>
              <span style={{ color: "#CCC8C0" }}>·</span>
              <div className="flex items-center gap-0.5">
                <Star size={11} fill="#F5A623" stroke="none" />
                <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", color: "#888699" }}>4.8</span>
              </div>
            </div>
          </div>
          {biz.hasPerk && (
            <div className="text-right">
              <div style={{ fontFamily: "'Fraunces', serif", fontSize: "1.3rem", fontWeight: 700, color: biz.perkColor }}>{biz.perkVal}</div>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.65rem", color: "#888699" }}>perk value</div>
            </div>
          )}
        </div>
        <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.82rem", color: NAVY, lineHeight: 1.55, opacity: 0.72, marginTop: 8, marginBottom: 12 }}>{biz.desc}</p>
        {biz.hasPerk && biz.required && (
          <div className="flex items-center gap-2 px-3 py-2 rounded-xl mb-4" style={{ background: "#F8F6F2" }}>
            <Zap size={13} fill={biz.perkColor} stroke="none" />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", color: "#888699" }}>Deliver: </span>
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", fontWeight: 700, color: NAVY }}>{biz.required}</span>
          </div>
        )}
        <div className="flex gap-3">
          {inCart ? (
            <button className="flex-1 py-3.5 rounded-2xl flex items-center justify-center gap-2 font-bold"
              style={{ background: "#F2EFE8", color: "#888699", fontFamily: "'Nunito', sans-serif", fontWeight: 700 }}
              onClick={onRemove}>
              <Check size={16} color={GREEN} /> Added to stroll
            </button>
          ) : (
            <motion.button className="flex-1 py-3.5 rounded-2xl flex items-center justify-center gap-2 font-bold"
              style={{ background: CORAL, color: "white", fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "0.9rem", boxShadow: `0 4px 16px ${CORAL}50` }}
              whileTap={{ scale: 0.97 }} onClick={onAdd}>
              <Plus size={17} /> Add to stroll
            </motion.button>
          )}
          <button className="px-5 py-3.5 rounded-2xl font-bold text-sm"
            style={{ background: "#F2EFE8", color: NAVY, fontFamily: "'Nunito', sans-serif", fontWeight: 700 }}>
            More
          </button>
        </div>
      </div>
    </motion.div>
  );
}

// ─── Mode Switch (prominent hero card) ────────────────────────────────────────

function ModeSwitchCard({ mode, onSwitch }: { mode: MapMode; onSwitch: (m: MapMode) => void }) {
  return (
    <div className="mx-4 rounded-2xl overflow-hidden flex"
      style={{ background: "white", boxShadow: "0 4px 20px rgba(0,0,0,0.13)", border: "1.5px solid rgba(27,25,40,0.06)" }}>
      {/* Explore option */}
      <button className="flex-1 relative flex flex-col items-center py-3 px-2 gap-1 transition-all"
        style={{ background: mode === "explore" ? NAVY : "transparent" }}
        onClick={() => onSwitch("explore")}>
        {mode === "explore" && (
          <motion.div className="absolute inset-0 rounded-xl" style={{ background: NAVY }}
            layoutId="modeHighlight" transition={{ type: "spring", damping: 22, stiffness: 300 }} />
        )}
        <div className="relative z-10 flex flex-col items-center gap-1">
          <Compass size={20} color={mode === "explore" ? "white" : "#B0ACBC"} />
          <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "0.78rem",
            color: mode === "explore" ? "white" : "#888699" }}>Roam the city</span>
          <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.63rem",
            color: mode === "explore" ? "rgba(255,255,255,0.65)" : "#C0BBCC", textAlign: "center", lineHeight: 1.3 }}>
            Every place, no obligations
          </span>
        </div>
      </button>

      {/* Divider */}
      <div style={{ width: 1, background: "rgba(27,25,40,0.08)", margin: "8px 0" }} />

      {/* Earn perks option */}
      <button className="flex-1 relative flex flex-col items-center py-3 px-2 gap-1 transition-all"
        style={{ background: mode === "earn" ? CORAL : "transparent" }}
        onClick={() => onSwitch("earn")}>
        {mode === "earn" && (
          <motion.div className="absolute inset-0 rounded-xl" style={{ background: CORAL }}
            layoutId="modeHighlight" transition={{ type: "spring", damping: 22, stiffness: 300 }} />
        )}
        <div className="relative z-10 flex flex-col items-center gap-1">
          <Gift size={20} color={mode === "earn" ? "white" : "#B0ACBC"} />
          <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "0.78rem",
            color: mode === "earn" ? "white" : "#888699" }}>Earn incentives</span>
          <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.63rem",
            color: mode === "earn" ? "rgba(255,255,255,0.65)" : "#C0BBCC", textAlign: "center", lineHeight: 1.3 }}>
            Perks for posting
          </span>
        </div>
      </button>
    </div>
  );
}

// ─── Map screen ────────────────────────────────────────────────────────────────

function MapScreen({ cart, setCart, onCreateStroll }: {
  cart: number[]; setCart: (c: number[]) => void; onCreateStroll: () => void;
}) {
  const [mode, setMode] = useState<MapMode>("explore");
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [activeFilter, setActiveFilter] = useState<string | null>(null);
  const selectedBiz = selectedId !== null ? BUSINESSES.find(b => b.id === selectedId) : null;

  const handleAdd = () => { if (selectedId && !cart.includes(selectedId)) setCart([...cart, selectedId]); };
  const handleRemove = () => { if (selectedId) setCart(cart.filter(id => id !== selectedId)); };

  return (
    <div className="size-full flex flex-col relative overflow-hidden">
      <div className="absolute inset-0">
        <CityMap mode={mode} cart={cart} selectedId={selectedId}
          onPinTap={id => setSelectedId(id === selectedId ? null : id)} showRoute={cart.length > 1} />
      </div>

      {/* Top bar */}
      <div className="relative z-20 pt-12 pb-3 flex flex-col gap-3 pointer-events-none">
        {/* Mode switch */}
        <div className="pointer-events-auto">
          <ModeSwitchCard mode={mode} onSwitch={setMode} />
        </div>

        {/* Filter chips */}
        <div className="flex gap-2 px-4 overflow-x-auto pb-1 pointer-events-auto" style={{ scrollbarWidth: "none" }}>
          {["All","Café","Food","Drinks","Culture","Market"].map(f => (
            <button key={f}
              className="flex-shrink-0 px-3.5 py-1.5 rounded-full text-xs font-bold"
              style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700,
                background: activeFilter === f ? NAVY : "white", color: activeFilter === f ? "white" : NAVY,
                boxShadow: "0 2px 8px rgba(0,0,0,0.1)" }}
              onClick={() => setActiveFilter(activeFilter === f ? null : f)}>{f}
            </button>
          ))}
        </div>
      </div>

      {/* Business sheet */}
      <AnimatePresence>
        {selectedBiz && (
          <BusinessSheet key={selectedBiz.id} biz={selectedBiz}
            inCart={cart.includes(selectedBiz.id)}
            onAdd={handleAdd} onRemove={handleRemove}
            onClose={() => setSelectedId(null)} />
        )}
      </AnimatePresence>

      {/* Cart pill */}
      <AnimatePresence>
        {!selectedBiz && (
          <motion.div className="absolute bottom-0 left-0 right-0 px-4 pb-6 z-20"
            initial={{ y: 80, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 80, opacity: 0 }}
            transition={{ type: "spring", damping: 26, stiffness: 300 }}>
            <div className="rounded-3xl p-4 flex items-center gap-4"
              style={{ background: "white", boxShadow: "0 8px 32px rgba(0,0,0,0.15)" }}>
              <div className="w-12 h-12 rounded-2xl flex-shrink-0 flex items-center justify-center"
                style={{ background: "linear-gradient(135deg, #FF5C3A, #FF8C42)" }}>
                <span style={{ fontSize: "1.4rem" }}>🧍</span>
              </div>
              <div className="flex-1 min-w-0">
                {cart.length === 0
                  ? <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.82rem", color: "#888699" }}>Tap a pin to add a stop</p>
                  : <>
                      <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", fontWeight: 700, color: "#888699", marginBottom: 2 }}>
                        {cart.length} stop{cart.length > 1 ? "s" : ""} added
                      </p>
                      <div className="flex gap-1.5">
                        {cart.map(id => {
                          const b = BUSINESSES.find(x => x.id === id)!;
                          return (
                            <div key={id} className="w-7 h-7 rounded-full flex items-center justify-center text-xs"
                              style={{ background: b.perkColor + "22", border: `2px solid ${b.perkColor}` }}>
                              {b.cat === "Café" ? "☕" : b.cat === "Restaurant" ? "🍽" : b.cat === "Bar" ? "🍺" : "●"}
                            </div>
                          );
                        })}
                      </div>
                    </>
                }
              </div>
              <motion.button
                className="flex-shrink-0 px-5 py-3 rounded-2xl font-bold flex items-center gap-1.5"
                style={{ background: cart.length >= 2 ? CORAL : "#F2EFE8",
                  color: cart.length >= 2 ? "white" : "#888699",
                  fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "0.82rem",
                  boxShadow: cart.length >= 2 ? `0 4px 16px ${CORAL}50` : "none" }}
                whileTap={cart.length >= 2 ? { scale: 0.95 } : {}}
                onClick={cart.length >= 2 ? onCreateStroll : undefined}>
                {cart.length >= 2 ? "Create stroll" : "Add 2+ stops"}
                {cart.length >= 2 && <ArrowRight size={15} />}
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

// ─── Journey screen ────────────────────────────────────────────────────────────

function JourneyScreen({ cart, drafts, onStart, onBack }: {
  cart: number[]; drafts: StopDraft[]; onStart: (idx: number) => void; onBack: () => void;
}) {
  const stops = cart.map(id => BUSINESSES.find(b => b.id === id)).filter(Boolean) as Business[];
  const totalMin = stops.reduce((a, b) => a + b.walkMin + 25, 0);

  const getDraft = (bizId: number) => drafts.find(d => d.bizId === bizId);
  const captureCount = (d: StopDraft | undefined) => {
    if (!d) return 0;
    return (d.captures.photo ? 1 : 0) + (d.captures.voice ? 1 : 0) + (d.captures.text.length > 0 ? 1 : 0);
  };

  return (
    <motion.div className="size-full flex flex-col" style={{ background: "#F8F6F2" }}
      initial={{ x: "100%" }} animate={{ x: 0 }} exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 28, stiffness: 280 }}>

      <div className="relative flex-shrink-0" style={{ height: 200 }}>
        <div className="absolute inset-0 overflow-hidden">
          <CityMap mode="earn" cart={cart} selectedId={null} onPinTap={() => {}} showRoute />
        </div>
        <div className="absolute inset-0" style={{ background: "linear-gradient(to bottom, transparent 60%, #F8F6F2 100%)" }} />
        <button className="absolute top-12 left-4 w-10 h-10 rounded-full flex items-center justify-center"
          style={{ background: "white", boxShadow: "0 2px 12px rgba(0,0,0,0.12)" }} onClick={onBack}>
          <ChevronLeft size={20} color={NAVY} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pb-32" style={{ scrollbarWidth: "none" }}>
        <h1 style={{ fontFamily: "'Fraunces', serif", fontStyle: "italic", fontSize: "1.9rem", fontWeight: 800, color: NAVY, letterSpacing: "-0.02em", marginBottom: 4 }}>
          Your stroll
        </h1>
        <div className="flex items-center gap-3 mb-6">
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full" style={{ background: "#F2EFE8" }}>
            <Clock size={13} color="#888699" />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", fontWeight: 700, color: NAVY }}>~{totalMin} min</span>
          </div>
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full" style={{ background: "#F2EFE8" }}>
            <MapPin size={13} color="#888699" />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", fontWeight: 700, color: NAVY }}>{stops.length} stops</span>
          </div>
          {stops.some(s => s.hasPerk) && (
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full" style={{ background: CORAL + "15" }}>
              <Gift size={13} color={CORAL} />
              <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", fontWeight: 700, color: CORAL }}>
                {stops.filter(s => s.hasPerk).map(s => s.perkVal).join(" + ")}
              </span>
            </div>
          )}
        </div>

        {/* Starting point */}
        <div className="flex gap-3 mb-1 px-1">
          <div className="flex flex-col items-center">
            <div className="w-4 h-4 rounded-full border-2 flex-shrink-0 mt-1" style={{ background: "#4A7FE5", borderColor: "#4A7FE5" }} />
            <div className="w-px flex-1 my-1" style={{ background: "#DDD8CE", minHeight: 16 }} />
          </div>
          <div className="pb-4">
            <p style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "0.8rem", color: NAVY }}>You are here</p>
            <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", color: "#888699" }}>Stuttgart Hbf — step out the main exit and head south on Königstraße</p>
          </div>
        </div>

        {stops.map((b, i) => {
          const stepIdx = STROLL_STEPS.findIndex(s => s.bizId === b.id);
          const draft = getDraft(b.id);
          const count = captureCount(draft);
          const postDone = draft?.postDone ?? false;

          return (
            <div key={b.id}>
              <div className="flex gap-3">
                <div className="flex flex-col items-center flex-shrink-0">
                  <div className="w-9 h-9 rounded-full flex items-center justify-center text-white font-bold text-sm flex-shrink-0"
                    style={{ background: postDone ? GREEN : b.hasPerk ? b.perkColor : "#9E9AA8",
                      boxShadow: b.hasPerk ? `0 2px 10px ${b.perkColor}50` : "none",
                      fontFamily: "'Nunito', sans-serif", fontWeight: 800 }}>
                    {postDone ? <CheckCircle2 size={18} /> : i + 1}
                  </div>
                  {i < stops.length - 1 && (
                    <div className="w-px flex-1 my-1.5 border-l-2 border-dashed" style={{ borderColor: "#DDD8CE", minHeight: 24 }} />
                  )}
                </div>
                <div className="pb-5 flex-1 min-w-0">
                  <div className="rounded-2xl overflow-hidden" style={{ background: "white", border: "1px solid rgba(27,25,40,0.07)", boxShadow: "0 2px 12px rgba(0,0,0,0.06)" }}>
                    <div className="relative">
                      <img src={`https://images.unsplash.com/photo-${b.img}?w=400&h=140&fit=crop&auto=format`}
                        alt={b.name} className="w-full object-cover" style={{ height: 90 }} />
                      {/* Status overlay */}
                      {postDone && (
                        <div className="absolute inset-0 flex items-center justify-center" style={{ background: "rgba(45,206,137,0.7)" }}>
                          <CheckCircle2 size={32} color="white" strokeWidth={2.5} />
                        </div>
                      )}
                      {count > 0 && !postDone && (
                        <div className="absolute top-2 right-2 px-2 py-1 rounded-full" style={{ background: CORAL }}>
                          <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.65rem", fontWeight: 800, color: "white" }}>{count} captured</span>
                        </div>
                      )}
                    </div>
                    <div className="p-3">
                      <div className="flex items-center justify-between mb-2">
                        <div>
                          <h3 style={{ fontFamily: "'Fraunces', serif", fontSize: "1rem", fontWeight: 700, color: NAVY }}>{b.name}</h3>
                          <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.7rem", color: "#888699" }}>{b.cat} · {b.distance}</p>
                        </div>
                        {b.hasPerk && (
                          <div className="flex items-center gap-1 px-2.5 py-1 rounded-full ml-2" style={{ background: b.perkColor + "18", border: `1px solid ${b.perkColor}30` }}>
                            <Gift size={10} color={b.perkColor} />
                            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.68rem", fontWeight: 800, color: b.perkColor }}>{b.perkVal}</span>
                          </div>
                        )}
                      </div>

                      {/* Action button per stop */}
                      {postDone ? (
                        <div className="flex items-center gap-1.5 px-3 py-2 rounded-xl" style={{ background: GREEN + "12" }}>
                          <CheckCircle2 size={13} color={GREEN} />
                          <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 700, color: GREEN }}>Post published · perk unlocked</span>
                        </div>
                      ) : count > 0 ? (
                        <div className="flex gap-2">
                          <button className="flex-1 py-2 rounded-xl flex items-center justify-center gap-1.5"
                            style={{ background: CORAL + "12", border: `1.5px solid ${CORAL}30` }}
                            onClick={() => onStart(i)}>
                            <RefreshCw size={12} color={CORAL} />
                            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 700, color: CORAL }}>Resume capture</span>
                          </button>
                          <button className="px-4 py-2 rounded-xl flex items-center justify-center gap-1.5"
                            style={{ background: NAVY }}
                            onClick={() => onStart(i)}>
                            <Send size={12} color="white" />
                            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 700, color: "white" }}>Post</span>
                          </button>
                        </div>
                      ) : (
                        <button className="w-full py-2 rounded-xl flex items-center justify-center gap-1.5"
                          style={{ background: stepIdx !== -1 ? CORAL : "#F2EFE8" }}
                          onClick={() => stepIdx !== -1 && onStart(i)}>
                          <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 700, color: stepIdx !== -1 ? "white" : "#888699" }}>
                            {stepIdx !== -1 ? "Start capture" : "Explore only"}
                          </span>
                        </button>
                      )}
                    </div>
                  </div>

                  {i < stops.length - 1 && (
                    <div className="flex items-center gap-1.5 mt-2 pl-2">
                      <Navigation2 size={11} color="#888699" />
                      <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.7rem", color: "#888699" }}>
                        {stops[i + 1].distance} to next stop
                      </span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="absolute bottom-0 left-0 right-0 px-5 pb-8 pt-4"
        style={{ background: "linear-gradient(to top, #F8F6F2 70%, transparent)" }}>
        <motion.button className="w-full py-4 rounded-2xl font-bold text-base flex items-center justify-center gap-2"
          style={{ background: CORAL, color: "white", fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "1rem", boxShadow: `0 6px 24px ${CORAL}50` }}
          whileTap={{ scale: 0.97 }} onClick={() => onStart(0)}>
          Start strolling <ArrowRight size={18} />
        </motion.button>
      </div>
    </motion.div>
  );
}

// ─── Step screen (per-stop capture) ───────────────────────────────────────────

function StepScreen({ stepIndex, draft, onDraftChange, onPost, onSaveResume, onBack }: {
  stepIndex: number;
  draft: StopDraft;
  onDraftChange: (d: StopDraft) => void;
  onPost: () => void;
  onSaveResume: () => void;
  onBack: () => void;
}) {
  const step = STROLL_STEPS[stepIndex];
  const biz = BUSINESSES.find(b => b.id === step.bizId)!;
  const [recording, setRecording] = useState(false);
  const [waveLevel, setWaveLevel] = useState(0);
  const [recSecs, setRecSecs] = useState(draft.captures.voiceSecs);
  const recInterval = useRef<ReturnType<typeof setInterval> | null>(null);
  const [editingText, setEditingText] = useState(false);

  useEffect(() => {
    setRecording(false);
    setRecSecs(draft.captures.voiceSecs);
    setEditingText(false);
  }, [stepIndex]);

  useEffect(() => {
    if (!recording) { setWaveLevel(0); return; }
    const wId = setInterval(() => setWaveLevel(Math.random() * 100), 90);
    recInterval.current = setInterval(() => setRecSecs(s => s + 1), 1000);
    return () => { clearInterval(wId); if (recInterval.current) clearInterval(recInterval.current); };
  }, [recording]);

  const captures = draft.captures;
  const hasAny = captures.photo || captures.voice || captures.text.length > 0;

  const update = (patch: Partial<StopCaptures>) =>
    onDraftChange({ ...draft, captures: { ...captures, ...patch } });

  const fmtSecs = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;

  return (
    <motion.div className="size-full flex flex-col" style={{ background: "#F8F6F2" }}
      initial={{ x: "100%" }} animate={{ x: 0 }} exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 28, stiffness: 280 }}>

      {/* Progress bar */}
      <div className="flex-shrink-0 pt-12 px-5 pb-3">
        <div className="flex items-center gap-2 mb-1">
          <button onClick={onBack}><ChevronLeft size={22} color={NAVY} /></button>
          <div className="flex-1 flex gap-1.5">
            {STROLL_STEPS.map((_, i) => (
              <div key={i} className="flex-1 rounded-full h-1.5 overflow-hidden" style={{ background: "#E8E4DA" }}>
                <motion.div className="h-full rounded-full" style={{ background: CORAL }}
                  initial={{ width: 0 }} animate={{ width: i <= stepIndex ? "100%" : "0%" }}
                  transition={{ duration: 0.4 }} />
              </div>
            ))}
          </div>
          <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 700, color: "#888699" }}>
            {stepIndex + 1}/{STROLL_STEPS.length}
          </span>
        </div>
      </div>

      {/* Business photo */}
      <div className="flex-shrink-0 mx-5 rounded-2xl overflow-hidden relative mb-3" style={{ height: 155 }}>
        <img src={`https://images.unsplash.com/photo-${biz.img}?w=500&h=310&fit=crop&auto=format`}
          alt={biz.name} className="w-full h-full object-cover" />
        <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgba(27,25,40,0.7) 0%, transparent 55%)" }} />
        <div className="absolute bottom-3 left-4 right-4 flex items-end justify-between">
          <div>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.65rem", fontWeight: 700, color: "rgba(255,255,255,0.7)", letterSpacing: "0.06em" }}>
              STOP {step.step} OF {step.of}
            </div>
            <h2 style={{ fontFamily: "'Fraunces', serif", fontSize: "1.2rem", fontWeight: 700, color: "white" }}>{step.bizName}</h2>
          </div>
          {biz.hasPerk && (
            <div className="px-2.5 py-1.5 rounded-full flex items-center gap-1"
              style={{ background: biz.perkColor, boxShadow: `0 2px 8px ${biz.perkColor}60` }}>
              <Gift size={11} color="white" />
              <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.65rem", fontWeight: 800, color: "white" }}>{biz.perkVal}</span>
            </div>
          )}
        </div>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto px-5 pb-2" style={{ scrollbarWidth: "none" }}>
        {/* Narration */}
        <div className="rounded-2xl p-4 mb-4" style={{ background: "white", border: "1px solid rgba(27,25,40,0.07)" }}>
          <div className="flex items-center gap-1.5 mb-2">
            <Sparkles size={13} color={CORAL} />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.68rem", fontWeight: 800, color: CORAL, letterSpacing: "0.06em" }}>YOUR SCRIPT</span>
          </div>
          <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.84rem", color: NAVY, lineHeight: 1.65 }}>{step.narration}</p>
          <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.73rem", color: "#888699", marginTop: 8, fontStyle: "italic" }}>
            📍 {step.captureHint}
          </p>
        </div>

        {/* ── Capture section label */}
        <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 800, color: "#888699", letterSpacing: "0.06em", marginBottom: 10 }}>
          CAPTURE THIS STOP — add any or all
        </p>

        {/* ── Photo / Video card */}
        <motion.div className="rounded-2xl overflow-hidden mb-3"
          style={{ background: "white", border: `2px solid ${captures.photo ? CORAL : "rgba(27,25,40,0.07)"}`,
            boxShadow: captures.photo ? `0 4px 16px ${CORAL}20` : "0 2px 10px rgba(0,0,0,0.05)" }}>
          {captures.photo ? (
            <div className="relative">
              <img src={`https://images.unsplash.com/photo-${biz.img}?w=400&h=200&fit=crop&auto=format`}
                alt="" className="w-full object-cover" style={{ height: 140 }} />
              <div className="absolute inset-0 flex items-center justify-center"
                style={{ background: "rgba(0,0,0,0.3)" }}>
                <div className="w-12 h-12 rounded-full flex items-center justify-center" style={{ background: GREEN }}>
                  <Check size={22} color="white" strokeWidth={3} />
                </div>
              </div>
              <div className="p-3 flex items-center justify-between">
                <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.78rem", fontWeight: 700, color: GREEN }}>✓ Photo captured</span>
                <button onClick={() => update({ photo: false })}
                  style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", color: "#888699" }}>Redo</button>
              </div>
            </div>
          ) : (
            <button className="w-full p-4 flex items-center gap-4" onClick={() => update({ photo: true })}>
              <div className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0"
                style={{ background: "#F2EFE8" }}>
                <Camera size={22} color={NAVY} />
              </div>
              <div className="text-left flex-1">
                <p style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "0.88rem", color: NAVY }}>Photo or Video</p>
                <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", color: "#888699" }}>Opens camera · stays inside the app</p>
              </div>
              <Plus size={18} color="#C8C4BC" />
            </button>
          )}
        </motion.div>

        {/* ── Voice note card */}
        <motion.div className="rounded-2xl overflow-hidden mb-3"
          style={{ background: "white", border: `2px solid ${captures.voice || recording ? CORAL : "rgba(27,25,40,0.07)"}`,
            boxShadow: captures.voice ? `0 4px 16px ${CORAL}20` : "0 2px 10px rgba(0,0,0,0.05)" }}>
          {captures.voice && !recording ? (
            <div className="p-4 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0" style={{ background: GREEN + "20" }}>
                <Mic size={18} color={GREEN} />
              </div>
              <div className="flex-1">
                <p style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "0.82rem", color: GREEN }}>✓ Voice note saved — {fmtSecs(recSecs)}</p>
                <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.7rem", color: "#888699" }}>Your words become the voiceover</p>
              </div>
              <button onClick={() => { setRecording(true); setRecSecs(0); update({ voice: false, voiceSecs: 0 }); }}
                style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", color: "#888699" }}>Redo</button>
            </div>
          ) : recording ? (
            <div className="p-4">
              <div className="flex items-center gap-2 mb-3">
                <motion.div animate={{ opacity: [1, 0.3, 1] }} transition={{ repeat: Infinity, duration: 0.8 }}
                  className="w-2 h-2 rounded-full" style={{ background: "#E53935" }} />
                <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", fontWeight: 700, color: "#E53935" }}>
                  Recording — {fmtSecs(recSecs)}
                </span>
                <button className="ml-auto px-3 py-1.5 rounded-xl"
                  style={{ background: CORAL, fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 700, color: "white" }}
                  onClick={() => { setRecording(false); update({ voice: true, voiceSecs: recSecs }); }}>
                  Stop
                </button>
              </div>
              <div className="flex items-center justify-center gap-0.5 h-10">
                {Array.from({ length: 36 }).map((_, i) => (
                  <motion.div key={i} className="w-[3px] rounded-full" style={{ background: CORAL }}
                    animate={{ height: `${6 + Math.random() * 26 * (waveLevel / 100)}px` }}
                    transition={{ duration: 0.09 }} />
                ))}
              </div>
            </div>
          ) : (
            <button className="w-full p-4 flex items-center gap-4" onClick={() => setRecording(true)}>
              <div className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" style={{ background: "#F2EFE8" }}>
                <Mic size={22} color={NAVY} />
              </div>
              <div className="text-left flex-1">
                <p style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "0.88rem", color: NAVY }}>Voice note</p>
                <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", color: "#888699" }}>Narrate your experience · becomes caption audio</p>
              </div>
              <Plus size={18} color="#C8C4BC" />
            </button>
          )}
        </motion.div>

        {/* ── Text / write card */}
        <motion.div className="rounded-2xl overflow-hidden mb-4"
          style={{ background: "white", border: `2px solid ${captures.text.length > 0 ? CORAL : "rgba(27,25,40,0.07)"}`,
            boxShadow: captures.text.length > 0 ? `0 4px 16px ${CORAL}20` : "0 2px 10px rgba(0,0,0,0.05)" }}>
          {editingText || captures.text.length > 0 ? (
            <div className="p-4">
              <div className="flex items-center gap-2 mb-2">
                <AlignLeft size={13} color={CORAL} />
                <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.68rem", fontWeight: 800, color: CORAL }}>YOUR NOTES</span>
              </div>
              <textarea
                className="w-full resize-none outline-none"
                rows={4}
                style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.84rem", color: NAVY, lineHeight: 1.6, background: "transparent", border: "none" }}
                placeholder="Write what you see, feel, or want to share…"
                value={captures.text}
                onFocus={() => setEditingText(true)}
                onBlur={() => setEditingText(false)}
                onChange={e => update({ text: e.target.value })}
              />
              {captures.text.length > 0 && (
                <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.65rem", color: "#888699", marginTop: 4 }}>
                  {captures.text.length} chars · becomes post caption
                </p>
              )}
            </div>
          ) : (
            <button className="w-full p-4 flex items-center gap-4" onClick={() => setEditingText(true)}>
              <div className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" style={{ background: "#F2EFE8" }}>
                <Edit3 size={22} color={NAVY} />
              </div>
              <div className="text-left flex-1">
                <p style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "0.88rem", color: NAVY }}>Write a note</p>
                <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", color: "#888699" }}>Thoughts, impressions, what to say in the caption</p>
              </div>
              <Plus size={18} color="#C8C4BC" />
            </button>
          )}
        </motion.div>
      </div>

      {/* Bottom actions */}
      <div className="flex-shrink-0 px-5 pb-8 pt-3 flex flex-col gap-2.5">
        <motion.button className="w-full py-4 rounded-2xl font-bold flex items-center justify-center gap-2"
          style={{ background: hasAny ? CORAL : "#F2EFE8", color: hasAny ? "white" : "#888699",
            fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "0.95rem",
            boxShadow: hasAny ? `0 6px 20px ${CORAL}45` : "none" }}
          whileTap={hasAny ? { scale: 0.97 } : {}}
          onClick={hasAny ? onPost : undefined}>
          {hasAny ? <>Build post for this stop <ArrowRight size={17} /></> : "Capture something first"}
        </motion.button>

        <div className="flex gap-2.5">
          <button className="flex-1 py-3 rounded-2xl flex items-center justify-center gap-1.5"
            style={{ background: "#F2EFE8" }}
            onClick={onSaveResume}>
            <Bookmark size={14} color="#888699" />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.78rem", fontWeight: 700, color: "#888699" }}>Save & come back</span>
          </button>
          <button className="flex-1 py-3 rounded-2xl text-center"
            style={{ background: "#F2EFE8" }}
            onClick={onBack}>
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.78rem", fontWeight: 700, color: "#888699" }}>← Back to stroll</span>
          </button>
        </div>
      </div>
    </motion.div>
  );
}

// ─── Per-stop post builder ─────────────────────────────────────────────────────

function StopPostScreen({ stepIndex, draft, onPublish, onBack }: {
  stepIndex: number;
  draft: StopDraft;
  onPublish: () => void;
  onBack: () => void;
}) {
  const step = STROLL_STEPS[stepIndex];
  const biz = BUSINESSES.find(b => b.id === step.bizId)!;
  const [caption, setCaption] = useState(
    draft.captures.text.length > 0
      ? draft.captures.text
      : `Just stopped by ${step.bizName} on my Stuttgart stroll. ${biz.hasPerk ? `${biz.perk} — absolutely worth it. 🙌` : "One of those hidden-gem spots you only find on foot. 🚶"}  #Stuttgart #Strolling #CityWalk`
  );
  const [activeShare, setActiveShare] = useState<string | null>(null);

  const platforms = [
    { name: "Instagram", bg: "linear-gradient(45deg,#F58529,#DD2A7B,#8134AF)", icon: "📸" },
    { name: "TikTok",    bg: "#000000", icon: "🎵" },
    { name: "Facebook",  bg: "#1877F2", icon: "f" },
  ];

  return (
    <motion.div className="size-full flex flex-col" style={{ background: "#F8F6F2" }}
      initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }}
      transition={{ type: "spring", damping: 28, stiffness: 280 }}>

      {/* Header */}
      <div className="flex-shrink-0 px-5 pt-12 pb-4 flex items-center gap-3"
        style={{ background: "white", borderBottom: "1px solid rgba(27,25,40,0.07)" }}>
        <button onClick={onBack} className="w-9 h-9 rounded-full flex items-center justify-center" style={{ background: "#F2EFE8" }}>
          <ChevronLeft size={20} color={NAVY} />
        </button>
        <div className="flex-1">
          <h2 style={{ fontFamily: "'Fraunces', serif", fontSize: "1.2rem", fontWeight: 700, color: NAVY }}>Post — {step.bizName}</h2>
          <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.7rem", color: "#888699" }}>Stop {step.step} of {step.of}</p>
        </div>
        {biz.hasPerk && (
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full" style={{ background: biz.perkColor }}>
            <Gift size={12} color="white" />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.7rem", fontWeight: 800, color: "white" }}>{biz.perkVal}</span>
          </div>
        )}
      </div>

      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-28" style={{ scrollbarWidth: "none" }}>
        {/* Captured media preview */}
        <div className="flex gap-2 mb-4">
          {draft.captures.photo && (
            <div className="flex-1 rounded-2xl overflow-hidden relative" style={{ height: 180 }}>
              <img src={`https://images.unsplash.com/photo-${biz.img}?w=300&h=360&fit=crop&auto=format`}
                alt="" className="w-full h-full object-cover" />
              <div className="absolute bottom-2 left-2 px-2 py-1 rounded-full" style={{ background: "rgba(0,0,0,0.5)" }}>
                <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.62rem", color: "white" }}>📸 Photo</span>
              </div>
            </div>
          )}
          {draft.captures.voice && (
            <div className="flex-1 rounded-2xl flex flex-col items-center justify-center gap-2" style={{ background: CORAL + "12", border: `2px solid ${CORAL}30`, height: 180 }}>
              <div className="w-12 h-12 rounded-full flex items-center justify-center" style={{ background: CORAL + "20" }}>
                <Mic size={20} color={CORAL} />
              </div>
              <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 700, color: CORAL }}>🎙 Voice {draft.captures.voiceSecs > 0 ? `(${Math.floor(draft.captures.voiceSecs / 60)}:${String(draft.captures.voiceSecs % 60).padStart(2, "0")})` : ""}</span>
            </div>
          )}
          {!draft.captures.photo && !draft.captures.voice && (
            <div className="w-full rounded-2xl flex items-center justify-center"
              style={{ height: 140, background: "#F2EFE8", border: "2px dashed rgba(27,25,40,0.12)" }}>
              <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.78rem", color: "#888699" }}>Text-only post</span>
            </div>
          )}
        </div>

        {/* AI caption with editable text */}
        <div className="rounded-2xl p-4 mb-4" style={{ background: "white", border: "1px solid rgba(27,25,40,0.07)" }}>
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-1.5">
              <Sparkles size={13} color={CORAL} />
              <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.68rem", fontWeight: 800, color: CORAL }}>CAPTION</span>
            </div>
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.65rem", color: "#888699" }}>Tap to edit</span>
          </div>
          <textarea
            className="w-full resize-none outline-none"
            rows={5}
            style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.84rem", color: NAVY, lineHeight: 1.65, background: "transparent", border: "none" }}
            value={caption}
            onChange={e => setCaption(e.target.value)}
          />
        </div>

        {/* Share to */}
        <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", fontWeight: 800, color: "#888699", letterSpacing: "0.06em", marginBottom: 10 }}>SHARE TO</p>
        <div className="flex flex-col gap-2.5 mb-4">
          {platforms.map(p => (
            <button key={p.name}
              className="w-full py-3.5 rounded-2xl flex items-center justify-center gap-2.5 font-bold"
              style={{ background: activeShare === p.name ? p.bg : "#F2EFE8",
                color: activeShare === p.name ? "white" : "#888699",
                fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "0.9rem",
                boxShadow: activeShare === p.name ? "0 4px 14px rgba(0,0,0,0.2)" : "none",
                transition: "all 0.2s" }}
              onClick={() => setActiveShare(activeShare === p.name ? null : p.name)}>
              <span>{p.icon}</span>
              {activeShare === p.name ? `✓ ${p.name} selected` : `Share to ${p.name}`}
            </button>
          ))}
        </div>
      </div>

      {/* Publish */}
      <div className="absolute bottom-0 left-0 right-0 px-5 pb-8 pt-4"
        style={{ background: "linear-gradient(to top, #F8F6F2 70%, transparent)" }}>
        <motion.button className="w-full py-4 rounded-2xl font-bold flex items-center justify-center gap-2"
          style={{ background: activeShare ? CORAL : "#F2EFE8",
            color: activeShare ? "white" : "#888699",
            fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "0.95rem",
            boxShadow: activeShare ? `0 6px 20px ${CORAL}45` : "none" }}
          whileTap={activeShare ? { scale: 0.97 } : {}}
          onClick={activeShare ? onPublish : undefined}>
          {activeShare ? <>Publish & unlock perk <Zap size={17} /></> : "Select a platform first"}
        </motion.button>
        {biz.hasPerk && activeShare && (
          <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", color: CORAL, textAlign: "center", marginTop: 8, fontWeight: 700 }}>
            Publishing unlocks your {biz.perk} perk 🎁
          </p>
        )}
      </div>
    </motion.div>
  );
}

// ─── Perks screen ──────────────────────────────────────────────────────────────

function PerksScreen() {
  const sc = (s: string) => s === "redeemed" ? GREEN : s === "approved" ? CORAL : "#F5A623";
  const sl = (s: string) => s === "redeemed" ? "Redeemed" : s === "approved" ? "Ready to use" : "Pending";
  return (
    <div className="size-full flex flex-col" style={{ background: "#F8F6F2" }}>
      <div className="flex-shrink-0 px-5 pt-14 pb-5">
        <h1 style={{ fontFamily: "'Fraunces', serif", fontStyle: "italic", fontSize: "1.8rem", fontWeight: 800, color: NAVY, letterSpacing: "-0.02em" }}>My perks</h1>
        <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.8rem", color: "#888699", marginTop: 2 }}>4 perks · €45 total value</p>
      </div>
      <div className="flex-1 overflow-y-auto px-5 pb-8 space-y-3" style={{ scrollbarWidth: "none" }}>
        {PERKS_DATA.map(p => (
          <motion.div key={p.id} className="rounded-2xl p-4"
            style={{ background: "white", border: "1px solid rgba(27,25,40,0.07)", boxShadow: "0 2px 10px rgba(0,0,0,0.05)" }}
            initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: p.id * 0.06 }}>
            <div className="flex items-start justify-between mb-3">
              <div>
                <h3 style={{ fontFamily: "'Fraunces', serif", fontSize: "1rem", fontWeight: 700, color: NAVY }}>{p.biz}</h3>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <Gift size={12} color={p.color} />
                  <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.75rem", fontWeight: 700, color: p.color }}>{p.perk}</span>
                </div>
              </div>
              <div>
                <div style={{ fontFamily: "'Fraunces', serif", fontSize: "1.2rem", fontWeight: 700, color: p.color, textAlign: "right" }}>{p.val}</div>
                <div className="px-2.5 py-0.5 rounded-full mt-1" style={{ background: sc(p.status) + "15" }}>
                  <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.62rem", fontWeight: 800, color: sc(p.status) }}>{sl(p.status)}</span>
                </div>
              </div>
            </div>
            {p.status === "approved" && (
              <div className="rounded-xl flex items-center justify-center" style={{ background: p.color + "08", border: `2px dashed ${p.color}40`, height: 72 }}>
                <div className="text-center">
                  <div style={{ fontSize: "1.5rem" }}>▣</div>
                  <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.68rem", color: p.color, fontWeight: 700, marginTop: 2 }}>Show this at the venue</p>
                </div>
              </div>
            )}
            {p.status === "redeemed" && (
              <div className="flex items-center gap-2 px-3 py-2 rounded-xl" style={{ background: GREEN + "10" }}>
                <CheckCircle2 size={14} color={GREEN} />
                <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.73rem", fontWeight: 700, color: GREEN }}>Redeemed · {p.date}</span>
              </div>
            )}
            {p.status === "pending" && (
              <div className="flex items-center gap-2 px-3 py-2 rounded-xl" style={{ background: "#FFF4E6", border: "1px solid #FDEBD0" }}>
                <Clock size={14} color="#E67E22" />
                <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.73rem", fontWeight: 700, color: "#E67E22" }}>Verifying your post…</span>
              </div>
            )}
          </motion.div>
        ))}
      </div>
    </div>
  );
}

// ─── Profile screen ────────────────────────────────────────────────────────────

function ProfileScreen() {
  const stats = [
    { icon: <Compass size={18} color={CORAL} />, label: "Strolls", val: "3" },
    { icon: <Heart size={18} color="#DD2A7B" />, label: "Reach", val: "8.2k" },
    { icon: <Trophy size={18} color="#F5A623" />, label: "Earned", val: "€74" },
    { icon: <Star size={18} color="#6C63FF" />, label: "Score", val: "4.9" },
  ];
  const history = [
    { city: "Stuttgart", date: "Today", stops: 3, img: "1477959858617-67f85cf4f1df" },
    { city: "Stuttgart", date: "12 Jul", stops: 2, img: "1519677100203-a0e668c92439" },
    { city: "Heidelberg", date: "28 Jun", stops: 4, img: "1548695269-a3f1eca28cc7" },
  ];
  return (
    <div className="size-full flex flex-col overflow-y-auto" style={{ background: "#F8F6F2", scrollbarWidth: "none" }}>
      <div className="flex-shrink-0 pt-14 pb-6 px-5">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-2xl flex items-center justify-center text-3xl flex-shrink-0"
            style={{ background: "linear-gradient(135deg, #FF5C3A, #FF8C42)", boxShadow: "0 4px 16px rgba(255,92,58,0.35)" }}>🧍</div>
          <div>
            <h1 style={{ fontFamily: "'Fraunces', serif", fontSize: "1.4rem", fontWeight: 700, color: NAVY }}>Alex Müller</h1>
            <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.78rem", color: "#888699" }}>Stuttgart · Food, Culture</p>
          </div>
        </div>
        <div className="flex gap-2 mt-4">
          {[{ label: "Instagram", followers: "4.2k", icon: "📸" }, { label: "Facebook", followers: "1.8k", icon: "f" }].map(acc => (
            <div key={acc.label} className="flex-1 flex items-center gap-2 p-3 rounded-xl"
              style={{ background: "white", border: "1px solid rgba(27,25,40,0.07)" }}>
              <span style={{ fontSize: "1.1rem" }}>{acc.icon}</span>
              <div>
                <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.7rem", fontWeight: 700, color: NAVY }}>{acc.label}</p>
                <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.65rem", color: "#888699" }}>{acc.followers} followers</p>
              </div>
            </div>
          ))}
          <div className="flex items-center justify-center p-3 rounded-xl w-14 flex-shrink-0"
            style={{ background: "white", border: "1.5px dashed rgba(27,25,40,0.15)" }}>
            <Plus size={18} color="#888699" />
          </div>
        </div>
      </div>
      <div className="px-5 mb-5">
        <div className="grid grid-cols-4 gap-2">
          {stats.map(s => (
            <div key={s.label} className="rounded-2xl p-3 flex flex-col items-center gap-1.5"
              style={{ background: "white", border: "1px solid rgba(27,25,40,0.07)", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
              {s.icon}
              <div style={{ fontFamily: "'Fraunces', serif", fontSize: "1.1rem", fontWeight: 700, color: NAVY }}>{s.val}</div>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.6rem", color: "#888699", textAlign: "center" }}>{s.label}</div>
            </div>
          ))}
        </div>
      </div>
      <div className="px-5 pb-10">
        <h2 style={{ fontFamily: "'Fraunces', serif", fontSize: "1.1rem", fontWeight: 700, color: NAVY, marginBottom: 12 }}>My strolls</h2>
        <div className="space-y-3">
          {history.map((h, i) => (
            <div key={i} className="flex items-center gap-3 rounded-2xl p-3"
              style={{ background: "white", border: "1px solid rgba(27,25,40,0.07)", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
              <div className="w-14 h-14 rounded-xl overflow-hidden flex-shrink-0">
                <img src={`https://images.unsplash.com/photo-${h.img}?w=100&h=100&fit=crop&auto=format`} alt="" className="w-full h-full object-cover" />
              </div>
              <div className="flex-1">
                <p style={{ fontFamily: "'Fraunces', serif", fontSize: "0.95rem", fontWeight: 700, color: NAVY }}>{h.city}</p>
                <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.72rem", color: "#888699" }}>{h.stops} stops · {h.date}</p>
              </div>
              <ChevronRight size={16} color="#C8C4BC" />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── Bottom nav ────────────────────────────────────────────────────────────────

function BottomNav({ tab, setTab }: { tab: Tab; setTab: (t: Tab) => void }) {
  const tabs: { key: Tab; label: string; icon: (a: boolean) => JSX.Element }[] = [
    { key: "map",     label: "Explore",   icon: a => <Map     size={22} color={a ? CORAL : "#B0ACBC"} strokeWidth={a ? 2.5 : 1.8} /> },
    { key: "stroll",  label: "My stroll", icon: a => <Compass size={22} color={a ? CORAL : "#B0ACBC"} strokeWidth={a ? 2.5 : 1.8} /> },
    { key: "perks",   label: "Perks",     icon: a => <Gift    size={22} color={a ? CORAL : "#B0ACBC"} strokeWidth={a ? 2.5 : 1.8} /> },
    { key: "profile", label: "Profile",   icon: a => <User    size={22} color={a ? CORAL : "#B0ACBC"} strokeWidth={a ? 2.5 : 1.8} /> },
  ];
  return (
    <div className="flex-shrink-0 flex items-center justify-around px-2 pt-2 pb-6"
      style={{ background: "white", borderTop: "1px solid rgba(27,25,40,0.07)", boxShadow: "0 -4px 20px rgba(0,0,0,0.06)" }}>
      {tabs.map(t => {
        const active = tab === t.key;
        return (
          <motion.button key={t.key} className="flex flex-col items-center gap-1 px-4 py-1 rounded-xl"
            whileTap={{ scale: 0.88 }} onClick={() => setTab(t.key)}>
            <div className="relative">
              {t.icon(active)}
              {t.key === "perks" && PERKS_DATA.some(p => p.status === "approved") && (
                <div className="absolute -top-0.5 -right-0.5 w-2.5 h-2.5 rounded-full" style={{ background: CORAL, border: "1.5px solid white" }} />
              )}
            </div>
            <span style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.62rem", fontWeight: active ? 800 : 600, color: active ? CORAL : "#B0ACBC" }}>
              {t.label}
            </span>
          </motion.button>
        );
      })}
    </div>
  );
}

// ─── Root App ──────────────────────────────────────────────────────────────────

export default function App() {
  const [loggedIn, setLoggedIn]       = useState(false);
  const [tab, setTab]                 = useState<Tab>("map");
  const [subScreen, setSubScreen]     = useState<SubScreen>(null);
  const [cart, setCart]               = useState<number[]>([]);
  const [stepIndex, setStepIndex]     = useState(0);

  // Per-stop drafts — keyed by bizId
  const [drafts, setDrafts] = useState<StopDraft[]>([]);

  const getDraft = (bizId: number): StopDraft => {
    return drafts.find(d => d.bizId === bizId) ?? { bizId, captures: emptyCaptures(), postDone: false, savedAt: null };
  };

  const saveDraft = (d: StopDraft) => {
    setDrafts(prev => {
      const next = prev.filter(x => x.bizId !== d.bizId);
      return [...next, d];
    });
  };

  const currentBizId = STROLL_STEPS[stepIndex]?.bizId;

  const handleCreateStroll = () => setSubScreen("journey");
  const handleStartStep    = (idx: number) => { setStepIndex(idx); setSubScreen("step"); };
  const handleSaveResume   = () => {
    saveDraft({ ...getDraft(currentBizId), savedAt: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) });
    setSubScreen("journey");
  };
  const handleBuildPost    = () => setSubScreen("stoppost");
  const handlePublish      = () => {
    saveDraft({ ...getDraft(currentBizId), postDone: true });
    setSubScreen("journey");
  };
  const handleBackFromStep = () => setSubScreen("journey");
  const handleBackFromPost = () => setSubScreen("step");

  if (!loggedIn) return (
    <div className="size-full"><OnboardingScreen onLogin={() => setLoggedIn(true)} /></div>
  );

  return (
    <div className="size-full flex flex-col overflow-hidden" style={{ background: "#F8F6F2" }}>

      {/* Overlapping sub-screens */}
      <AnimatePresence>
        {subScreen === "journey" && (
          <div key="journey" className="absolute inset-0 z-40">
            <JourneyScreen
              cart={cart} drafts={drafts}
              onStart={handleStartStep}
              onBack={() => { setSubScreen(null); }} />
          </div>
        )}
        {subScreen === "step" && (
          <div key="step" className="absolute inset-0 z-40">
            <StepScreen
              stepIndex={stepIndex}
              draft={getDraft(currentBizId)}
              onDraftChange={saveDraft}
              onPost={handleBuildPost}
              onSaveResume={handleSaveResume}
              onBack={handleBackFromStep} />
          </div>
        )}
        {subScreen === "stoppost" && (
          <div key="stoppost" className="absolute inset-0 z-50">
            <StopPostScreen
              stepIndex={stepIndex}
              draft={getDraft(currentBizId)}
              onPublish={handlePublish}
              onBack={handleBackFromPost} />
          </div>
        )}
      </AnimatePresence>

      {/* Tab content */}
      <div className="flex-1 relative overflow-hidden">
        <AnimatePresence mode="wait">
          {tab === "map" && (
            <motion.div key="map" className="absolute inset-0"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.18 }}>
              <MapScreen cart={cart} setCart={setCart} onCreateStroll={handleCreateStroll} />
            </motion.div>
          )}
          {tab === "stroll" && (
            <motion.div key="stroll" className="absolute inset-0"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.18 }}>
              {cart.length === 0 ? (
                <div className="size-full flex flex-col items-center justify-center px-8 text-center">
                  <div className="text-5xl mb-4">🗺️</div>
                  <h2 style={{ fontFamily: "'Fraunces', serif", fontStyle: "italic", fontSize: "1.4rem", fontWeight: 700, color: NAVY, marginBottom: 8 }}>No stroll yet</h2>
                  <p style={{ fontFamily: "'Nunito', sans-serif", fontSize: "0.85rem", color: "#888699", lineHeight: 1.6 }}>Head to the map, pick 2+ stops, then create your stroll.</p>
                  <button className="mt-6 px-6 py-3.5 rounded-2xl font-bold text-sm"
                    style={{ background: CORAL, color: "white", fontFamily: "'Nunito', sans-serif", fontWeight: 800, boxShadow: `0 4px 16px ${CORAL}45` }}
                    onClick={() => setTab("map")}>Open map →</button>
                </div>
              ) : (
                <JourneyScreen cart={cart} drafts={drafts} onStart={handleStartStep} onBack={() => setTab("map")} />
              )}
            </motion.div>
          )}
          {tab === "perks" && (
            <motion.div key="perks" className="absolute inset-0"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.18 }}>
              <PerksScreen />
            </motion.div>
          )}
          {tab === "profile" && (
            <motion.div key="profile" className="absolute inset-0"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.18 }}>
              <ProfileScreen />
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {subScreen === null && <BottomNav tab={tab} setTab={setTab} />}
    </div>
  );
}
