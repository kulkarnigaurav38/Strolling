# FERNWEH 🎬

**Walk in. Talk for 20 minutes. Walk out with a published video.**

A guided micro-shoot: der Regisseur (a warm German film director) walks a first-time
creator through five shots of a place, interviews them about each, then cuts, captions,
and publishes a vertical mini-doc. Built for the Cursor Hackathon Stuttgart.

---

## Commit 1 — the skeleton (tracer bullet)

This commit makes the **entire creator flow clickable on a phone with every external
service mocked**. It runs with **zero keys**. The only real hardware is the camera. Every
later commit swaps exactly one mock for one real integration — grep the tree for
`TODO(COMMIT-n)` to see each seam.

Flow: **Brief → Shoot (×5) → Interview → Render → Done**, state-driven end to end.

## Stack

- **Flutter 3.x / Dart**, portrait-only
- **go_router** — routes are a projection of the session status (`lib/core/router.dart`)
- **Riverpod + shared_preferences** — one `SessionController`, persisted so a mid-shoot
  restart resumes exactly where you left off
- **dio** — a single `ApiClient` (`lib/core/api/`)
- **camera** — live `CameraPreview` with a `Stack` overlay of shot guidance
- **video_player** — plays the (mocked) rendered film
- **permission_handler** — camera + mic requested on first launch
- One `ThemeData` (`lib/core/theme.dart`), no visible Material defaults

## Run

Prereqs: Flutter 3.27+ and a device/emulator (or Chrome for web). Verified on
Flutter 3.44 / Dart 3.12.

```bash
# 1. Generate the platform folders (kept out of git — see .gitignore).
#    This does not touch lib/ or pubspec.yaml.
flutter create --platforms=android,ios,web .

# 2. Add the platform permissions below (Android manifest + iOS Info.plist), then:
flutter pub get

# 3. Run — no keys needed, everything is mocked.
flutter run

# Ship:
flutter build apk --release
flutter build web
```

### Platform permissions (add after `flutter create .`)

**android/app/src/main/AndroidManifest.xml** — inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

Set `minSdkVersion` to at least `21` in `android/app/build.gradle`.

**ios/Runner/Info.plist**:

```xml
<key>NSCameraUsageDescription</key>
<string>Fernweh uses the camera to shoot your mini-doc.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Fernweh records your voice for the video.</string>
```

## The mock flag

The whole app is gated by `Config.mock` (`lib/core/config.dart`), which defaults **on**
so it runs with no credentials. Override at build time:

```bash
# turn the master mock OFF (later commits wire real backends per route)
flutter run --dart-define=FERNWEH_MOCK=false

# or load everything from a file (copy the example first)
cp dart_defines.example.json dart_defines.json
flutter run --dart-define-from-file=dart_defines.json
```

## Project structure

```
lib/
  main.dart                     app entry, portrait lock, first-launch permissions
  core/                         shared across features
    models.dart                 the contract (Task, Capture, Review, ShootSession, …)
    seed.dart  copy.dart        business + shot list + UI copy (verbatim from the brief)
    director.dart               DIRECTOR_SYSTEM_PROMPT (version-controlled persona)
    config.dart  theme.dart  router.dart
    api/api_client.dart         single dio ApiClient (mocked)
    session/session_controller.dart   Riverpod + shared_preferences
    widgets/                    AppScaffold, PrimaryButton, Pill, Panel, local_image
  features/
    brief/screens/              BriefScreen
    shoot/{screens,widgets}/    camera + TaskCard + ProgressPips + ShutterButton
    interview/{screens,widgets} InterviewPanel + DirectorWidget (mock typewriter)
    render/screens/             RenderScreen
    done/screens/               DoneScreen (video + caption + payoff)
assets/mock/sample.mp4          stand-in rendered film
```

## Commit roadmap

| Commit | Replaces the mock in… | With |
| ------ | --------------------- | ---- |
| **2** | `DirectorWidget` | ElevenLabs conversational WebSocket (`web_socket_channel`); WebView of the React widget as fallback |
| **3** | `ApiClient.generateTasks`, `uploadMedia` | Claude task generation + fal storage |
| **4** | `ApiClient.render` | fal i2v + ffmpeg compose, real-voice narration |
| **5** | `ApiClient.publish` | n8n webhook → YouTube Short |
| **6** | — | venue shoot + polish |

## Not in this commit

Real agent audio, fal/LLM/n8n calls, GPS checks, style picker UI, business onboarding,
auth, DB.
