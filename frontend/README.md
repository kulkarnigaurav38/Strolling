# Strolling 🚶

**Walk the city. Get rewarded.**

The Flutter client for Strolling, matching the Figma Make design
([CursorStutt](https://www.figma.com/make/1fpV6kfWgSY2WZrSc66nP1/CursorStutt), v5):
pick businesses on a Stuttgart map, get a **themed shooting script** for your stroll,
capture photo/video/voice/text at each stop, publish per-stop posts, earn perks.

Everything external is **mocked and runs with zero keys**. The only real hardware is
the camera/file picker.

## The flow

**Onboarding** (mock social login) → **Map** (mode switch Roam/Earn, category chips,
perk pins, business sheet, 2+ stops → cart) → **Pick your script style** →
**My Stroll** (scene timeline + totals) → **Step screen** (script card + the three
capture cards) → **Post builder** (AI caption, platform selector) → **Perks wallet**
(pending → approved → redeemed, QR).

## Script templates

`lib/core/script_templates.dart` turns the user's picks into a per-stop shooting
script. Each scene has a themed title, staging direction, a line to deliver, the perk
deliverable woven in, and **the capture actions to open** (📸 🎬 🎙️ ✍️). Actions
required by a perk deliverable ("1 photo + 1 story post") gate the Post button.

| Template | Vibe |
| --- | --- |
| 🎀 The Symmetrist (à la Wes Anderson) | pastel, dead-center framing, deadpan captions |
| 🔴 One-Point Stare (à la Kubrick) | one-point perspective, slow push-ins |
| 🎙️ Der Doku | honest handheld documentary, interview yourself |
| ⚡ Whatever's Viral | hook in 0.5s, whip-pans, POV captions |

The generator is pure Dart — a later commit swaps it for Claude without touching
any screen.

## Stack notes

- **Map**: `flutter_map` + OpenStreetMap tiles (no API key), businesses at real
  Stuttgart coordinates; journey header is a non-interactive mini-map with the
  route polyline.
- **Type**: SF Pro Text (bundled from this Mac's installed Apple fonts —
  fine for the demo; check licensing before shipping). No emoji in UI chrome —
  CupertinoIcons (SF-symbol style) + Material rounded icons.
- **Backend wire**: run with `--dart-define=STROLLING_MOCK=false
  --dart-define=API_BASE_URL=http://localhost:3000` and scripts come from
  `POST /api/scripts` (local generator is the offline fallback).

## Run

Prereqs: Flutter 3.27+ and a device/emulator (or Chrome for web).

```bash
# 1. Generate the platform folders (kept out of git — see .gitignore).
flutter create --platforms=android,ios,web .

# 2. Add platform permissions below (camera), then:
flutter pub get

# 3. Run — no keys needed, everything is mocked.
flutter run                      # device / Chrome
flutter run -d web-server --web-port 8080   # any browser
```

### Platform permissions (add after `flutter create .`)

**android/app/src/main/AndroidManifest.xml** — inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**ios/Runner/Info.plist**:

```xml
<key>NSCameraUsageDescription</key>
<string>Strolling uses the camera to shoot your stops.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Strolling records voice notes at your stops.</string>
```

## Structure

```
lib/
  main.dart                     entry, portrait lock
  core/
    models.dart                 Business, StopDraft, Perk, CaptureAction
    seed.dart                   Stuttgart businesses + mock AI captions
    script_templates.dart       the template engine (4 themed templates)
    state.dart                  Riverpod: auth, mode, cart, stroll, perks (persisted)
    theme.dart  copy.dart  router.dart
  features/
    onboarding/                 sunset hero + social logins
    map/                        painter, pins, mode switch, business sheet
    template/                   script style picker
    journey/                    stroll timeline + totals
    step/                       script card + photo/video + voice + note cards
    post/                       per-stop post builder
    perks/  profile/  shell/    wallet, stats, bottom nav
```

## Mocks → real (future commits)

- Social login → real OAuth
- `draftCaption()` + `script_templates.dart` → Claude generation via the backend
- Voice recorder → real recording
- Publish → backend `/api/publish` → n8n → socials
- Map → real map tiles + GPS
