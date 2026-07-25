# strolling

Flutter client for Strolling.

## Google Maps

The explore screen uses the **normal** Google Maps style (not satellite).

1. Create a key in [Google Cloud Console](https://console.cloud.google.com/) with **Maps SDK for Android**, **Maps SDK for iOS**, and (if needed) **Maps JavaScript API**.
2. **Android** — add to `android/local.properties`:
   ```
   GOOGLE_MAPS_API_KEY=your_key_here
   ```
3. **iOS** — copy `ios/Flutter/Secrets.xcconfig.example` → `ios/Flutter/Secrets.xcconfig` and set the key.
4. **Web** — replace `YOUR_KEY_HERE` in `web/index.html`.

Then do a full app restart (not just hot reload).

## Run

```bash
flutter pub get
flutter run
```
