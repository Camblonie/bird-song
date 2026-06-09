# Bird Song 🐦

An iOS 26 app that listens through the microphone and identifies bird calls in real time, focused on **US Midwest species**. When birds are detected the app shows a photo, common name, scientific name, and confidence score. Users can log individual sightings and review a full history.

---

## Features

- **Real-time identification** — Continuously analyzes 3-second audio windows via on-device ML (BirdNET CoreML)
- **Multi-bird display** — Multiple species detected at the same time each get their own card
- **Per-bird logging** — Tap "Log This" on any card to save that individual sighting
- **5-second debounce** — Cards stay visible briefly after audio fades
- **Sighting history** — Timestamped log with bird photo, confidence %, swipe-to-delete
- **JSON export** — Export your full history via the iOS share sheet (Files, AirDrop, email, etc.)
- **~80 Midwest species** — American Robin, Northern Cardinal, Sandhill Crane, Bald Eagle, and many more

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift |
| UI | SwiftUI |
| Persistence | SwiftData |
| Audio capture | AVAudioEngine |
| ML inference | CoreML + BirdNET (on-device) |
| Minimum target | iOS 26 |

---

## Project Structure

```
Bird Song/
├── Models/
│   └── BirdCatalog.swift        # ~80 Midwest species definitions
├── Views/
│   ├── RootTabView.swift        # Tab bar: Listen | History
│   ├── ListeningView.swift      # Mic button, waveform, multi-bird cards
│   ├── HistoryView.swift        # Logged sightings list
│   └── BirdDetailView.swift     # Full sighting detail sheet
├── ViewModels/
│   ├── AudioSessionManager.swift # AVAudioEngine mic capture
│   └── BirdClassifier.swift     # CoreML inference wrapper (mock ready)
├── Services/
│   └── ExportService.swift      # JSON export
├── Utilities/
│   └── DateFormatter+Ext.swift  # Date display helpers
├── Item.swift                   # BirdSighting SwiftData model
├── Bird_SongApp.swift           # App entry point
└── Info.plist                   # Microphone usage description
```

---

## Getting Started

### Prerequisites
- Xcode 26+
- iOS 26 simulator or physical device
- (For real ML) Python 3 + `coremltools` for BirdNET model conversion

### Build & Run (Mock Mode)
1. Clone the repository
2. Open `Bird Song.xcodeproj`
3. Add all files in `Models/`, `ViewModels/`, `Services/`, `Utilities/`, and `Views/` to the **Bird Song** target in Xcode
4. Build and run on simulator or device — the app runs with a **mock classifier** that cycles through species for UI development

### Enabling Real BirdNET Inference
1. Download [BirdNET-Analyzer](https://github.com/kahst/BirdNET-Analyzer) (Apache 2.0)
2. Convert the TFLite model to CoreML:
   ```bash
   pip install coremltools tensorflow
   # Run the conversion script (see docs/convert_birdnet.py — coming soon)
   ```
3. Add `BirdNET.mlmodel` to the Xcode project
4. Set `USE_REAL_MODEL = true` in `ViewModels/BirdClassifier.swift`

### Bird Photos
Add bird images to `Assets.xcassets` named `bird_<species_id>` (e.g. `bird_american_robin`).  
The app shows a placeholder feather icon until photos are added.

---

## Midwest Species Catalog (sample)

American Robin · Northern Cardinal · Red-winged Blackbird · Black-capped Chickadee · American Goldfinch · Baltimore Oriole · Sandhill Crane · Bald Eagle · Great Horned Owl · Barred Owl · Eastern Bluebird · Indigo Bunting · Rose-breasted Grosbeak · and ~65 more.

---

## License

MIT
