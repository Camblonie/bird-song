# Bird Song 🐦

An iOS app that listens through the microphone and identifies bird calls in real time, focused on **US Midwest species**. When birds are detected the app shows a photo, common name, scientific name, and confidence score. Users can log sightings and review their full history.

---

## Current Status

| Area | Status |
|------|--------|
| SwiftUI app shell | ✅ Complete |
| Audio capture (AVAudioEngine, 48 kHz mono) | ✅ Complete |
| Bird catalog (~85 Midwest species) | ✅ Complete |
| Listening UI with detection cards | ✅ Complete |
| History / sighting log (SwiftData) | ✅ Complete |
| JSON export via share sheet | ✅ Complete |
| Bird photos in asset catalog | ⚠️ Partial (~40 of 85 downloaded) |
| ML inference — mock mode | ✅ Complete (cycles through species) |
| ML inference — BirdNET API server | ✅ Complete (requires Mac on same Wi-Fi) |
| ML inference — on-device Create ML | 🔲 In progress (needs xeno-canto audio) |

---

## Features

- **Real-time identification** — Continuously analyzes 3-second audio windows
- **Multi-bird display** — Multiple species each get their own detection card
- **Per-bird logging** — Tap "Log This" on any card to save a sighting
- **5-second debounce** — Cards stay visible briefly after audio fades
- **Sighting history** — Timestamped log with photo, confidence %, swipe-to-delete
- **JSON export** — Export full history via iOS share sheet
- **~85 Midwest species** — American Robin, Northern Cardinal, Sandhill Crane, Bald Eagle, and more

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift |
| UI | SwiftUI |
| Persistence | SwiftData |
| Audio capture | AVAudioEngine |
| ML inference | CoreML (Create ML Sound Classifier) |
| API fallback | BirdNET-Analyzer REST server |
| Minimum target | iOS 16 |

---

## Project Structure

```
Bird Song/
├── Models/
│   └── BirdCatalog.swift         # 85 Midwest species, catalog lookup helpers
├── Views/
│   ├── RootTabView.swift          # Tab bar: Listen | History
│   ├── ListeningView.swift        # Mic button, waveform, detection cards
│   ├── HistoryView.swift          # Logged sightings list
│   └── BirdDetailView.swift       # Full sighting detail sheet
├── ViewModels/
│   ├── AudioSessionManager.swift  # AVAudioEngine 48 kHz mono capture
│   └── BirdClassifier.swift       # Three-mode inference: mock / api / coreML
├── Services/
│   ├── BirdNETAPIService.swift    # HTTP client for BirdNET-Analyzer server
│   └── ExportService.swift        # JSON export
├── Utilities/
│   └── DateFormatter+Ext.swift    # Date display helpers
├── Item.swift                     # BirdSighting SwiftData model
├── Bird_SongApp.swift             # App entry point
└── Info.plist                     # Microphone + location usage descriptions

scripts/
├── download_bird_photos.py        # Download bird photos → Assets.xcassets
├── download_training_audio.py     # Download xeno-canto audio for Create ML
├── convert_birdnet_to_coreml.py   # TFLite → CoreML conversion (reference)
└── run_conversion.py              # Alternate TFLite → CoreML via tf2onnx
```

---

## Next Steps

### Priority 1 — On-Device ML with Create ML ⭐ (recommended)

This gives the app real bird identification with no server, no internet required.

**1. Get a free xeno-canto API key**
- Register at [xeno-canto.org](https://xeno-canto.org) (free)
- Copy your API key from [xeno-canto.org/explore/api](https://xeno-canto.org/explore/api)
- Paste it into `scripts/download_training_audio.py` line 142:
  ```python
  XC_API_KEY = "your_key_here"
  ```

**2. Download training audio (~30-60 min, ~1.5 GB)**
```bash
python3 scripts/download_training_audio.py
```
Downloads 20 × 3-second WAV clips per species into `scripts/training_audio/<CommonName>/`.

**3. Train in Create ML (~30-60 min)**
1. In Xcode: **Open Developer Tool → Create ML**
2. New Document → **Sound Classifier**
3. Drag `scripts/training_audio/` into **Training Data**
4. Set iterations to **25**, augmentations on
5. Click **Train**
6. When complete → **Output tab → Export** → save as `BirdSoundClassifier.mlmodel`

**4. Add model to Xcode**
- Drag `BirdSoundClassifier.mlmodel` into the Xcode project (add to Bird Song target)
- In `Bird Song/ViewModels/BirdClassifier.swift` line 48, change:
  ```swift
  private static let inferenceMode: InferenceMode = .api
  // → change to:
  private static let inferenceMode: InferenceMode = .coreML
  ```
- Update the CoreML output key in `BirdClassifier.swift` to match the Sound Classifier output (label `classLabel`, probabilities `classProbability`)

---

### Priority 2 — Complete Bird Photos

About 40-45 of 85 species still need photos in the asset catalog.

```bash
python3 scripts/download_bird_photos.py
```

Photos are downloaded from Wikimedia Commons and saved to `Assets.xcassets`. Re-running skips already-downloaded species. Some may need manual lookup if the filename has changed on Commons.

---

### Priority 3 — Location-Aware Detection

Location context dramatically improves BirdNET accuracy (filters species not expected in your area).

1. Import `CoreLocation` and add `CLLocationManager` to `AudioSessionManager.swift`
2. Pass `latitude`/`longitude` to `BirdNETAPIService.analyze(buffer:latitude:longitude:)` — the parameter is already wired
3. For the Create ML path, location filtering would be a post-processing step against a species range dataset

---

### Priority 4 — App Polish

- **App icon** — A proper icon is needed; placeholder exists in `Assets.xcassets`
- **Onboarding screen** — First-launch explanation of microphone use and how to hold the phone
- **Settings tab** — Confidence threshold slider, server URL input, inference mode picker
- **Waveform animation** — Animate the audio level meter in `ListeningView` using actual buffer RMS
- **Haptic feedback** — Trigger on new detection (`UIImpactFeedbackGenerator`)

---

### Priority 5 — App Store Preparation

- [ ] Set bundle ID and team in Xcode signing settings
- [ ] Finalize app icon (all required sizes)
- [ ] Write App Store description and screenshots
- [ ] Enable App Store Connect record
- [ ] Submit for TestFlight beta testing
- [ ] Address any App Review guidelines (microphone usage justification)

---

## Inference Mode Reference

Change `inferenceMode` in `BirdClassifier.swift` to switch between modes:

| Mode | Description | Requires |
|------|-------------|----------|
| `.mock` | Random birds, no audio analysis | Nothing |
| `.api` | BirdNET-Analyzer server over Wi-Fi | Mac running `python3 -m birdnet_analyzer.server` on same network |
| `.coreML` | On-device Create ML model | `BirdSoundClassifier.mlmodel` in Xcode bundle |

### Running the API server (Mac)
```bash
pip install birdnet bottle
python3 -m birdnet_analyzer.server --host 0.0.0.0 --port 8080
```
Then set `BirdNETAPIService.serverURL` to your Mac's local IP (find it with `ipconfig getifaddr en0`).

---

## License

MIT
