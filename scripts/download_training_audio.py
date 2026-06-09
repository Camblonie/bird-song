#!/usr/bin/env python3
"""
download_training_audio.py
Bird Song iOS App — Download xeno-canto audio for Create ML Sound Classifier training.

Downloads up to MAX_PER_SPECIES recordings per species from xeno-canto (CC-licensed),
converts each to a 3-second mono 22050 Hz WAV clip, and organises them into:
    training_audio/
        American Robin/
            xc123456.wav
            xc123457.wav
            ...
        Northern Cardinal/
            ...

This folder can be dragged directly into Create ML's Sound Classifier trainer.

Requirements: Python 3.9+, macOS (uses built-in afconvert)
Usage:
    python3 scripts/download_training_audio.py
"""

import os
import sys
import json
import time
import struct
import subprocess
import urllib.request
import urllib.parse
import urllib.error

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MAX_PER_SPECIES = 20          # recordings per species (more = better accuracy)
MIN_QUALITY     = "A"         # xeno-canto quality: A=best, B=good, C=ok
CLIP_SECONDS    = 3.0         # Create ML needs consistent clip length
SAMPLE_RATE     = 22050       # Hz — Create ML Sound Classifier default
DELAY_BETWEEN   = 0.5         # seconds between API requests (polite rate limiting)

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR   = os.path.join(SCRIPT_DIR, "training_audio")

# All 85 Midwest species — (common name, scientific name)
# Common name becomes the folder name and the class label in Create ML
SPECIES = [
    ("American Robin",           "Turdus migratorius"),
    ("Northern Cardinal",        "Cardinalis cardinalis"),
    ("Red-winged Blackbird",     "Agelaius phoeniceus"),
    ("Song Sparrow",             "Melospiza melodia"),
    ("House Finch",              "Haemorhous mexicanus"),
    ("American Goldfinch",       "Spinus tristis"),
    ("Black-capped Chickadee",   "Poecile atricapillus"),
    ("Tufted Titmouse",          "Baeolophus bicolor"),
    ("White-breasted Nuthatch",  "Sitta carolinensis"),
    ("Downy Woodpecker",         "Dryobates pubescens"),
    ("Hairy Woodpecker",         "Dryobates villosus"),
    ("Red-bellied Woodpecker",   "Melanerpes carolinus"),
    ("Pileated Woodpecker",      "Dryocopus pileatus"),
    ("Blue Jay",                 "Cyanocitta cristata"),
    ("American Crow",            "Corvus brachyrhynchos"),
    ("Common Grackle",           "Quiscalus quiscula"),
    ("European Starling",        "Sturnus vulgaris"),
    ("House Sparrow",            "Passer domesticus"),
    ("Mourning Dove",            "Zenaida macroura"),
    ("Rock Pigeon",              "Columba livia"),
    ("Barn Swallow",             "Hirundo rustica"),
    ("Tree Swallow",             "Tachycineta bicolor"),
    ("Chimney Swift",            "Chaetura pelagica"),
    ("Ruby-throated Hummingbird","Archilochus colubris"),
    ("Eastern Bluebird",         "Sialia sialis"),
    ("American Tree Sparrow",    "Spizelloides arborea"),
    ("Dark-eyed Junco",          "Junco hyemalis"),
    ("White-throated Sparrow",   "Zonotrichia albicollis"),
    ("Chipping Sparrow",         "Spizella passerina"),
    ("Field Sparrow",            "Spizella pusilla"),
    ("Eastern Towhee",           "Pipilo erythrophthalmus"),
    ("Common Yellowthroat",      "Geothlypis trichas"),
    ("Yellow Warbler",           "Setophaga petechia"),
    ("American Redstart",        "Setophaga ruticilla"),
    ("Ovenbird",                 "Seiurus aurocapilla"),
    ("Red-eyed Vireo",           "Vireo olivaceus"),
    ("Warbling Vireo",           "Vireo gilvus"),
    ("Eastern Phoebe",           "Sayornis phoebe"),
    ("Eastern Wood-Pewee",       "Contopus virens"),
    ("Great Crested Flycatcher", "Myiarchus crinitus"),
    ("Eastern Kingbird",         "Tyrannus tyrannus"),
    ("House Wren",               "Troglodytes aedon"),
    ("Carolina Wren",            "Thryothorus ludovicianus"),
    ("Marsh Wren",               "Cistothorus palustris"),
    ("Cedar Waxwing",            "Bombycilla cedrorum"),
    ("Baltimore Oriole",         "Icterus galbula"),
    ("Orchard Oriole",           "Icterus spurius"),
    ("Rose-breasted Grosbeak",   "Pheucticus ludovicianus"),
    ("Indigo Bunting",           "Passerina cyanea"),
    ("Bobolink",                 "Dolichonyx oryzivorus"),
    ("Eastern Meadowlark",       "Sturnella magna"),
    ("Brown-headed Cowbird",     "Molothrus ater"),
    ("Killdeer",                 "Charadrius vociferus"),
    ("American Woodcock",        "Scolopax minor"),
    ("Sandhill Crane",           "Antigone canadensis"),
    ("Great Blue Heron",         "Ardea herodias"),
    ("Great Egret",              "Ardea alba"),
    ("Canada Goose",             "Branta canadensis"),
    ("Mallard",                  "Anas platyrhynchos"),
    ("Wood Duck",                "Aix sponsa"),
    ("Red-tailed Hawk",          "Buteo jamaicensis"),
    ("Cooper's Hawk",            "Accipiter cooperii"),
    ("Sharp-shinned Hawk",       "Accipiter striatus"),
    ("Osprey",                   "Pandion haliaetus"),
    ("Bald Eagle",               "Haliaeetus leucocephalus"),
    ("Eastern Screech-Owl",      "Megascops asio"),
    ("Great Horned Owl",         "Bubo virginianus"),
    ("Barred Owl",               "Strix varia"),
    ("Belted Kingfisher",        "Megaceryle alcyon"),
    ("Yellow-billed Cuckoo",     "Coccyzus americanus"),
    ("Whip-poor-will",           "Antrostomus vociferus"),
    ("Common Nighthawk",         "Chordeiles minor"),
    ("Purple Martin",            "Progne subis"),
    ("Cliff Swallow",            "Petrochelidon pyrrhonota"),
    ("Dickcissel",               "Spiza americana"),
    ("Yellow-headed Blackbird",  "Xanthocephalus xanthocephalus"),
    ("American Bittern",         "Botaurus lentiginosus"),
    ("Common Loon",              "Gavia immer"),
    ("Pied-billed Grebe",        "Podilymbus podiceps"),
    ("American Coot",            "Fulica americana"),
    ("Sora",                     "Porzana carolina"),
    ("Virginia Rail",            "Rallus limicola"),
    ("Trumpeter Swan",           "Cygnus buccinator"),
    ("Northern Harrier",         "Circus hudsonius"),
    ("American Kestrel",         "Falco sparverius"),
]

# ---------------------------------------------------------------------------
# xeno-canto API v3 helpers
# ---------------------------------------------------------------------------

# Get a free API key at: https://xeno-canto.org/explore/api
# (requires free account registration, takes ~2 minutes)
XC_API_KEY = ""   # ← paste your key here, e.g. "abc123def456"

XC_API_V3  = "https://xeno-canto.org/api/2/recordings"   # fallback path
XC_API_URL = "https://xeno-canto.org/api/2/recordings"

def xc_search(scientific_name: str, quality: str) -> list:
    """Query xeno-canto API v3 for recordings of a species."""
    if not XC_API_KEY:
        print("  ERROR: XC_API_KEY not set.")
        print("  Get a free key at https://xeno-canto.org/explore/api")
        print("  Then paste it into XC_API_KEY at the top of this script.")
        sys.exit(1)

    query = f'"{scientific_name}" q:{quality} type:song'
    params = urllib.parse.urlencode({
        "query": query,
        "page": 1,
        "key": XC_API_KEY,
    })
    url = f"https://xeno-canto.org/api/2/recordings?{params}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "BirdSongApp/1.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())
            return data.get("recordings", [])
    except Exception as e:
        print(f"    xeno-canto API error: {e}")
        return []

def download_mp3(url: str, dest_path: str) -> bool:
    """Download an MP3 file from xeno-canto."""
    # xeno-canto file URLs may be protocol-relative (//xeno-canto.org/...)
    if url.startswith("//"):
        url = "https:" + url
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "BirdSongApp/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            with open(dest_path, "wb") as f:
                f.write(resp.read())
        return True
    except Exception as e:
        print(f"    Download error: {e}")
        return False

# ---------------------------------------------------------------------------
# Audio conversion helpers (macOS afconvert + built-in WAV trimmer)
# ---------------------------------------------------------------------------

def mp3_to_wav(mp3_path: str, wav_path: str) -> bool:
    """Convert MP3 → WAV using macOS built-in afconvert (no ffmpeg needed)."""
    try:
        result = subprocess.run(
            ["afconvert", "-f", "WAVE", "-d", "LEI16@22050", "-c", "1",
             mp3_path, wav_path],
            capture_output=True, timeout=30
        )
        return result.returncode == 0 and os.path.exists(wav_path)
    except Exception as e:
        print(f"    afconvert error: {e}")
        return False

def read_wav_header(path: str):
    """Read WAV header and return (sample_rate, num_channels, num_frames, data_offset)."""
    with open(path, "rb") as f:
        riff = f.read(4)
        if riff != b"RIFF":
            return None
        f.read(4)  # chunk size
        wave = f.read(4)
        if wave != b"WAVE":
            return None
        # Walk chunks to find fmt and data
        sample_rate = channels = bits = data_offset = data_size = None
        while True:
            chunk_id = f.read(4)
            if len(chunk_id) < 4:
                break
            chunk_size = struct.unpack("<I", f.read(4))[0]
            if chunk_id == b"fmt ":
                fmt_data = f.read(chunk_size)
                audio_fmt, channels, sample_rate = struct.unpack_from("<HHI", fmt_data, 0)
                bits = struct.unpack_from("<H", fmt_data, 14)[0]
            elif chunk_id == b"data":
                data_offset = f.tell()
                data_size   = chunk_size
                break
            else:
                f.seek(chunk_size, 1)
    if None in (sample_rate, channels, bits, data_offset, data_size):
        return None
    bytes_per_frame = channels * (bits // 8)
    num_frames = data_size // bytes_per_frame
    return sample_rate, channels, num_frames, data_offset, bits

def trim_wav_to_clip(src_path: str, dst_path: str, clip_seconds: float = 3.0) -> bool:
    """
    Trim or pad a WAV to exactly clip_seconds starting from the middle of the file.
    This avoids silence at the start/end of many xeno-canto recordings.
    """
    info = read_wav_header(src_path)
    if info is None:
        return False
    sample_rate, channels, num_frames, data_offset, bits = info
    target_frames = int(clip_seconds * sample_rate)
    bytes_per_frame = channels * (bits // 8)
    target_bytes = target_frames * bytes_per_frame

    # Start from the middle of the recording for the best chance of song content
    if num_frames > target_frames:
        start_frame = (num_frames - target_frames) // 2
    else:
        start_frame = 0

    with open(src_path, "rb") as f:
        f.seek(data_offset + start_frame * bytes_per_frame)
        audio_bytes = f.read(target_bytes)

    # Pad with silence if recording is shorter than clip length
    if len(audio_bytes) < target_bytes:
        audio_bytes += b"\x00" * (target_bytes - len(audio_bytes))

    # Write new WAV
    data_size  = len(audio_bytes)
    chunk_size = 36 + data_size
    byte_rate  = sample_rate * channels * (bits // 8)
    block_align = channels * (bits // 8)
    with open(dst_path, "wb") as f:
        f.write(b"RIFF")
        f.write(struct.pack("<I", chunk_size))
        f.write(b"WAVE")
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))
        f.write(struct.pack("<HHIIHH", 1, channels, sample_rate,
                            byte_rate, block_align, bits))
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        f.write(audio_bytes)
    return True

# ---------------------------------------------------------------------------
# Main download loop
# ---------------------------------------------------------------------------

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    tmp_mp3 = os.path.join(SCRIPT_DIR, "_tmp_bird.mp3")
    tmp_wav = os.path.join(SCRIPT_DIR, "_tmp_bird.wav")

    total_ok = 0
    total_species = len(SPECIES)

    print(f"Downloading training audio for {total_species} species")
    print(f"Output: {OUTPUT_DIR}\n")

    for sp_idx, (common_name, sci_name) in enumerate(SPECIES, 1):
        species_dir = os.path.join(OUTPUT_DIR, common_name)
        os.makedirs(species_dir, exist_ok=True)

        # Count already-downloaded clips for this species
        existing = [f for f in os.listdir(species_dir) if f.endswith(".wav")]
        if len(existing) >= MAX_PER_SPECIES:
            print(f"[{sp_idx:2}/{total_species}] {common_name} — already has {len(existing)} clips, skipping")
            total_ok += len(existing)
            continue

        print(f"[{sp_idx:2}/{total_species}] {common_name} ({sci_name})")

        # Try quality A first, fall back to B
        recordings = xc_search(sci_name, "A")
        if len(recordings) < 5:
            recordings += xc_search(sci_name, "B")
        time.sleep(DELAY_BETWEEN)

        if not recordings:
            print(f"  ✗ No recordings found on xeno-canto")
            continue

        downloaded = len(existing)
        needed     = MAX_PER_SPECIES - downloaded

        for rec in recordings[:needed + 5]:   # fetch a few extra in case some fail
            if downloaded >= MAX_PER_SPECIES:
                break

            xc_id   = rec.get("id", "unknown")
            file_url = rec.get("file", "")
            if not file_url:
                continue

            out_path = os.path.join(species_dir, f"xc{xc_id}.wav")
            if os.path.exists(out_path):
                downloaded += 1
                continue

            # Download MP3
            if not download_mp3(file_url, tmp_mp3):
                continue

            # Convert to WAV (22050 Hz mono 16-bit)
            if not mp3_to_wav(tmp_mp3, tmp_wav):
                continue

            # Trim to 3-second clip centred in the recording
            if trim_wav_to_clip(tmp_wav, out_path, CLIP_SECONDS):
                downloaded += 1
                total_ok   += 1
                print(f"  ✓ xc{xc_id}")
            else:
                print(f"  ✗ xc{xc_id} (trim failed)")

            time.sleep(DELAY_BETWEEN)

        # Clean up temp files
        for p in [tmp_mp3, tmp_wav]:
            if os.path.exists(p):
                os.remove(p)

        print(f"  → {downloaded}/{MAX_PER_SPECIES} clips")

    print(f"\n=== Done: {total_ok} total clips across {total_species} species ===")
    print(f"Training data at: {OUTPUT_DIR}")
    print("\nNext steps:")
    print("1. Open Create ML.app (Xcode menu → Open Developer Tool → Create ML)")
    print("2. New Document → Sound Classifier")
    print("3. Drag the 'training_audio' folder into the Training Data section")
    print("4. Click Train (takes ~30-60 min)")
    print("5. Export the model as BirdSoundClassifier.mlmodel")
    print("6. Drag it into Xcode and set inferenceMode = .coreML in BirdClassifier.swift")

if __name__ == "__main__":
    main()
