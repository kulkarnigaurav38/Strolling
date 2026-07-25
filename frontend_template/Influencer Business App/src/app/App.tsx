import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  MapPin, Coffee, Utensils, Beer, Camera, Mic, ChevronRight, ChevronLeft,
  Check, Share2, Gift, User, Sun, Moon, Plus, X, ArrowRight, Sparkles,
  Eye, Bell, QrCode, Trophy, Music, Map, Navigation, Heart, MessageCircle,
  Zap, AlignLeft, FileText, BookOpen, Play, Pause, Volume2, Pencil,
  Bookmark, BookmarkCheck, Compass, Footprints
} from "lucide-react";

// ── Types ──────────────────────────────────────────────────────────────────────
interface Business {
  id: number; name: string; category: string; description: string;
  perk: string; perkValue: string; requirement: string;
  distance: string; walkTime: string; color: string;
  mapX: number; mapY: number; minFollowers: number; iconKey: string; coverImg: string;
}

interface StepMedia {
  photo: boolean;
  voice: boolean;
  text: string;
}

type AppState = "auth" | "onboard" | "main";
type CreatorScreen = "map" | "route" | "step" | "post" | "perks" | "profile";
type MapMode = "roam" | "earn";

// ── Data ───────────────────────────────────────────────────────────────────────
const BUSINESSES: Business[] = [
  {
    id: 1, name: "Café Alma", category: "Coffee",
    description: "Specialty roaster in a sun-drenched corner spot. Famous for cardamom flat whites and locally baked sourdough.",
    perk: "2 free lattes", perkValue: "€8 value", requirement: "1 photo + 1 story post",
    distance: "0.3 km", walkTime: "4 min", color: "#C97B4B",
    mapX: 27, mapY: 33, minFollowers: 0, iconKey: "coffee",
    coverImg: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&h=200&fit=crop&auto=format",
  },
  {
    id: 2, name: "Osteria Noma", category: "Food",
    description: "Neighbourhood Italian with a vine-covered terrace. Pasta made fresh each morning, wine from small estates only.",
    perk: "Free lunch (up to €25)", perkValue: "€25 value", requirement: "1 post + 1 reel",
    distance: "0.5 km", walkTime: "6 min", color: "#4A8A5C",
    mapX: 64, mapY: 24, minFollowers: 5000, iconKey: "food",
    coverImg: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=200&fit=crop&auto=format",
  },
  {
    id: 3, name: "Bar Soleil", category: "Nightlife",
    description: "Rooftop bar with 270° city views. Cocktails named after local legends. The 'Stadtmitte' is unmissable.",
    perk: "3 free craft beers", perkValue: "€15 value", requirement: "1 story + tag",
    distance: "0.8 km", walkTime: "10 min", color: "#7C5CE4",
    mapX: 74, mapY: 57, minFollowers: 0, iconKey: "beer",
    coverImg: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400&h=200&fit=crop&auto=format",
  },
  {
    id: 4, name: "Studio Mira", category: "Boutique",
    description: "Ceramics and textile studio. All pieces are signed and made in-house. Mira is usually at the wheel when open.",
    perk: "€20 store credit", perkValue: "€20 value", requirement: "2 posts + tag",
    distance: "0.4 km", walkTime: "5 min", color: "#E45C7C",
    mapX: 43, mapY: 61, minFollowers: 2000, iconKey: "boutique",
    coverImg: "https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=400&h=200&fit=crop&auto=format",
  },
  {
    id: 5, name: "The Record Loft", category: "Culture",
    description: "Vinyl heaven up a narrow staircase — the sign says only 'Loft'. Max has been here 22 years.",
    perk: "Free entry + 1 drink", perkValue: "€12 value", requirement: "1 reel + 1 story",
    distance: "0.6 km", walkTime: "8 min", color: "#3B82F6",
    mapX: 19, mapY: 67, minFollowers: 1000, iconKey: "culture",
    coverImg: "https://images.unsplash.com/photo-1483412033650-1015ddeb83d1?w=400&h=200&fit=crop&auto=format",
  },
  {
    id: 6, name: "Mercado Hall", category: "Food",
    description: "Indoor market with 12 local stalls. The grilled octopus stall at the back is what people travel here for.",
    perk: "€30 food voucher", perkValue: "€30 value", requirement: "1 post + 3 stories",
    distance: "1.1 km", walkTime: "13 min", color: "#F59E0B",
    mapX: 82, mapY: 41, minFollowers: 10000, iconKey: "food",
    coverImg: "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=400&h=200&fit=crop&auto=format",
  },
];

const STROLL_STEPS = [
  {
    id: 0, businessId: 1, business: "Café Alma", color: "#C97B4B",
    title: "Your first sip of the day",
    narration: "Turn left onto Schillerstraße and walk two blocks past the bookshop with the green awning — you'll smell the coffee before you see it. Café Alma has been on this corner since 1987. The owner, Ingrid, still roasts the beans herself every Tuesday morning.",
    task: "Grab a cardamom flat white and capture your first sip.",
    hint: "The golden light hits the back wall beautifully before noon",
    aiCaption: "First stop of the stroll and already obsessed ☕ @cafealma's cardamom flat white is pure magic — the kind of place you move to a city for. #CaféAlma #Stuttgart #MorningVibes #Strolling",
  },
  {
    id: 1, businessId: 4, business: "Studio Mira", color: "#E45C7C",
    title: "The ceramic studio",
    narration: "Head down Lindenstraße toward the old railway bridge. Look for the hand-painted tile above a wooden gate — that's Studio Mira. Every piece here takes at least a week to make. Ask Mira what she's currently working on.",
    task: "Show the textures — hands on clay, finished pieces on the shelf.",
    hint: "Natural light from the skylight makes ceramics glow",
    aiCaption: "Found this incredible ceramics studio tucked behind a wooden gate on Lindenstraße 🏺 @studiomira makes every piece by hand — each one takes a week. Getting one of these home. #StudioMira #Ceramics #CityStroll",
  },
  {
    id: 2, businessId: 5, business: "The Record Loft", color: "#3B82F6",
    title: "Vinyl hunting",
    narration: "Cut through the market square — the fountain marks your halfway point. The Record Loft is up a narrow staircase; the only sign is a small 'Loft' in the window. Max has been behind the counter for 22 years and will play anything you ask.",
    task: "Pull a record from the crate and talk about why it caught your eye.",
    hint: "The neon sign in the back glows perfectly on camera",
    aiCaption: "This place smells exactly how a record shop should 🎵 @therecordloft is up a tiny staircase with no signs — just vibes and 22 years of Max behind the counter. Leaving with three records I didn't plan on buying. #RecordLoft #VinylLife #HiddenGems",
  },
];

const INTERESTS = ["☕ Coffee", "🍝 Food", "🍻 Nightlife", "🎨 Culture", "🌿 Outdoors", "🛍 Shopping", "🎵 Music", "🏛 History"];

// ── Helpers ─────────────────────────────────────────────────────────────────────
function cn(...args: (string | false | undefined | null)[]) {
  return args.filter(Boolean).join(" ");
}

function getCategoryIcon(iconKey: string, size = 13) {
  switch (iconKey) {
    case "coffee": return <Coffee size={size} />;
    case "food": return <Utensils size={size} />;
    case "beer": return <Beer size={size} />;
    case "culture": return <Music size={size} />;
    default: return <MapPin size={size} />;
  }
}

function hasCapture(m?: StepMedia) {
  return m && (m.photo || m.voice || m.text.trim().length > 0);
}

// ── City Map SVG ────────────────────────────────────────────────────────────────
function CityMapSVG({ dark }: { dark: boolean }) {
  const bg = dark ? "#13121F" : "#F5F0E8";
  const block = dark ? "#1E1D30" : "#E8E0CE";
  const blockB = dark ? "#231F36" : "#EDE6D6";
  const st = dark ? "#0C0B18" : "#D5C9B0";
  const park = dark ? "#132A18" : "#C4E6A0";
  const water = dark ? "#0F2035" : "#AECCE8";

  return (
    <svg viewBox="0 0 375 460" className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
      <rect width="375" height="460" fill={bg} />
      {[55, 118, 181, 244, 307].map(x => <rect key={x} x={x} y="0" width="7" height="460" fill={st} />)}
      {[58, 125, 192, 259, 326].map(y => <rect key={y} x="0" y={y} width="375" height="7" fill={st} />)}
      <rect x="62" y="0" width="56" height="58" rx="2" fill={block} />
      <rect x="125" y="0" width="56" height="58" rx="2" fill={blockB} />
      <rect x="188" y="0" width="56" height="58" rx="2" fill={block} />
      <rect x="251" y="0" width="56" height="58" rx="2" fill={blockB} />
      <rect x="314" y="0" width="61" height="58" rx="2" fill={block} />
      <rect x="0" y="65" width="55" height="60" rx="2" fill={blockB} />
      <rect x="62" y="65" width="56" height="60" rx="2" fill={block} />
      <rect x="125" y="65" width="119" height="60" rx="2" fill={park} />
      <rect x="251" y="65" width="56" height="60" rx="2" fill={blockB} />
      <rect x="314" y="65" width="61" height="60" rx="2" fill={block} />
      {[[150,85],[175,90],[163,105],[200,88],[215,100]].map(([cx,cy],i) => (
        <circle key={i} cx={cx} cy={cy} r={i%2===0?5:4} fill={dark?"#1A3A20":"#8EC870"} />
      ))}
      <rect x="0" y="132" width="55" height="60" rx="2" fill={block} />
      <rect x="62" y="132" width="56" height="60" rx="2" fill={blockB} />
      <rect x="125" y="132" width="56" height="60" rx="2" fill={block} />
      <rect x="188" y="132" width="56" height="60" rx="2" fill={blockB} />
      <rect x="251" y="132" width="56" height="60" rx="2" fill={block} />
      <rect x="314" y="132" width="61" height="60" rx="2" fill={blockB} />
      <rect x="0" y="199" width="55" height="60" rx="2" fill={blockB} />
      <rect x="62" y="199" width="119" height="60" rx="2" fill={park} />
      <rect x="188" y="199" width="56" height="60" rx="2" fill={block} />
      <rect x="251" y="199" width="56" height="60" rx="2" fill={blockB} />
      <rect x="314" y="199" width="61" height="60" rx="2" fill={block} />
      {[[85,215],[100,230],[148,220],[125,240]].map(([cx,cy],i) => (
        <circle key={i} cx={cx} cy={cy} r={i%2===0?5:4} fill={dark?"#1A3A20":"#8EC870"} />
      ))}
      <rect x="0" y="266" width="55" height="60" rx="2" fill={block} />
      <rect x="62" y="266" width="56" height="60" rx="2" fill={blockB} />
      <rect x="125" y="266" width="56" height="60" rx="2" fill={block} />
      <rect x="188" y="266" width="56" height="60" rx="2" fill={blockB} />
      <rect x="251" y="266" width="119" height="60" rx="2" fill={water} />
      <ellipse cx="310" cy="296" rx="28" ry="7" fill={dark?"#0A1828":"#96BCDC"} opacity="0.6" />
      <rect x="0" y="333" width="55" height="60" rx="2" fill={blockB} />
      <rect x="62" y="333" width="56" height="60" rx="2" fill={block} />
      <rect x="125" y="333" width="56" height="60" rx="2" fill={blockB} />
      <rect x="188" y="333" width="56" height="60" rx="2" fill={block} />
      <rect x="251" y="333" width="56" height="60" rx="2" fill={blockB} />
      <rect x="314" y="333" width="61" height="60" rx="2" fill={block} />
    </svg>
  );
}

// ── Business Pin ─────────────────────────────────────────────────────────────────
function BusinessPin({ business, isSelected, isInCart, onClick }: {
  business: Business; isSelected: boolean; isInCart: boolean; onClick: () => void;
}) {
  return (
    <motion.button
      className="absolute cursor-pointer z-10"
      style={{ left: `${business.mapX}%`, top: `${business.mapY}%`, transform: "translate(-50%,-100%)" }}
      onClick={onClick}
      whileTap={{ scale: 0.88 }}
      animate={{ y: isSelected ? -4 : 0 }}
      transition={{ type: "spring", stiffness: 380, damping: 22 }}
    >
      {isSelected && (
        <motion.div
          className="absolute rounded-full pointer-events-none"
          style={{ backgroundColor: business.color + "28", inset: -10 }}
          animate={{ scale: [1, 1.7, 1], opacity: [0.9, 0, 0.9] }}
          transition={{ repeat: Infinity, duration: 2.2 }}
        />
      )}
      <div
        className={cn("flex items-center gap-1 px-2.5 py-1.5 rounded-full shadow-lg text-white text-[11px] font-bold transition-all", isInCart && "ring-2 ring-white ring-offset-1")}
        style={{ backgroundColor: business.color }}
      >
        {getCategoryIcon(business.iconKey, 11)}
        <span>{business.name.split(" ")[0]}</span>
        {isInCart && <Check size={9} strokeWidth={3} />}
      </div>
      <div className="absolute left-1/2 -translate-x-1/2 -bottom-1 w-2.5 h-2.5 rotate-45" style={{ backgroundColor: business.color }} />
    </motion.button>
  );
}

// ── Status Bar ────────────────────────────────────────────────────────────────────
function StatusBar() {
  return (
    <div className="flex items-center justify-between px-5 pt-3 pb-1 text-[11px] font-bold text-foreground">
      <span>9:41</span>
      <div className="flex items-center gap-1.5">
        <div className="flex items-end gap-[2px]">
          {[10, 14, 18, 22].map((h, i) => (
            <div key={i} className="w-[3px] rounded-sm bg-foreground" style={{ height: h, opacity: i < 3 ? 1 : 0.35 }} />
          ))}
        </div>
        <svg viewBox="0 0 24 12" className="w-5 h-3 fill-foreground">
          <rect x="0" y="1" width="21" height="10" rx="2" stroke="currentColor" strokeWidth="1.5" fill="none" />
          <rect x="22" y="3.5" width="2" height="5" rx="1" />
          <rect x="1.5" y="2.5" width="16" height="7" rx="1" />
        </svg>
      </div>
    </div>
  );
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────────
function BottomNav({ tab, setTab, cartCount }: { tab: string; setTab: (t: string) => void; cartCount: number }) {
  const tabs = [{ id: "map", label: "Explore", icon: Map }, { id: "perks", label: "Perks", icon: Gift }, { id: "profile", label: "Profile", icon: User }];
  return (
    <div className="absolute bottom-0 left-0 right-0 bg-card/96 backdrop-blur-md border-t border-border px-8 pb-5 pt-2 flex items-center justify-around">
      {tabs.map(({ id, label, icon: Icon }) => (
        <button key={id} onClick={() => setTab(id)} className={cn("flex flex-col items-center gap-1 transition-all", tab === id ? "text-primary" : "text-muted-foreground")}>
          <div className="relative">
            {id === "map" && cartCount > 0 && (
              <span className="absolute -top-1 -right-1.5 bg-primary text-primary-foreground text-[9px] font-bold rounded-full w-4 h-4 flex items-center justify-center">{cartCount}</span>
            )}
            <Icon size={22} strokeWidth={tab === id ? 2.2 : 1.8} />
          </div>
          <span className="text-[10px] font-semibold">{label}</span>
        </button>
      ))}
    </div>
  );
}

// ── Auth Screen ───────────────────────────────────────────────────────────────────
function AuthScreen({ onLogin, dark }: { onLogin: () => void; dark: boolean }) {
  return (
    <div className="absolute inset-0 bg-background flex flex-col overflow-hidden">
      {/* Top visual */}
      <div className="relative flex-1 flex flex-col items-center justify-center px-6 pb-4">
        {/* Decorative map preview */}
        <div className="relative w-full h-44 rounded-3xl overflow-hidden mb-6 shadow-xl border border-border">
          <CityMapSVG dark={dark} />
          {/* Animated ping dots */}
          {[{x:27,y:33,c:"#C97B4B"},{x:43,y:61,c:"#E45C7C"},{x:19,y:67,c:"#3B82F6"}].map((p,i) => (
            <div key={i} className="absolute" style={{left:`${p.x}%`,top:`${p.y}%`,transform:"translate(-50%,-50%)"}}>
              <motion.div
                className="w-4 h-4 rounded-full border-2 border-white shadow"
                style={{ backgroundColor: p.c }}
                animate={{ scale: [1,1.3,1] }}
                transition={{ repeat: Infinity, duration: 2, delay: i * 0.7 }}
              />
            </div>
          ))}
          {/* Route line overlay */}
          <div className="absolute inset-0 bg-gradient-to-t from-background/60 to-transparent" />
        </div>

        <span style={{ fontFamily: "Fraunces, serif" }} className="text-4xl font-bold text-foreground tracking-tight">
          Strolling
        </span>
        <p className="text-muted-foreground text-center mt-2 text-[15px] leading-snug">
          Wander the city, capture moments,<br />earn perks along the way.
        </p>
      </div>

      {/* Login buttons */}
      <div className="px-5 pb-8 space-y-3">
        <button
          onClick={onLogin}
          className="w-full flex items-center justify-center gap-3 rounded-2xl py-4 font-bold text-[15px] text-white shadow-lg"
          style={{ background: "linear-gradient(135deg, #405DE6, #5851DB, #833AB4, #C13584, #E1306C, #FD1D1D)" }}
        >
          <svg viewBox="0 0 24 24" className="w-5 h-5 fill-white"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
          Continue with Instagram
        </button>
        <button
          onClick={onLogin}
          className="w-full flex items-center justify-center gap-3 bg-[#1877F2] text-white rounded-2xl py-4 font-bold text-[15px] shadow-lg"
        >
          <svg viewBox="0 0 24 24" className="w-5 h-5 fill-white"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
          Continue with Facebook
        </button>
        <button
          onClick={onLogin}
          className="w-full flex items-center justify-center gap-3 bg-card border border-border text-foreground rounded-2xl py-4 font-bold text-[15px] shadow-sm"
        >
          <svg viewBox="0 0 24 24" className="w-5 h-5"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/></svg>
          Continue with Google
        </button>
        <button onClick={onLogin} className="w-full text-center text-[13px] text-muted-foreground py-2 font-medium">
          Skip for now — just browsing
        </button>
      </div>
    </div>
  );
}

// ── Onboarding Screen ─────────────────────────────────────────────────────────────
function OnboardingScreen({ onComplete }: { onComplete: () => void }) {
  const [step, setStep] = useState(0);
  const [interests, setInterests] = useState<string[]>(["☕ Coffee", "🍝 Food"]);

  const toggleInterest = (i: string) =>
    setInterests(prev => prev.includes(i) ? prev.filter(x => x !== i) : [...prev, i]);

  return (
    <div className="absolute inset-0 bg-background flex flex-col">
      {/* Progress */}
      <div className="flex gap-1.5 px-5 pt-4 pb-2">
        {[0, 1].map(i => (
          <div key={i} className={cn("flex-1 h-1 rounded-full transition-all", i <= step ? "bg-primary" : "bg-muted")} />
        ))}
      </div>

      <AnimatePresence mode="wait">
        {step === 0 && (
          <motion.div
            key="s0"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="flex-1 flex flex-col px-5"
          >
            <div className="pt-4 pb-3">
              <h2 style={{ fontFamily: "Fraunces, serif" }} className="text-2xl font-bold text-foreground">Connect your socials</h2>
              <p className="text-[13px] text-muted-foreground mt-1">Linking accounts unlocks more perks and lets businesses see your reach.</p>
            </div>
            <div className="space-y-3 mb-6">
              {[
                { name: "Instagram", handle: "@sophie.explores", followers: "8.5K followers", connected: true, cls: "from-purple-500 to-pink-500" },
                { name: "Facebook", handle: "Sophie Mayer", followers: "2.1K friends", connected: true, cls: "from-blue-600 to-blue-700" },
                { name: "TikTok", handle: "Not linked yet", followers: "", connected: false, cls: "from-zinc-500 to-zinc-600" },
              ].map(acc => (
                <div key={acc.name} className="bg-card border border-border rounded-2xl p-4 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={cn("w-10 h-10 rounded-full bg-gradient-to-br flex items-center justify-center text-white font-extrabold flex-none", acc.cls)}>
                      {acc.name[0]}
                    </div>
                    <div>
                      <p className="font-bold text-[13px] text-foreground">{acc.name}</p>
                      <p className="text-[11px] text-muted-foreground">{acc.connected ? `${acc.handle} · ${acc.followers}` : acc.handle}</p>
                    </div>
                  </div>
                  {acc.connected
                    ? <span className="flex items-center gap-1 text-[11px] font-bold text-green-600 dark:text-green-400"><Check size={13} /> Connected</span>
                    : <button className="text-[11px] font-bold text-primary bg-primary/10 px-3 py-1.5 rounded-full">Link</button>
                  }
                </div>
              ))}
            </div>
            <div className="bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800/40 rounded-2xl p-3 mb-4">
              <p className="text-[12px] text-amber-800 dark:text-amber-300 leading-relaxed">
                💡 Connected accounts unlock cash perks and let businesses see your real reach. No minimum needed for in-kind perks.
              </p>
            </div>
            <div className="flex-1" />
            <div className="pb-6 space-y-2">
              <button onClick={() => setStep(1)} className="w-full bg-primary text-primary-foreground rounded-2xl py-4 font-bold text-[15px] flex items-center justify-center gap-2 shadow-lg shadow-primary/25">
                Next <ChevronRight size={16} />
              </button>
            </div>
          </motion.div>
        )}

        {step === 1 && (
          <motion.div
            key="s1"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="flex-1 flex flex-col px-5"
          >
            <div className="pt-4 pb-4">
              <h2 style={{ fontFamily: "Fraunces, serif" }} className="text-2xl font-bold text-foreground">What do you love?</h2>
              <p className="text-[13px] text-muted-foreground mt-1">We use this to show you the best stops on every stroll.</p>
            </div>
            <div className="flex flex-wrap gap-2 mb-6">
              {INTERESTS.map(i => (
                <button
                  key={i}
                  onClick={() => toggleInterest(i)}
                  className={cn(
                    "px-4 py-2.5 rounded-full text-[13px] font-semibold border transition-all",
                    interests.includes(i) ? "bg-primary text-primary-foreground border-transparent shadow-sm" : "bg-card text-foreground border-border"
                  )}
                >
                  {i}
                </button>
              ))}
            </div>
            <div className="flex-1" />
            <div className="pb-8 space-y-2">
              <button onClick={onComplete} className="w-full bg-primary text-primary-foreground rounded-2xl py-4 font-bold text-[15px] flex items-center justify-center gap-2 shadow-lg shadow-primary/25">
                <Sparkles size={18} /> Start strolling!
              </button>
              <button onClick={() => setStep(0)} className="w-full text-center text-[13px] text-muted-foreground py-2">
                ← Back
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

// ── Map Screen ─────────────────────────────────────────────────────────────────────
function MapScreen({
  dark, businesses, cart, mapMode, setMapMode,
  selectedBusiness, setSelectedBusiness, onAddToCart, onRemoveFromCart, onCreateRoute,
  savedProgress, onResume,
}: {
  dark: boolean; businesses: Business[]; cart: number[];
  mapMode: MapMode; setMapMode: (m: MapMode) => void;
  selectedBusiness: number | null; setSelectedBusiness: (id: number | null) => void;
  onAddToCart: (id: number) => void; onRemoveFromCart: (id: number) => void;
  onCreateRoute: () => void;
  savedProgress: boolean; onResume: () => void;
}) {
  const [filter, setFilter] = useState("All");
  const selected = businesses.find(b => b.id === selectedBusiness);
  const cartBusinesses = businesses.filter(b => cart.includes(b.id));
  const FILTERS = ["All", "Food", "Coffee", "Nightlife", "Culture"];

  return (
    <div className="absolute inset-0 overflow-hidden">
      {/* MAP */}
      <div className="absolute inset-0">
        <CityMapSVG dark={dark} />
        {businesses.map(b => (
          <BusinessPin key={b.id} business={b} isSelected={selectedBusiness === b.id} isInCart={cart.includes(b.id)}
            onClick={() => setSelectedBusiness(selectedBusiness === b.id ? null : b.id)} />
        ))}
        <div className="absolute" style={{ left: "50%", top: "50%", transform: "translate(-50%,-50%)" }}>
          <motion.div className="w-4 h-4 rounded-full bg-blue-500 border-2 border-white shadow-md relative z-10"
            animate={{ scale: [1, 1.15, 1] }} transition={{ repeat: Infinity, duration: 2.5 }} />
          <div className="absolute -inset-3 rounded-full bg-blue-500/15" />
        </div>
      </div>

      {/* TOP OVERLAY */}
      <div className="absolute top-0 left-0 right-0 px-4 pt-1 bg-gradient-to-b from-background/96 via-background/60 to-transparent pb-5 pointer-events-none">
        <div className="flex items-center justify-between mb-3 pointer-events-auto">
          <span style={{ fontFamily: "Fraunces, serif" }} className="font-bold text-xl text-foreground tracking-tight">Strolling</span>
          <div className="flex items-center gap-2">
            <button className="w-8 h-8 flex items-center justify-center rounded-full bg-card shadow border border-border text-foreground">
              <Bell size={14} />
            </button>
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-orange-400 to-pink-500" />
          </div>
        </div>

        {/* MODE SWITCH — prominent */}
        <div className="pointer-events-auto flex gap-2">
          <button
            onClick={() => setMapMode("roam")}
            className={cn(
              "flex-1 flex items-center justify-center gap-2 py-2.5 rounded-2xl text-[13px] font-bold border transition-all shadow-sm",
              mapMode === "roam"
                ? "bg-foreground text-background border-transparent shadow-md"
                : "bg-card/90 backdrop-blur-sm text-foreground border-border"
            )}
          >
            <Footprints size={14} /> Just Roam
          </button>
          <button
            onClick={() => setMapMode("earn")}
            className={cn(
              "flex-1 flex items-center justify-center gap-2 py-2.5 rounded-2xl text-[13px] font-bold border transition-all shadow-sm",
              mapMode === "earn"
                ? "bg-primary text-primary-foreground border-transparent shadow-md shadow-primary/25"
                : "bg-card/90 backdrop-blur-sm text-foreground border-border"
            )}
          >
            <Sparkles size={14} /> Earn Perks
          </button>
        </div>
      </div>

      {/* FILTER CHIPS */}
      <div className="absolute top-[118px] left-0 right-0 px-4 flex gap-2 overflow-x-auto scrollbar-hide">
        {FILTERS.map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={cn("flex-none px-3 py-1.5 rounded-full text-[11px] font-bold border transition-all whitespace-nowrap shadow-sm",
              filter === f ? "bg-foreground text-background border-transparent" : "bg-card/85 backdrop-blur-sm text-foreground border-border"
            )}
          >{f}</button>
        ))}
      </div>

      {/* RESUME BANNER */}
      <AnimatePresence>
        {savedProgress && !selectedBusiness && (
          <motion.div
            className="absolute top-[152px] left-4 right-4 z-20"
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
          >
            <div className="bg-primary text-primary-foreground rounded-2xl px-4 py-3 flex items-center justify-between shadow-lg shadow-primary/30">
              <div className="flex items-center gap-2">
                <Bookmark size={16} />
                <div>
                  <p className="text-[12px] font-bold">Stroll in progress</p>
                  <p className="text-[10px] opacity-80">Stop 2 of 3 saved — pick up where you left off</p>
                </div>
              </div>
              <button onClick={onResume} className="bg-white/20 px-3 py-1.5 rounded-xl text-[11px] font-extrabold flex-none">
                Resume →
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* BUSINESS DETAIL SHEET */}
      <AnimatePresence>
        {selected && (
          <motion.div className="absolute inset-x-0 bottom-0 z-30"
            initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }}
            transition={{ type: "spring", stiffness: 280, damping: 28 }}
          >
            <div className="bg-card rounded-t-3xl shadow-2xl">
              <div className="flex justify-center pt-3 pb-1"><div className="w-10 h-1 rounded-full bg-border" /></div>
              <button onClick={() => setSelectedBusiness(null)} className="absolute top-3 right-4 w-8 h-8 flex items-center justify-center rounded-full bg-muted text-muted-foreground"><X size={15} /></button>
              <div className="mx-4 mt-1 h-28 rounded-2xl overflow-hidden bg-muted">
                <img src={selected.coverImg} alt={selected.name} className="w-full h-full object-cover" />
              </div>
              <div className="px-4 pt-3 pb-5">
                <div className="flex items-start justify-between gap-3 mb-2">
                  <div className="flex-1 min-w-0">
                    <h3 className="font-bold text-foreground text-[17px] leading-tight">{selected.name}</h3>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-[11px] text-muted-foreground bg-muted px-2 py-0.5 rounded-full font-medium">{selected.category}</span>
                      <span className="text-[11px] text-muted-foreground">{selected.distance} · {selected.walkTime}</span>
                    </div>
                  </div>
                  {mapMode === "earn" && (
                    <div className="bg-accent text-accent-foreground px-3 py-2 rounded-xl text-center flex-none shadow-sm">
                      <div className="text-[11px] font-extrabold leading-tight">{selected.perk}</div>
                      <div className="text-[10px] opacity-70 font-medium">{selected.perkValue}</div>
                    </div>
                  )}
                </div>
                <p className="text-[13px] text-muted-foreground leading-relaxed mb-3">{selected.description}</p>
                {mapMode === "earn" && (
                  <div className="flex items-center gap-1.5 mb-4">
                    <Zap size={11} className="text-muted-foreground flex-none" />
                    <span className="text-[11px] text-muted-foreground">Requires: {selected.requirement}</span>
                  </div>
                )}
                {cart.includes(selected.id) ? (
                  <button onClick={() => onRemoveFromCart(selected.id)} className="w-full flex items-center justify-center gap-2 bg-muted text-foreground rounded-2xl py-3.5 font-bold text-sm">
                    <Check size={16} className="text-green-500" /> Added to stroll
                  </button>
                ) : (
                  <button onClick={() => { onAddToCart(selected.id); }} disabled={cart.length >= 5}
                    className="w-full flex items-center justify-center gap-2 bg-primary text-primary-foreground rounded-2xl py-3.5 font-bold text-sm shadow-lg shadow-primary/25 disabled:opacity-40">
                    <Plus size={16} /> Add to stroll
                  </button>
                )}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* BOTTOM CART */}
      <AnimatePresence>
        {!selected && (
          <motion.div className="absolute inset-x-0 bottom-0 z-20"
            initial={{ y: 10, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 10, opacity: 0 }}>
            <div className="bg-card/96 backdrop-blur-md rounded-t-3xl border-t border-border px-4 pt-3 pb-24 shadow-2xl">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-full bg-gradient-to-br from-orange-400 to-pink-500 flex-none shadow" />
                  <div>
                    <p className="text-[13px] font-bold text-foreground">My Stroll</p>
                    <p className="text-[11px] text-muted-foreground">
                      {cart.length === 0 ? "Tap a pin to start" : `${cart.length} stop${cart.length > 1 ? "s" : ""} added`}
                    </p>
                  </div>
                </div>
                {cart.length > 0 && (
                  <motion.button onClick={onCreateRoute} initial={{ scale: 0.85, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
                    className="flex items-center gap-1.5 bg-primary text-primary-foreground rounded-full px-4 py-2.5 text-[13px] font-bold shadow-lg shadow-primary/30">
                    Start strolling <ArrowRight size={13} />
                  </motion.button>
                )}
              </div>
              {cart.length > 0 && (
                <div className="flex gap-2.5 overflow-x-auto scrollbar-hide pb-1">
                  {cartBusinesses.map(b => (
                    <div key={b.id} className="flex-none flex flex-col items-center gap-1">
                      <div className="w-12 h-12 rounded-2xl flex items-center justify-center text-white text-sm font-bold shadow" style={{ backgroundColor: b.color }}>
                        {getCategoryIcon(b.iconKey, 18)}
                      </div>
                      <span className="text-[9px] text-muted-foreground max-w-[48px] text-center leading-tight truncate">{b.name.split(" ")[0]}</span>
                    </div>
                  ))}
                  {cart.length < 5 && (
                    <div className="flex-none flex flex-col items-center gap-1">
                      <div className="w-12 h-12 rounded-2xl border-2 border-dashed border-border flex items-center justify-center text-muted-foreground"><Plus size={18} /></div>
                      <span className="text-[9px] text-muted-foreground">Add stop</span>
                    </div>
                  )}
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

// ── Route Screen ────────────────────────────────────────────────────────────────────
function RouteScreen({ dark, businesses, cart, onBack, onStart }: {
  dark: boolean; businesses: Business[]; cart: number[]; onBack: () => void; onStart: () => void;
}) {
  const stops = (() => {
    const s = businesses.filter(b => cart.includes(b.id));
    return s.length > 0 ? s : businesses.filter(b => [1, 4, 5].includes(b.id));
  })();

  return (
    <div className="absolute inset-0 bg-background flex flex-col">
      <div className="flex items-center gap-3 px-4 pt-3 pb-3 border-b border-border">
        <button onClick={onBack} className="w-9 h-9 flex items-center justify-center rounded-full bg-muted text-foreground flex-none"><ChevronLeft size={20} /></button>
        <div>
          <h2 className="font-bold text-foreground text-[17px]">Your Stroll</h2>
          <p className="text-[11px] text-muted-foreground">{stops.length} stops · est. 45 min · 1.4 km</p>
        </div>
      </div>
      <div className="mx-4 mt-3 rounded-2xl overflow-hidden h-[100px] relative shadow border border-border">
        <CityMapSVG dark={dark} />
        {stops.map((b, i) => (
          <div key={b.id} className="absolute" style={{ left: `${b.mapX}%`, top: `${b.mapY}%`, transform: "translate(-50%,-50%)" }}>
            <div className="w-7 h-7 rounded-full text-white text-[11px] font-extrabold flex items-center justify-center shadow border-2 border-white" style={{ backgroundColor: b.color }}>{i + 1}</div>
          </div>
        ))}
      </div>
      <div className="mx-4 mt-3 p-3 bg-blue-50 dark:bg-blue-950/20 rounded-2xl border border-blue-200 dark:border-blue-900/50 flex items-start gap-2">
        <Navigation size={14} className="text-blue-500 mt-0.5 flex-none" />
        <div>
          <p className="text-[12px] font-bold text-blue-700 dark:text-blue-300">You're at Marktplatz</p>
          <p className="text-[11px] text-blue-600 dark:text-blue-400 leading-relaxed mt-0.5">Head toward the fountain, then turn east. Your first stop is 4 minutes on foot.</p>
        </div>
      </div>
      <div className="flex-1 overflow-y-auto px-4 py-3 space-y-2">
        {stops.map((b, i) => (
          <div key={b.id} className="flex gap-3">
            <div className="flex flex-col items-center flex-none">
              <div className="w-8 h-8 rounded-full text-white text-[12px] font-extrabold flex items-center justify-center shadow" style={{ backgroundColor: b.color }}>{i + 1}</div>
              {i < stops.length - 1 && <div className="w-px h-8 bg-border mt-1" />}
            </div>
            <div className="flex-1 bg-card border border-border rounded-2xl p-3 -mt-0.5">
              <div className="flex items-center justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-[13px] text-foreground">{b.name}</p>
                  <p className="text-[11px] text-muted-foreground">{b.distance} · {b.walkTime}</p>
                </div>
                <div className="bg-accent/20 border border-accent/40 px-2 py-1 rounded-xl flex-none">
                  <p className="text-[10px] font-extrabold text-foreground">{b.perk}</p>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
      <div className="px-4 pb-8 pt-2">
        <button onClick={onStart} className="w-full bg-primary text-primary-foreground rounded-2xl py-4 font-bold text-[15px] flex items-center justify-center gap-2 shadow-lg shadow-primary/25">
          <Sparkles size={18} /> Start strolling
        </button>
        <p className="text-center text-[11px] text-muted-foreground mt-2">AI-written narration · post at each stop</p>
      </div>
    </div>
  );
}

// ── Location Post Sheet ────────────────────────────────────────────────────────────
function LocationPostSheet({ step, media, onClose, onPosted }: {
  step: typeof STROLL_STEPS[0]; media: StepMedia;
  onClose: () => void; onPosted: () => void;
}) {
  const [caption, setCaption] = useState(step.aiCaption);
  const [posted, setPosted] = useState(false);

  function handlePost() {
    setPosted(true);
    setTimeout(() => { onPosted(); }, 1200);
  }

  return (
    <motion.div
      className="absolute inset-x-0 bottom-0 z-40 bg-card rounded-t-3xl shadow-2xl overflow-hidden"
      initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }}
      transition={{ type: "spring", stiffness: 280, damping: 28 }}
      style={{ maxHeight: "88%" }}
    >
      {/* Handle */}
      <div className="flex justify-center pt-3 pb-2"><div className="w-10 h-1 rounded-full bg-border" /></div>
      <button onClick={onClose} className="absolute top-3 right-4 w-8 h-8 flex items-center justify-center rounded-full bg-muted text-muted-foreground"><X size={15} /></button>

      <div className="overflow-y-auto px-4 pb-8" style={{ maxHeight: "calc(88vh - 40px)" }}>
        <div className="flex items-center gap-2 mb-3">
          <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: step.color }} />
          <p className="text-[12px] font-bold text-foreground">{step.business}</p>
          <span className="text-[11px] text-muted-foreground">· Post this stop</span>
        </div>

        {/* Media preview thumbnails */}
        <div className="flex gap-2 mb-4">
          {media.photo && (
            <div className="relative w-20 h-20 rounded-2xl overflow-hidden bg-muted flex-none">
              <img src="https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=160&h=160&fit=crop&auto=format" alt="" className="w-full h-full object-cover" />
              <div className="absolute bottom-1 right-1 bg-black/50 rounded-full w-5 h-5 flex items-center justify-center">
                <Camera size={10} className="text-white" />
              </div>
            </div>
          )}
          {media.voice && (
            <div className="w-20 h-20 rounded-2xl bg-purple-100 dark:bg-purple-950/30 flex flex-col items-center justify-center flex-none border border-purple-200 dark:border-purple-800/40">
              <Volume2 size={22} className="text-purple-500 mb-1" />
              <span className="text-[9px] text-purple-600 dark:text-purple-400 font-bold">0:23</span>
            </div>
          )}
          {media.text.trim() && (
            <div className="flex-1 min-w-0 h-20 rounded-2xl bg-blue-50 dark:bg-blue-950/20 border border-blue-200 dark:border-blue-800/40 p-2 overflow-hidden">
              <p className="text-[10px] text-blue-800 dark:text-blue-300 leading-relaxed line-clamp-4">{media.text}</p>
            </div>
          )}
          {!media.photo && !media.voice && !media.text.trim() && (
            <div className="w-20 h-20 rounded-2xl bg-muted flex items-center justify-center text-muted-foreground flex-none">
              <Camera size={22} />
            </div>
          )}
        </div>

        {/* AI Caption */}
        <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider mb-2">Caption</p>
        <div className="bg-background border border-border rounded-2xl p-3 mb-3">
          <div className="flex items-start gap-2">
            <div className="w-5 h-5 rounded-full bg-primary/15 flex items-center justify-center flex-none mt-0.5">
              <Sparkles size={10} className="text-primary" />
            </div>
            <textarea
              value={caption}
              onChange={e => setCaption(e.target.value)}
              className="flex-1 text-[12px] text-foreground bg-transparent resize-none outline-none leading-relaxed"
              rows={4}
            />
          </div>
        </div>

        {/* Hashtags */}
        <div className="flex gap-1.5 flex-wrap mb-4">
          {["#Strolling", `#${step.business.replace(/\s/g, "")}`, "#HiddenGems", "#CityWalks"].map(tag => (
            <span key={tag} className="text-[11px] text-primary bg-primary/10 px-2.5 py-1 rounded-full font-semibold">{tag}</span>
          ))}
        </div>

        {/* Post now buttons */}
        {!posted ? (
          <>
            <div className="grid grid-cols-2 gap-2 mb-3">
              <button onClick={handlePost} className="flex items-center justify-center gap-2 rounded-2xl py-3.5 text-[12px] font-bold text-white" style={{ background: "linear-gradient(135deg, #833AB4, #C13584, #E1306C)" }}>
                <svg viewBox="0 0 24 24" className="w-4 h-4 fill-white"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
                Post to Instagram
              </button>
              <button onClick={handlePost} className="flex items-center justify-center gap-2 bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 rounded-2xl py-3.5 text-[12px] font-bold">
                <svg viewBox="0 0 24 24" className="w-4 h-4 fill-current"><path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-2.88 2.5 2.89 2.89 0 01-2.89-2.89 2.89 2.89 0 012.89-2.89c.28 0 .54.04.79.1V9.01a6.33 6.33 0 00-.79-.05 6.34 6.34 0 00-6.34 6.34 6.34 6.34 0 006.34 6.34 6.34 6.34 0 006.33-6.34V8.72a8.24 8.24 0 004.83 1.55V6.82a4.85 4.85 0 01-1.06-.13z"/></svg>
                Post to TikTok
              </button>
            </div>
            <button onClick={onClose} className="w-full text-center text-[12px] text-muted-foreground py-2 font-medium flex items-center justify-center gap-1.5">
              <Bookmark size={13} /> Save draft — post later
            </button>
          </>
        ) : (
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="bg-green-50 dark:bg-green-950/25 border border-green-200 dark:border-green-800/50 rounded-2xl p-4 flex items-center gap-3"
          >
            <div className="w-10 h-10 rounded-full bg-green-500 flex items-center justify-center flex-none">
              <Check size={20} className="text-white" strokeWidth={3} />
            </div>
            <div>
              <p className="font-bold text-green-700 dark:text-green-300 text-[13px]">Posted! 🎉</p>
              <p className="text-[11px] text-green-600 dark:text-green-400">Continuing to next stop…</p>
            </div>
          </motion.div>
        )}
      </div>
    </motion.div>
  );
}

// ── Step Screen ─────────────────────────────────────────────────────────────────────
function StepScreen({
  steps, currentStep, setCurrentStep, media, setMedia,
  postedSteps, onPostStep, onFinish, onSaveAndExit,
}: {
  steps: typeof STROLL_STEPS; currentStep: number; setCurrentStep: (n: number) => void;
  media: Record<number, StepMedia>; setMedia: (id: number, m: StepMedia) => void;
  postedSteps: Set<number>; onPostStep: (id: number) => void;
  onFinish: () => void; onSaveAndExit: () => void;
}) {
  const [showPostSheet, setShowPostSheet] = useState(false);
  const [writingNote, setWritingNote] = useState(false);

  const step = steps[currentStep];
  const stepMedia = media[step.id] ?? { photo: false, voice: false, text: "" };
  const isPosted = postedSteps.has(step.id);
  const captured = hasCapture(stepMedia);
  const allDone = steps.every(s => postedSteps.has(s.id) || hasCapture(media[s.id]));

  // Reset writing mode when step changes
  useEffect(() => { setWritingNote(false); }, [currentStep]);

  function updateMedia(patch: Partial<StepMedia>) {
    setMedia(step.id, { ...stepMedia, ...patch });
  }

  const progress = (currentStep + (isPosted ? 1 : captured ? 0.5 : 0)) / steps.length;

  return (
    <div className="absolute inset-0 bg-background flex flex-col">
      {/* Progress */}
      <div className="h-1 bg-muted">
        <motion.div className="h-full bg-primary" animate={{ width: `${progress * 100}%` }} transition={{ duration: 0.4 }} />
      </div>

      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2.5 border-b border-border">
        <span className="text-[12px] font-semibold text-muted-foreground">Stop {currentStep + 1} of {steps.length}</span>
        <div className="flex items-center gap-2">
          {steps.map((s, i) => (
            <button key={s.id} onClick={() => setCurrentStep(i)}
              className={cn("w-2 h-2 rounded-full transition-all", i === currentStep ? "bg-primary scale-125" : postedSteps.has(s.id) ? "bg-green-500" : hasCapture(media[s.id]) ? "bg-primary/40" : "bg-muted-foreground/30")}
            />
          ))}
        </div>
        <button onClick={onSaveAndExit} className="flex items-center gap-1 text-[11px] text-muted-foreground font-medium">
          <Bookmark size={12} /> Pause
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-4 pb-2">
        {/* Business + title */}
        <div className="mt-3 mb-2">
          <div className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[11px] font-bold text-white mb-2" style={{ backgroundColor: step.color }}>
            <MapPin size={10} /> {step.business}
          </div>
          <h2 className="font-bold text-foreground text-xl leading-tight">{step.title}</h2>
        </div>

        {/* Narration */}
        <p className="text-[13px] text-muted-foreground leading-relaxed mb-3">{step.narration}</p>

        {/* Task box */}
        <div className="bg-primary/5 border border-primary/20 rounded-2xl p-3 mb-4">
          <div className="flex items-center gap-2 mb-1.5">
            <Sparkles size={12} className="text-primary" />
            <span className="text-[10px] font-extrabold text-primary uppercase tracking-wider">Your task</span>
          </div>
          <p className="text-[13px] font-semibold text-foreground">{step.task}</p>
        </div>

        {/* ── CAPTURE SECTION ── */}
        <p className="text-[11px] font-extrabold text-muted-foreground uppercase tracking-wider mb-2">Capture your moment</p>

        <div className="space-y-2 mb-3">
          {/* Photo / Video */}
          <div
            className={cn("rounded-2xl border transition-all overflow-hidden", stepMedia.photo ? "border-green-400 dark:border-green-700 bg-green-50 dark:bg-green-950/20" : "border-border bg-card")}
            onClick={() => !stepMedia.photo && updateMedia({ photo: true })}
          >
            {stepMedia.photo ? (
              <div className="flex items-center p-3 gap-3">
                <div className="w-14 h-14 rounded-xl overflow-hidden flex-none bg-muted relative">
                  <img src="https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=112&h=112&fit=crop&auto=format" alt="" className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-black/20 flex items-center justify-center">
                    <Play size={14} className="text-white" />
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5 mb-0.5">
                    <Check size={13} className="text-green-500" />
                    <span className="text-[12px] font-bold text-green-700 dark:text-green-300">Photo captured</span>
                  </div>
                  <p className="text-[11px] text-muted-foreground">Tap to retake</p>
                </div>
                <button onClick={(e) => { e.stopPropagation(); updateMedia({ photo: false }); }}
                  className="w-7 h-7 flex items-center justify-center rounded-full bg-muted text-muted-foreground flex-none">
                  <X size={13} />
                </button>
              </div>
            ) : (
              <button className="w-full flex items-center gap-3 p-4 cursor-pointer">
                <div className="w-11 h-11 rounded-xl bg-primary/10 flex items-center justify-center flex-none">
                  <Camera size={20} className="text-primary" />
                </div>
                <div className="text-left">
                  <p className="text-[13px] font-bold text-foreground">Photo or Video</p>
                  <p className="text-[11px] text-muted-foreground">Tap to open camera</p>
                </div>
              </button>
            )}
          </div>

          {/* Voice note */}
          <div
            className={cn("rounded-2xl border transition-all", stepMedia.voice ? "border-purple-400 dark:border-purple-700 bg-purple-50 dark:bg-purple-950/20" : "border-border bg-card")}
            onClick={() => !stepMedia.voice && updateMedia({ voice: true })}
          >
            {stepMedia.voice ? (
              <div className="flex items-center p-3 gap-3">
                <div className="w-11 h-11 rounded-xl bg-purple-500 flex items-center justify-center flex-none">
                  <Volume2 size={18} className="text-white" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-1.5 mb-1">
                    <Check size={13} className="text-purple-500" />
                    <span className="text-[12px] font-bold text-purple-700 dark:text-purple-300">Voice note · 0:23</span>
                  </div>
                  {/* Fake waveform */}
                  <div className="flex items-center gap-0.5 h-5">
                    {[3,5,8,4,7,9,5,6,8,4,3,6,8,5,4,7,6,3,8,5].map((h, i) => (
                      <div key={i} className="w-1 rounded-full bg-purple-400" style={{ height: h * 2 }} />
                    ))}
                  </div>
                </div>
                <button onClick={(e) => { e.stopPropagation(); updateMedia({ voice: false }); }}
                  className="w-7 h-7 flex items-center justify-center rounded-full bg-muted text-muted-foreground flex-none">
                  <X size={13} />
                </button>
              </div>
            ) : (
              <button className="w-full flex items-center gap-3 p-4 cursor-pointer">
                <div className="w-11 h-11 rounded-xl bg-purple-100 dark:bg-purple-950/30 flex items-center justify-center flex-none">
                  <Mic size={20} className="text-purple-500" />
                </div>
                <div className="text-left">
                  <p className="text-[13px] font-bold text-foreground">Voice note</p>
                  <p className="text-[11px] text-muted-foreground">Hold to record audio</p>
                </div>
              </button>
            )}
          </div>

          {/* Text note */}
          <div className={cn("rounded-2xl border transition-all", stepMedia.text.trim() ? "border-blue-400 dark:border-blue-700 bg-blue-50 dark:bg-blue-950/20" : "border-border bg-card")}>
            {writingNote ? (
              <div className="p-3">
                <div className="flex items-center gap-1.5 mb-2">
                  <AlignLeft size={13} className="text-blue-500" />
                  <span className="text-[11px] font-bold text-blue-700 dark:text-blue-300">Text note</span>
                </div>
                <textarea
                  autoFocus
                  value={stepMedia.text}
                  onChange={e => updateMedia({ text: e.target.value })}
                  placeholder="Write what you're experiencing right now..."
                  className="w-full text-[13px] text-foreground bg-transparent resize-none outline-none leading-relaxed placeholder:text-muted-foreground"
                  rows={4}
                />
                <div className="flex justify-end mt-2">
                  <button onClick={() => setWritingNote(false)} className="text-[11px] font-bold text-blue-600 dark:text-blue-400">Done</button>
                </div>
              </div>
            ) : (
              <button onClick={() => setWritingNote(true)} className="w-full flex items-center gap-3 p-4 cursor-pointer">
                <div className={cn("w-11 h-11 rounded-xl flex items-center justify-center flex-none", stepMedia.text.trim() ? "bg-blue-500" : "bg-blue-100 dark:bg-blue-950/30")}>
                  <AlignLeft size={20} className={stepMedia.text.trim() ? "text-white" : "text-blue-500"} />
                </div>
                <div className="text-left flex-1 min-w-0">
                  {stepMedia.text.trim() ? (
                    <>
                      <div className="flex items-center gap-1.5 mb-0.5"><Check size={13} className="text-blue-500" /><span className="text-[12px] font-bold text-blue-700 dark:text-blue-300">Note added</span></div>
                      <p className="text-[11px] text-muted-foreground truncate">{stepMedia.text}</p>
                    </>
                  ) : (
                    <>
                      <p className="text-[13px] font-bold text-foreground">Write a note</p>
                      <p className="text-[11px] text-muted-foreground">Your thoughts in words</p>
                    </>
                  )}
                </div>
              </button>
            )}
          </div>
        </div>

        {/* Hint */}
        <div className="bg-muted rounded-xl px-3 py-2 mb-3">
          <span className="text-[11px] text-muted-foreground">💡 {step.hint}</span>
        </div>
      </div>

      {/* Bottom actions */}
      <div className="px-4 pb-6 pt-2 space-y-2">
        {isPosted ? (
          <div className="bg-green-50 dark:bg-green-950/25 border border-green-200 dark:border-green-800/50 rounded-2xl p-3 flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-green-500 flex items-center justify-center flex-none"><Check size={18} className="text-white" strokeWidth={3} /></div>
            <div className="flex-1">
              <p className="font-bold text-green-700 dark:text-green-300 text-[13px]">Posted to Instagram ✓</p>
              <p className="text-[11px] text-green-600 dark:text-green-400">Keep going to the next stop!</p>
            </div>
          </div>
        ) : captured ? (
          <button onClick={() => setShowPostSheet(true)}
            className="w-full bg-primary text-primary-foreground rounded-2xl py-3.5 font-bold text-[14px] flex items-center justify-center gap-2 shadow-lg shadow-primary/25">
            <Share2 size={16} /> Post this stop
          </button>
        ) : (
          <div className="w-full bg-muted text-muted-foreground rounded-2xl py-3.5 font-bold text-[14px] flex items-center justify-center gap-2">
            <Camera size={16} /> Capture something first
          </div>
        )}

        {currentStep < steps.length - 1 ? (
          <button
            onClick={() => setCurrentStep(currentStep + 1)}
            className={cn("w-full rounded-2xl py-3 font-bold text-[14px] flex items-center justify-center gap-2 transition-all border",
              captured ? "border-primary text-primary" : "border-border text-muted-foreground"
            )}
          >
            {captured ? "Next stop →" : "Skip this stop"}
          </button>
        ) : (
          allDone || captured ? (
            <button onClick={onFinish}
              className="w-full bg-accent text-accent-foreground rounded-2xl py-3 font-bold text-[14px] flex items-center justify-center gap-2 border border-accent">
              <Trophy size={16} /> Finish my stroll!
            </button>
          ) : null
        )}
      </div>

      {/* Post sheet */}
      <AnimatePresence>
        {showPostSheet && (
          <LocationPostSheet
            step={step}
            media={stepMedia}
            onClose={() => setShowPostSheet(false)}
            onPosted={() => { setShowPostSheet(false); onPostStep(step.id); }}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

// ── Post Builder (final summary) ──────────────────────────────────────────────────
function PostBuilder({ businesses, cart, postedSteps, onDone }: {
  businesses: Business[]; cart: number[]; postedSteps: Set<number>; onDone: () => void;
}) {
  const stops = (() => {
    const s = businesses.filter(b => cart.includes(b.id));
    return s.length > 0 ? s : businesses.filter(b => [1, 4, 5].includes(b.id));
  })();

  return (
    <div className="absolute inset-0 bg-background flex flex-col overflow-y-auto">
      <div className="relative bg-gradient-to-br from-primary/10 via-accent/15 to-transparent px-4 pt-6 pb-4 text-center">
        <motion.div initial={{ scale: 0, rotate: -15 }} animate={{ scale: 1, rotate: 0 }} transition={{ type: "spring", stiffness: 280, damping: 18, delay: 0.08 }} className="text-5xl mb-2 select-none">🎉</motion.div>
        <h2 style={{ fontFamily: "Fraunces, serif" }} className="font-bold text-foreground text-2xl">Stroll complete!</h2>
        <p className="text-[13px] text-muted-foreground mt-1">{stops.length} stops · 45 min · 1.4 km</p>
        <div className="flex justify-center gap-2 mt-3">
          {stops.map(b => (
            <div key={b.id} className={cn("w-7 h-7 rounded-full flex items-center justify-center text-white text-xs shadow border-2 border-background", postedSteps.has(b.id) ? "ring-2 ring-green-400" : "")} style={{ backgroundColor: b.color }}>
              {postedSteps.has(b.id) ? <Check size={12} strokeWidth={3} /> : b.name[0]}
            </div>
          ))}
        </div>
        {postedSteps.size > 0 && (
          <p className="text-[11px] text-green-600 dark:text-green-400 font-semibold mt-2">{postedSteps.size} stop{postedSteps.size > 1 ? "s" : ""} already posted during the stroll</p>
        )}
      </div>

      <div className="px-4 py-3">
        <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider mb-3">Your stroll highlights</p>
        <div className="grid grid-cols-3 gap-2">
          {["https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200&h=200&fit=crop&auto=format",
            "https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=200&h=200&fit=crop&auto=format",
            "https://images.unsplash.com/photo-1483412033650-1015ddeb83d1?w=200&h=200&fit=crop&auto=format"].map((src, i) => (
            <div key={i} className="aspect-square rounded-2xl overflow-hidden bg-muted">
              <img src={src} alt="" className="w-full h-full object-cover" />
            </div>
          ))}
        </div>
      </div>

      <div className="px-4 mb-4">
        <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider mb-2">City guide post (optional)</p>
        <div className="bg-card border border-border rounded-2xl p-3">
          <div className="flex items-center gap-1.5 mb-2">
            <Sparkles size={12} className="text-primary" />
            <span className="text-[11px] font-bold text-primary">AI-written city guide</span>
          </div>
          <p className="text-[12px] text-muted-foreground leading-relaxed">
            "Spent the afternoon on a proper stroll through Stuttgart's hidden corners — coffee at @cafealma, ceramics at @studiomira, vinyl at @therecordloft. These three spots could not be more different but together they're exactly what this city is about. Save this for your next visit 📍"
          </p>
        </div>
        <div className="flex gap-1.5 mt-2 flex-wrap">
          {["#Strolling", "#Stuttgart", "#CityGuide", "#HiddenGems"].map(tag => (
            <span key={tag} className="text-[11px] text-primary bg-primary/10 px-2.5 py-1 rounded-full font-semibold">{tag}</span>
          ))}
        </div>
      </div>

      <div className="px-4 mb-3">
        <div className="grid grid-cols-3 gap-2">
          {[
            { label: "Instagram", cls: "bg-gradient-to-br from-purple-500 to-pink-500" },
            { label: "TikTok", cls: "bg-zinc-900 dark:bg-zinc-200 text-white dark:text-zinc-900" },
            { label: "Facebook", cls: "bg-blue-600" },
          ].map(s => (
            <button key={s.label} className={cn("py-3.5 rounded-2xl text-[11px] font-bold flex flex-col items-center gap-1.5", s.cls, "text-white")}>
              <Share2 size={15} /> {s.label}
            </button>
          ))}
        </div>
      </div>

      <div className="px-4 pb-8">
        <button onClick={onDone} className="w-full bg-accent text-accent-foreground font-bold rounded-2xl py-4 flex items-center justify-center gap-2 text-[14px] shadow-md">
          <Gift size={18} /> Claim {stops.length} perk{stops.length > 1 ? "s" : ""}!
        </button>
      </div>
    </div>
  );
}

// ── Perks Screen ─────────────────────────────────────────────────────────────────────
function PerksScreen({ businesses, cart }: { businesses: Business[]; cart: number[] }) {
  const stops = (() => {
    const s = businesses.filter(b => cart.includes(b.id));
    return s.length > 0 ? s : businesses.filter(b => [1, 4, 5].includes(b.id));
  })();
  const STATUSES = ["approved", "approved", "pending"];

  return (
    <div className="absolute inset-0 bg-background flex flex-col">
      <div className="px-4 pt-4 pb-3 border-b border-border">
        <h2 style={{ fontFamily: "Fraunces, serif" }} className="font-bold text-foreground text-xl">My Perks</h2>
        <p className="text-[11px] text-muted-foreground mt-0.5">{stops.length} perks ready to claim</p>
      </div>
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3 pb-24">
        {stops.map((b, i) => {
          const status = STATUSES[i % STATUSES.length];
          return (
            <div key={b.id} className="bg-card border border-border rounded-2xl p-4">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center text-white flex-none shadow" style={{ backgroundColor: b.color }}>
                  {getCategoryIcon(b.iconKey, 17)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-[13px] text-foreground">{b.name}</p>
                  <p className="text-[12px] font-semibold text-foreground">{b.perk}</p>
                </div>
                <span className={cn("text-[10px] font-bold px-2.5 py-1 rounded-full flex-none",
                  status === "approved" ? "bg-green-100 text-green-700 dark:bg-green-950/30 dark:text-green-400" : "bg-amber-100 text-amber-700 dark:bg-amber-950/30 dark:text-amber-400"
                )}>{status}</span>
              </div>
              {status === "approved" && (
                <div className="bg-muted rounded-xl p-3 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <QrCode size={32} className="text-foreground flex-none" />
                    <div>
                      <p className="text-[12px] font-bold text-foreground">Show at venue</p>
                      <p className="text-[11px] text-muted-foreground font-mono">STR-{(b.id * 3782 + 1234).toString(16).toUpperCase().slice(0, 4)}</p>
                    </div>
                  </div>
                  <ChevronRight size={15} className="text-muted-foreground" />
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ── Profile Screen ──────────────────────────────────────────────────────────────────
function ProfileScreen() {
  return (
    <div className="absolute inset-0 bg-background overflow-y-auto pb-24">
      <div className="relative h-28 bg-gradient-to-br from-primary/30 to-accent/30">
        <div className="absolute -bottom-8 left-4">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-orange-400 to-pink-500 border-4 border-background shadow-lg" />
        </div>
      </div>
      <div className="px-4 pt-11">
        <h2 className="font-bold text-foreground text-xl">Sophie Mayer</h2>
        <p className="text-[13px] text-muted-foreground">@sophie.explores · Stuttgart, DE</p>
        <div className="grid grid-cols-3 gap-2 mt-4 mb-5">
          {[["8.5K", "Followers"], ["12", "Strolls"], ["€180", "Perks earned"]].map(([v, l]) => (
            <div key={l} className="bg-card border border-border rounded-2xl p-3 text-center">
              <p className="font-bold text-foreground text-lg">{v}</p>
              <p className="text-[11px] text-muted-foreground leading-tight">{l}</p>
            </div>
          ))}
        </div>
        <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider mb-2">Connected accounts</p>
        <div className="space-y-2 mb-5">
          {[
            { label: "Instagram", handle: "@sophie.explores", connected: true, cls: "from-purple-500 to-pink-500" },
            { label: "Facebook", handle: "Sophie Mayer", connected: true, cls: "from-blue-600 to-blue-700" },
            { label: "TikTok", handle: "Coming soon", connected: false, cls: "from-zinc-400 to-zinc-500" },
          ].map(acc => (
            <div key={acc.label} className="bg-card border border-border rounded-2xl p-3 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className={cn("w-8 h-8 rounded-full bg-gradient-to-br flex items-center justify-center text-white text-[11px] font-extrabold flex-none", acc.cls)}>{acc.label[0]}</div>
                <div>
                  <p className="text-[13px] font-bold text-foreground">{acc.label}</p>
                  <p className="text-[11px] text-muted-foreground">{acc.handle}</p>
                </div>
              </div>
              {acc.connected ? <Check size={16} className="text-green-500" /> : <span className="text-[10px] text-muted-foreground bg-muted px-2 py-0.5 rounded-full font-medium">Soon</span>}
            </div>
          ))}
        </div>
        <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider mb-2">Recent strolls</p>
        {[{ date: "Jul 20", stops: 4, perks: "€47", city: "Stuttgart" }, { date: "Jul 14", stops: 3, perks: "€31", city: "Stuttgart" }, { date: "Jul 8", stops: 5, perks: "€62", city: "Munich" }].map((h, i) => (
          <div key={i} className="flex items-center justify-between py-3 border-b border-border last:border-0">
            <div className="flex items-center gap-3">
              <div className="w-2 h-2 rounded-full bg-primary flex-none" />
              <div><p className="text-[13px] font-semibold text-foreground">{h.city} · {h.stops} stops</p><p className="text-[11px] text-muted-foreground">{h.date}</p></div>
            </div>
            <span className="text-[13px] font-bold text-foreground">{h.perks}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Business Dashboard data (live API with offline fallback) ──────────────────────
const API = (import.meta as any).env?.VITE_API_URL ?? "http://localhost:3000";

type BizStatTile = { label: string; value: string; trend: string; cc: string; bc: string };
type BizOffer = { perk: string; remaining: number; total: number; req: string; eligible: number; type: string };
type BizCreator = { name: string; handle: string; status: string; eta: string; followers: string; cls: string };
type BizPost = { creator: string; platform: string; reach: string; likes: number; comments: number; img: string };

const BIZ_FALLBACK_STATS: BizStatTile[] = [
  { label: "Creators this month", value: "24", trend: "+6", cc: "text-blue-500", bc: "bg-blue-50 dark:bg-blue-950/25" },
  { label: "Posts live", value: "18", trend: "+3", cc: "text-emerald-500", bc: "bg-emerald-50 dark:bg-emerald-950/25" },
  { label: "Total reach", value: "142K", trend: "+28K", cc: "text-violet-500", bc: "bg-violet-50 dark:bg-violet-950/25" },
  { label: "Cost per post", value: "€8.30", trend: "−€1.2", cc: "text-primary", bc: "bg-primary/5" },
];
const BIZ_FALLBACK_OFFERS: BizOffer[] = [
  { perk: "3 free craft beers", remaining: 8, total: 20, req: "1 story + tag", eligible: 152, type: "in-kind" },
  { perk: "€25 cash payment", remaining: 3, total: 5, req: "1 post + 1 reel · 10K min", eligible: 28, type: "cash" },
];
const BIZ_FALLBACK_CREATORS: BizCreator[] = [
  { name: "Sophie M.", handle: "@sophie.explores", status: "en route", eta: "12 min", followers: "8.5K", cls: "from-orange-400 to-pink-500" },
  { name: "Lukas K.", handle: "@lukasinthewild", status: "arrived", eta: "now", followers: "22K", cls: "from-teal-400 to-cyan-500" },
  { name: "Anna B.", handle: "@byannab", status: "posted", eta: "done", followers: "41K", cls: "from-violet-400 to-purple-500" },
];
const BIZ_FALLBACK_POSTS: BizPost[] = [
  { creator: "@anna.explores", platform: "Instagram", reach: "38.2K", likes: 1240, comments: 87, img: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=80&h=80&fit=crop&auto=format" },
  { creator: "@cityguidemax", platform: "TikTok", reach: "61K", likes: 3850, comments: 214, img: "https://images.unsplash.com/photo-1483412033650-1015ddeb83d1?w=80&h=80&fit=crop&auto=format" },
];
const BIZ_CREATOR_GRADIENTS = ["from-orange-400 to-pink-500", "from-teal-400 to-cyan-500", "from-violet-400 to-purple-500"];
const BIZ_POST_IMGS = [
  "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=80&h=80&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1483412033650-1015ddeb83d1?w=80&h=80&fit=crop&auto=format",
];
const BIZ_PLATFORM_LABELS: Record<string, string> = { instagram: "Instagram", tiktok: "TikTok", facebook: "Facebook" };

function fmtK(n: number): string {
  if (!Number.isFinite(n) || n < 0) return "0";
  if (n < 1000) return String(n);
  const k = n / 1000;
  return `${k >= 100 ? Math.round(k) : Math.round(k * 10) / 10}K`;
}

function useBusinessDashboardData() {
  const [stats, setStats] = useState<BizStatTile[]>(BIZ_FALLBACK_STATS);
  const [offers, setOffers] = useState<BizOffer[]>(BIZ_FALLBACK_OFFERS);
  const [creators, setCreators] = useState<BizCreator[]>(BIZ_FALLBACK_CREATORS);
  const [posts, setPosts] = useState<BizPost[]>(BIZ_FALLBACK_POSTS);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const responses = await Promise.all([
          fetch(`${API}/api/business/demo/stats`),
          fetch(`${API}/api/business/demo/offers`),
          fetch(`${API}/api/business/demo/creators`),
          fetch(`${API}/api/business/demo/posts`),
        ]);
        if (responses.some(r => !r.ok)) return; // any failure → keep hardcoded demo data
        const [s, o, c, p] = await Promise.all(responses.map(r => r.json()));
        if (cancelled) return;

        // Stats: keep labels/colors/trends (trends not in the API), swap in live values.
        const postCount = Number(s?.posts ?? 0);
        const costEur = Number(s?.costEur ?? 0);
        const costPerPost = postCount > 0 ? costEur / postCount : costEur;
        setStats([
          { ...BIZ_FALLBACK_STATS[0], value: String(s?.creatorsHosted ?? 0) },
          { ...BIZ_FALLBACK_STATS[1], value: String(postCount) },
          { ...BIZ_FALLBACK_STATS[2], value: fmtK(Number(s?.totalReach ?? 0)) },
          { ...BIZ_FALLBACK_STATS[3], value: `€${costPerPost.toFixed(2)}` },
        ]);

        setOffers(
          (Array.isArray(o) ? o : [])
            .filter((x: any) => x?.active !== false)
            .map((x: any): BizOffer => {
              const minFollowers = Number(x?.minFollowers ?? 0);
              return {
                perk: String(x?.perkTitle ?? ""),
                remaining: Number(x?.slotsRemaining ?? 0),
                total: Number(x?.slotsTotal ?? 0) || 1,
                req: `${x?.deliverable ?? ""}${minFollowers > 0 ? ` · ${fmtK(minFollowers)} min` : ""}`,
                // "eligible" is not part of the API contract — estimated client-side.
                eligible: Math.max(5, 152 - Math.round(minFollowers / 80)),
                type: x?.offerType === "cash" ? "cash" : "in-kind",
              };
            }),
        );

        setCreators(
          (Array.isArray(c) ? c : []).map((x: any, i: number): BizCreator => {
            const status = x?.status === "en_route" ? "en route" : String(x?.status ?? "en route");
            return {
              name: String(x?.name ?? ""),
              handle: String(x?.handle ?? "").startsWith("@") ? String(x?.handle) : `@${x?.handle ?? ""}`,
              status,
              eta: status === "en route" ? `${Number(x?.etaMin ?? 0)} min` : status === "arrived" ? "now" : "done",
              followers: fmtK(Number(x?.followers ?? 0)),
              cls: BIZ_CREATOR_GRADIENTS[i % BIZ_CREATOR_GRADIENTS.length],
            };
          }),
        );

        setPosts(
          (Array.isArray(p) ? p : []).map((x: any, i: number): BizPost => ({
            creator: String(x?.creatorHandle ?? "").startsWith("@") ? String(x?.creatorHandle) : `@${x?.creatorHandle ?? "creator"}`,
            platform: BIZ_PLATFORM_LABELS[String(x?.platform ?? "")] ?? String(x?.platform ?? ""),
            reach: fmtK(Number(x?.reach ?? 0)),
            likes: Number(x?.likes ?? 0),
            comments: Number(x?.comments ?? 0),
            img: BIZ_POST_IMGS[i % BIZ_POST_IMGS.length],
          })),
        );
      } catch {
        // Backend offline — keep the hardcoded demo data as fallback.
      }
    })();
    return () => { cancelled = true; };
  }, []);

  return { stats, offers, creators, posts };
}

// ── Business Dashboard ─────────────────────────────────────────────────────────────
function BusinessDashboard() {
  const [activeTab, setActiveTab] = useState<"offers" | "creators" | "posts" | "redeem">("offers");
  const { stats: bizStats, offers: bizOffers, creators: bizCreators, posts: bizPosts } = useBusinessDashboardData();
  return (
    <div className="absolute inset-0 bg-background flex flex-col">
      <div className="px-4 pt-4 pb-0 border-b border-border">
        <div className="flex items-center justify-between mb-3">
          <div>
            <p className="text-[11px] font-extrabold text-primary uppercase tracking-widest">Strolling for Business</p>
            <h2 style={{ fontFamily: "Fraunces, serif" }} className="font-bold text-foreground text-xl mt-0.5">Bar Soleil</h2>
          </div>
          <div className="flex items-center gap-2">
            <button className="w-9 h-9 flex items-center justify-center rounded-full bg-muted text-muted-foreground"><Bell size={17} /></button>
            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-violet-500 to-indigo-600 shadow" />
          </div>
        </div>
        <div className="flex gap-0.5 overflow-x-auto scrollbar-hide pb-3">
          {(["offers", "creators", "posts", "redeem"] as const).map(t => (
            <button key={t} onClick={() => setActiveTab(t)}
              className={cn("flex-none px-4 py-2 rounded-full text-[11px] font-bold capitalize transition-all", activeTab === t ? "bg-primary text-primary-foreground" : "text-muted-foreground")}>
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>
      </div>
      <div className="px-4 py-3 grid grid-cols-2 gap-2">
        {bizStats.map(s => (
          <div key={s.label} className={cn("rounded-2xl p-3", s.bc)}>
            <p className={cn("text-xl font-extrabold", s.cc)}>{s.value}</p>
            <p className="text-[11px] text-muted-foreground leading-tight">{s.label}</p>
            <p className={cn("text-[11px] font-bold mt-1", s.cc)}>{s.trend} this week</p>
          </div>
        ))}
      </div>
      <div className="flex-1 overflow-y-auto px-4 pb-8 space-y-3">
        {activeTab === "offers" && (
          <>
            <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider">Active offers</p>
            {bizOffers.map((o, i) => (
              <div key={i} className="bg-card border border-border rounded-2xl p-4">
                <div className="flex items-center justify-between mb-3">
                  <span className="font-bold text-[14px] text-foreground">{o.perk}</span>
                  <span className={cn("text-[10px] font-extrabold px-2.5 py-1 rounded-full", o.type === "cash" ? "bg-green-100 text-green-700 dark:bg-green-950/40 dark:text-green-400" : "bg-amber-100 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400")}>{o.type}</span>
                </div>
                <div className="w-full bg-muted rounded-full h-1.5 mb-2">
                  <div className="h-1.5 rounded-full bg-primary" style={{ width: `${((o.total - o.remaining) / o.total) * 100}%` }} />
                </div>
                <div className="flex justify-between text-[11px] text-muted-foreground mb-1"><span>{o.total - o.remaining} claimed · {o.remaining} left</span><span>{o.eligible} eligible</span></div>
                <p className="text-[11px] text-muted-foreground">Requires: {o.req}</p>
              </div>
            ))}
            <button className="w-full border-2 border-dashed border-border rounded-2xl py-4 text-[13px] font-bold text-muted-foreground flex items-center justify-center gap-2"><Plus size={15} /> Add new offer</button>
          </>
        )}
        {activeTab === "creators" && (
          <>
            <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider">Creator activity</p>
            {bizCreators.map((c, i) => (
              <div key={i} className="bg-card border border-border rounded-2xl p-3 flex items-center gap-3">
                <div className={cn("w-10 h-10 rounded-full bg-gradient-to-br flex-none shadow", c.cls)} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5"><p className="font-bold text-[13px] text-foreground">{c.name}</p><span className="text-[11px] text-muted-foreground">· {c.followers}</span></div>
                  <p className="text-[11px] text-muted-foreground">{c.handle}</p>
                </div>
                <span className={cn("text-[10px] font-extrabold px-2.5 py-1 rounded-full flex-none",
                  c.status === "posted" ? "bg-green-100 text-green-700 dark:bg-green-950/30 dark:text-green-400" : c.status === "arrived" ? "bg-blue-100 text-blue-700 dark:bg-blue-950/30 dark:text-blue-400" : "bg-amber-100 text-amber-700 dark:bg-amber-950/30 dark:text-amber-400"
                )}>{c.status === "en route" ? c.eta : c.status}</span>
              </div>
            ))}
          </>
        )}
        {activeTab === "posts" && (
          <>
            <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider">Live posts</p>
            {bizPosts.map((p, i) => (
              <div key={i} className="bg-card border border-border rounded-2xl p-3 flex gap-3">
                <img src={p.img} alt="" className="w-14 h-14 rounded-xl object-cover flex-none bg-muted" />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-1"><p className="font-bold text-[13px] text-foreground">{p.creator}</p><span className="text-[10px] text-muted-foreground">{p.platform}</span></div>
                  <div className="flex items-center gap-3 text-[11px] text-muted-foreground">
                    <span className="flex items-center gap-1"><Eye size={11} />{p.reach}</span>
                    <span className="flex items-center gap-1"><Heart size={11} />{p.likes.toLocaleString()}</span>
                    <span className="flex items-center gap-1"><MessageCircle size={11} />{p.comments}</span>
                  </div>
                </div>
              </div>
            ))}
          </>
        )}
        {activeTab === "redeem" && (
          <>
            <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider">Pending redemptions</p>
            {[
              { creator: "Sophie M.", perk: "3 free craft beers", code: "STR-A4BX", time: "just now" },
              { creator: "Lukas K.", perk: "3 free craft beers", code: "STR-7YMQ", time: "8 min ago" },
            ].map((r, i) => (
              <div key={i} className="bg-card border border-border rounded-2xl p-4">
                <div className="flex items-center justify-between mb-3">
                  <div><p className="font-bold text-[13px] text-foreground">{r.creator}</p><p className="text-[11px] text-muted-foreground">{r.perk} · {r.time}</p></div>
                  <span className="font-mono text-[11px] bg-muted px-2.5 py-1.5 rounded-xl text-foreground font-bold">{r.code}</span>
                </div>
                <div className="flex gap-2">
                  <button className="flex-1 bg-emerald-500 text-white rounded-xl py-2.5 text-[12px] font-bold flex items-center justify-center gap-1"><Check size={13} /> Approve</button>
                  <button className="flex-1 bg-muted text-muted-foreground rounded-xl py-2.5 text-[12px] font-bold flex items-center justify-center gap-1"><X size={13} /> Decline</button>
                </div>
              </div>
            ))}
          </>
        )}
      </div>
    </div>
  );
}

// ── Status Bar ────────────────────────────────────────────────────────────────────
function StatusBarComp() {
  return (
    <div className="flex items-center justify-between px-5 pt-3 pb-1 text-[11px] font-bold text-foreground">
      <span>9:41</span>
      <div className="flex items-center gap-1.5">
        <div className="flex items-end gap-[2px]">
          {[10, 14, 18, 22].map((h, i) => (<div key={i} className="w-[3px] rounded-sm bg-foreground" style={{ height: h, opacity: i < 3 ? 1 : 0.35 }} />))}
        </div>
        <svg viewBox="0 0 24 12" className="w-5 h-3 fill-foreground">
          <rect x="0" y="1" width="21" height="10" rx="2" stroke="currentColor" strokeWidth="1.5" fill="none" />
          <rect x="22" y="3.5" width="2" height="5" rx="1" />
          <rect x="1.5" y="2.5" width="16" height="7" rx="1" />
        </svg>
      </div>
    </div>
  );
}

// ── App ───────────────────────────────────────────────────────────────────────────
export default function App() {
  const [dark, setDark] = useState(false);
  const [appState, setAppState] = useState<AppState>("auth");
  const [appMode, setAppMode] = useState<"creator" | "business">("creator");
  const [screen, setScreen] = useState<CreatorScreen>("map");
  const [tab, setTab] = useState("map");
  const [mapMode, setMapMode] = useState<MapMode>("earn");
  const [selectedBusiness, setSelectedBusiness] = useState<number | null>(null);
  const [cart, setCart] = useState<number[]>([]);
  const [currentStep, setCurrentStep] = useState(0);
  const [stepMedia, setStepMediaState] = useState<Record<number, StepMedia>>({});
  const [postedSteps, setPostedSteps] = useState<Set<number>>(new Set());
  const [savedProgress, setSavedProgress] = useState(false);

  function setStepMedia(id: number, m: StepMedia) {
    setStepMediaState(prev => ({ ...prev, [id]: m }));
  }

  function handleTabChange(t: string) {
    setTab(t);
    setScreen(t as CreatorScreen);
    setSelectedBusiness(null);
  }

  function handleAddToCart(id: number) {
    if (!cart.includes(id) && cart.length < 5) setCart(prev => [...prev, id]);
  }

  function handleRemoveFromCart(id: number) {
    setCart(prev => prev.filter(c => c !== id));
  }

  function handleCreateRoute() {
    setSelectedBusiness(null);
    setScreen("route");
  }

  function handleStartStroll() {
    setCurrentStep(0);
    setStepMediaState({});
    setPostedSteps(new Set());
    setSavedProgress(false);
    setScreen("step");
  }

  function handlePostStep(id: number) {
    setPostedSteps(prev => new Set([...prev, id]));
  }

  function handleSaveAndExit() {
    setSavedProgress(true);
    setTab("map");
    setScreen("map");
  }

  function handleResume() {
    setScreen("step");
  }

  const screenKey = appMode === "business" ? "biz" : screen;

  const screenEl = appMode === "business" ? <BusinessDashboard key="biz" />
    : screen === "map" ? (
      <MapScreen key="map" dark={dark} businesses={BUSINESSES} cart={cart} mapMode={mapMode} setMapMode={setMapMode}
        selectedBusiness={selectedBusiness} setSelectedBusiness={setSelectedBusiness}
        onAddToCart={handleAddToCart} onRemoveFromCart={handleRemoveFromCart}
        onCreateRoute={handleCreateRoute} savedProgress={savedProgress} onResume={handleResume} />
    ) : screen === "route" ? (
      <RouteScreen key="route" dark={dark} businesses={BUSINESSES} cart={cart} onBack={() => setScreen("map")} onStart={handleStartStroll} />
    ) : screen === "step" ? (
      <StepScreen key="step" steps={STROLL_STEPS} currentStep={currentStep} setCurrentStep={setCurrentStep}
        media={stepMedia} setMedia={setStepMedia} postedSteps={postedSteps}
        onPostStep={handlePostStep} onFinish={() => setScreen("post")} onSaveAndExit={handleSaveAndExit} />
    ) : screen === "post" ? (
      <PostBuilder key="post" businesses={BUSINESSES} cart={cart} postedSteps={postedSteps} onDone={() => { setTab("perks"); setScreen("perks"); }} />
    ) : screen === "perks" ? (
      <PerksScreen key="perks" businesses={BUSINESSES} cart={cart} />
    ) : screen === "profile" ? (
      <ProfileScreen key="profile" />
    ) : null;

  const showBottomNav = appMode === "creator" && ["map", "perks", "profile"].includes(screen);

  return (
    <div className={dark ? "dark" : ""}>
      <div className="min-h-screen bg-zinc-100 dark:bg-zinc-950 transition-colors duration-300 flex flex-col items-center justify-start pt-6 pb-12 px-4"
        style={{ backgroundImage: dark ? "radial-gradient(circle, rgba(255,255,255,0.03) 1px, transparent 1px)" : "radial-gradient(circle, rgba(0,0,0,0.05) 1px, transparent 1px)", backgroundSize: "24px 24px" }}>

        {/* Top controls (only shown after auth) */}
        {appState === "main" && (
          <div className="flex items-center gap-3 mb-6 flex-wrap justify-center">
            <div className="flex bg-white dark:bg-zinc-800 rounded-full p-1 shadow border border-zinc-200 dark:border-zinc-700 gap-0.5">
              {(["creator", "business"] as const).map(m => (
                <button key={m} onClick={() => setAppMode(m)}
                  className={cn("px-5 py-2 rounded-full text-sm font-bold transition-all", appMode === m ? "bg-primary text-primary-foreground shadow-sm" : "text-zinc-500 dark:text-zinc-400")}>
                  {m === "creator" ? "Creator App" : "For Business"}
                </button>
              ))}
            </div>
            <button onClick={() => setDark(!dark)}
              className="bg-white dark:bg-zinc-800 rounded-full p-3 shadow border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 transition-colors">
              {dark ? <Sun size={18} /> : <Moon size={18} />}
            </button>
          </div>
        )}

        {appState !== "main" && (
          <div className="flex items-center gap-3 mb-6">
            <button onClick={() => setDark(!dark)}
              className="bg-white dark:bg-zinc-800 rounded-full p-3 shadow border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 transition-colors">
              {dark ? <Sun size={18} /> : <Moon size={18} />}
            </button>
          </div>
        )}

        {/* Phone frame */}
        <div className="relative" style={{ width: 393 }}>
          <div className="relative rounded-[48px] bg-zinc-900 shadow-2xl overflow-hidden" style={{ height: 852, padding: 12 }}>
            <div className="absolute top-3 left-1/2 -translate-x-1/2 w-28 h-[34px] bg-zinc-900 rounded-full z-50" />
            <div className="relative w-full h-full rounded-[38px] overflow-hidden bg-background">
              <StatusBarComp />
              <div className="relative" style={{ height: "calc(100% - 36px)" }}>
                <AnimatePresence mode="wait">
                  {appState === "auth" ? (
                    <motion.div key="auth" className="absolute inset-0" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, x: -20 }} transition={{ duration: 0.2 }}>
                      <AuthScreen dark={dark} onLogin={() => setAppState("onboard")} />
                    </motion.div>
                  ) : appState === "onboard" ? (
                    <motion.div key="onboard" className="absolute inset-0" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} transition={{ duration: 0.2 }}>
                      <OnboardingScreen onComplete={() => setAppState("main")} />
                    </motion.div>
                  ) : (
                    <motion.div key={screenKey} className="absolute inset-0" initial={{ opacity: 0, x: 18 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -18 }} transition={{ duration: 0.18, ease: "easeInOut" }}>
                      {screenEl}
                    </motion.div>
                  )}
                </AnimatePresence>
                {appState === "main" && showBottomNav && (
                  <BottomNav tab={tab} setTab={handleTabChange} cartCount={cart.length} />
                )}
              </div>
            </div>
          </div>
          {/* Phone side buttons */}
          <div className="absolute right-0 top-28 w-[3px] h-16 bg-zinc-700 rounded-l-full" />
          <div className="absolute right-0 top-[192px] w-[3px] h-10 bg-zinc-700 rounded-l-full" />
          <div className="absolute left-0 top-[110px] w-[3px] h-8 bg-zinc-700 rounded-r-full" />
          <div className="absolute left-0 top-[148px] w-[3px] h-14 bg-zinc-700 rounded-r-full" />
          <div className="absolute left-0 top-[178px] w-[3px] h-14 bg-zinc-700 rounded-r-full" />
        </div>

        <div className="mt-5 text-center select-none">
          <p style={{ fontFamily: "Fraunces, serif" }} className="font-bold text-zinc-800 dark:text-zinc-200 text-lg tracking-tight">Strolling</p>
          <p className="text-xs text-zinc-400 mt-0.5">
            {appState === "auth" ? "Interactive prototype · Login screen" : appState === "onboard" ? "Onboarding flow" : `${appMode === "creator" ? "Creator app" : "Business dashboard"}${cart.length > 0 ? ` · ${cart.length} stop${cart.length > 1 ? "s" : ""} in cart` : ""}`}
          </p>
        </div>
      </div>
    </div>
  );
}
