# Strolling

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
deliverable woven in, and **the capture actions to open** (photo / video / voice /
text). Actions required by a perk deliverable ("1 photo + 1 story post") gate the
Post button.

| Template | Vibe |
| --- | --- |
| The Symmetrist (à la Wes Anderson) | centered frames, level horizons, deadpan captions |
| One-Point Stare (à la Kubrick) | one-point perspective, slow push-ins |
| Der Doku | handheld documentary, real sound, first takes |
| Whatever's Viral | hook first, fast cuts, POV captions |

The generator is pure Dart — a later commit swaps it for Claude without touching
any screen.

## Stack notes

- **Map**: `flutter_map` + OpenStreetMap tiles (no API key), businesses at real
  Stuttgart coordinates; journey header is a non-interactive mini-map with the
  route polyline.
- **Type**: SF Pro Text (bundled from a Mac's installed Apple fonts —
  fine for the demo; check licensing before shipping). No emoji in UI chrome —
  CupertinoIcons (SF-symbol style) + Material rounded icons.
- **Backend wire**: run with `--dart-define=STROLLING_MOCK=false
  --dart-define=API_BASE_URL=http://localhost:3000` and scripts come from
  `POST /api/scripts` (local generator is the offline fallback).

## Run

Prereqs: Flutter 3.27+ and a device/emulator (or Chrome for web). Platform folders
(`android/`, `ios/`, `web/`) are committed; camera/mic permissions are already in the
Android manifest and iOS Info.plist.

```bash
flutter pub get
flutter run                                  # device / Chrome
flutter run -d web-server --web-port 8080    # any browser
```

## Structure

```
lib/
  main.dart                     entry, portrait lock
  core/
    models.dart                 Business, StopDraft, Perk, CaptureAction, ScriptStep
    seed.dart                   Stuttgart businesses + mock AI captions
    script_templates.dart       the template engine (4 themed templates)
    state.dart                  Riverpod: auth, mode, cart, stroll, perks (persisted)
    api/api_client.dart         dio client for POST /api/scripts
    theme.dart  copy.dart  router.dart  config.dart
  features/
    onboarding/                 sunset hero + social logins
    map/                        flutter_map, pins, mode switch, business sheet
    template/                   script style picker
    journey/                    stroll timeline + mini-map + totals
    step/                       script card + photo/video + voice + note cards
    post/                       per-stop post builder
    perks/  profile/  shell/    wallet, stats, bottom nav
```

## Mocks → real (future commits)

- Social login → real OAuth
- `draftCaption()` + script generator → Claude via the backend (`POST /api/scripts`)
- Voice recorder → real recording
- Publish → backend `/api/publish` → n8n → socials
- User location → real GPS
