#!/usr/bin/env python3
"""
download_bird_photos.py
Bird Song iOS App — Wikimedia Commons photo downloader

Downloads one representative CC-licensed photo per Midwest bird species
and saves them as PNG files named to match the imageName values in BirdCatalog.swift.

Output folder: ../Bird Song/Assets.xcassets/  (one imageset per bird)

Usage:
    pip install requests Pillow
    python3 download_bird_photos.py

After running, drag the generated Assets.xcassets imagesets into Xcode
or simply replace the existing Assets.xcassets folder contents.
"""

import os
import time
import json
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from PIL import Image
from io import BytesIO

# ---------------------------------------------------------------------------
# Species list — (asset_name, wikimedia_page_title)
# Page titles are the exact Wikimedia Commons File: page for a good photo.
# ---------------------------------------------------------------------------
SPECIES = [
    # Filenames verified against Wikimedia Commons Special:FilePath
    ("bird_american_robin",          "Turdus-migratorius-002.jpg"),
    ("bird_northern_cardinal",       "Northern_Cardinal_male.jpg"),
    ("bird_red_winged_blackbird",    "Red-winged_Blackbird_(Agelaius_phoeniceus)_male.jpg"),
    ("bird_song_sparrow",            "Song_Sparrow_(Melospiza_melodia)_(2).jpg"),
    ("bird_house_finch",             "House_Finch_(Haemorhous_mexicanus)_(male).jpg"),
    ("bird_american_goldfinch",      "American_Goldfinch-27527-2.jpg"),
    ("bird_black_capped_chickadee",  "Black_Capped_Chickadee.jpg"),
    ("bird_tufted_titmouse",         "Tufted_Titmouse_Baeolophus_bicolor.jpg"),
    ("bird_white_breasted_nuthatch", "Sitta-carolinensis-001.jpg"),
    ("bird_downy_woodpecker",        "Downy_Woodpecker.jpg"),
    ("bird_hairy_woodpecker",        "Hairy_Woodpecker.jpg"),
    ("bird_red_bellied_woodpecker",  "Red-bellied_Woodpecker_Melanerpes_carolinus.jpg"),
    ("bird_pileated_woodpecker",     "Pileated_woodpecker.jpg"),
    ("bird_blue_jay",                "Cyanocitta-cristata-004.jpg"),
    ("bird_american_crow",           "American_Crow.jpg"),
    ("bird_common_grackle",          "Common_Grackle_(Quiscalus_quiscula).jpg"),
    ("bird_european_starling",       "European_Starling.jpg"),
    ("bird_house_sparrow",           "Passer_domesticus_male_(15).jpg"),
    ("bird_mourning_dove",           "Mourning_Dove_2006.jpg"),
    ("bird_rock_pigeon",             "Rock_Pigeon_(Columba_livia)_(3).jpg"),
    ("bird_barn_swallow",            "Hirundo_rustica_-_Barn_Swallow.jpg"),
    ("bird_tree_swallow",            "Tree_Swallow_(Tachycineta_bicolor).jpg"),
    ("bird_chimney_swift",           "Chaetura_pelagica.jpg"),
    ("bird_ruby_throated_hummingbird","Ruby-throated_Hummingbird_(Archilochus_colubris).jpg"),
    ("bird_eastern_bluebird",        "Eastern_Bluebird_(Sialia_sialis)_male.jpg"),
    ("bird_american_tree_sparrow",   "American_Tree_Sparrow_(Spizelloides_arborea).jpg"),
    ("bird_dark_eyed_junco",         "Dark-eyed_Junco_RWD2013.jpg"),
    ("bird_white_throated_sparrow",  "White-throated_Sparrow_(Zonotrichia_albicollis).jpg"),
    ("bird_chipping_sparrow",        "Chipping_Sparrow.jpg"),
    ("bird_field_sparrow",           "Field_Sparrow_(Spizella_pusilla).jpg"),
    ("bird_eastern_towhee",          "Eastern_Towhee.jpg"),
    ("bird_common_yellowthroat",     "Common_Yellowthroat.jpg"),
    ("bird_yellow_warbler",          "Yellow_warbler.jpg"),
    ("bird_american_redstart",       "American_Redstart_(Setophaga_ruticilla)_male.jpg"),
    ("bird_ovenbird",                "Ovenbird_(Seiurus_aurocapilla).jpg"),
    ("bird_red_eyed_vireo",          "Red-eyed_Vireo.jpg"),
    ("bird_warbling_vireo",          "Warbling_Vireo_(Vireo_gilvus).jpg"),
    ("bird_eastern_phoebe",          "Eastern_Phoebe_(Sayornis_phoebe).jpg"),
    ("bird_eastern_wood_pewee",      "Eastern_Wood-Pewee.jpg"),
    ("bird_great_crested_flycatcher","Great_Crested_Flycatcher_(Myiarchus_crinitus).jpg"),
    ("bird_eastern_kingbird",        "Eastern_Kingbird_(Tyrannus_tyrannus).jpg"),
    ("bird_house_wren",              "House_Wren_(Troglodytes_aedon).jpg"),
    ("bird_carolina_wren",           "Thryothorus_ludovicianus_-_Carolina_Wren.jpg"),
    ("bird_marsh_wren",              "Cistothorus_palustris_Marsh_Wren.jpg"),
    ("bird_cedar_waxwing",           "Cedar_Waxwing.jpg"),
    ("bird_baltimore_oriole",        "Baltimore_oriole_RWD2013b.jpg"),
    ("bird_orchard_oriole",          "Orchard_Oriole_(Icterus_spurius)_male.jpg"),
    ("bird_rose_breasted_grosbeak",  "Rose-breasted_Grosbeak_(Pheucticus_ludovicianus)_male.jpg"),
    ("bird_indigo_bunting",          "Indigo_bunting_-_male.jpg"),
    ("bird_bobolink",                "Bobolink_(Dolichonyx_oryzivorus)_male.jpg"),
    ("bird_eastern_meadowlark",      "Eastern_Meadowlark.jpg"),
    ("bird_brown_headed_cowbird",    "Brown-headed_Cowbird.jpg"),
    ("bird_killdeer",                "Killdeer_with_eggs.jpg"),
    ("bird_american_woodcock",       "American_woodcock.jpg"),
    ("bird_sandhill_crane",          "Sandhill_crane.jpg"),
    ("bird_great_blue_heron",        "Great_blue_heron_-_Ardea_herodias.jpg"),
    ("bird_great_egret",             "Great_Egret_(Ardea_alba).jpg"),
    ("bird_canada_goose",            "Canada_goose_on_Seedskadee_NWR.jpg"),
    ("bird_mallard",                 "Mallard2.jpg"),
    ("bird_wood_duck",               "Wood_Duck.jpg"),
    ("bird_red_tailed_hawk",         "Red-tailed_hawk.jpg"),
    ("bird_coopers_hawk",            "Accipiter_cooperii_-_Cooper%27s_hawk.jpg"),
    ("bird_sharp_shinned_hawk",      "Sharp-shinned_Hawk.jpg"),
    ("bird_osprey",                  "Osprey_-_natures_pics.jpg"),
    ("bird_bald_eagle",              "Bald_Eagle_Portrait.jpg"),
    ("bird_eastern_screech_owl",     "Eastern_Screech_Owl.jpg"),
    ("bird_great_horned_owl",        "Great_horned_owl.jpg"),
    ("bird_barred_owl",              "Barred_Owl_(Strix_varia).jpg"),
    ("bird_belted_kingfisher",       "Belted_Kingfisher_(Megaceryle_alcyon).jpg"),
    ("bird_yellow_billed_cuckoo",    "Yellow-billed_cuckoo.jpg"),
    ("bird_whip_poor_will",          "Whip-poor-will.jpg"),
    ("bird_common_nighthawk",        "Common_Nighthawk_(Chordeiles_minor).jpg"),
    ("bird_purple_martin",           "Purple_martin.jpg"),
    ("bird_cliff_swallow",           "Cliff_Swallow_(Petrochelidon_pyrrhonota).jpg"),
    ("bird_dickcissel",              "Dickcissel_(Spiza_americana).jpg"),
    ("bird_yellow_headed_blackbird", "Yellow-headed_Blackbird.jpg"),
    ("bird_american_bittern",        "American_Bittern.jpg"),
    ("bird_common_loon",             "Common_loon.jpg"),
    ("bird_pied_billed_grebe",       "Pied-billed_Grebe.jpg"),
    ("bird_american_coot",           "American_Coot.jpg"),
    ("bird_sora",                    "Sora_(Porzana_carolina).jpg"),
    ("bird_virginia_rail",           "Virginia_Rail.jpg"),
    ("bird_trumpeter_swan",          "Trumpeter_Swan.jpg"),
    ("bird_northern_harrier",        "Northern_Harrier.jpg"),
    ("bird_american_kestrel",        "American_kestrel.jpg"),
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

TARGET_SIZE   = (600, 600)   # square thumbnails for the app
OUTPUT_DIR    = os.path.join(os.path.dirname(__file__), "..", "Bird Song", "Assets.xcassets")

HEADERS = {"User-Agent": "BirdSongApp/1.0 (iOS bird identification; educational use)"}

# Session with automatic retry
_session = requests.Session()
_adapter = HTTPAdapter(max_retries=Retry(total=3, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504], raise_on_status=False))
_session.mount("https://", _adapter)


def download_and_save(asset_name: str, filename: str) -> bool:
    """Download image via Wikimedia Special:FilePath (no API key needed), resize, write xcassets imageset."""
    # Special:FilePath redirects directly to the file — no JSON API call required
    url = f"https://commons.wikimedia.org/wiki/Special:FilePath/{requests.utils.quote(filename)}?width=800"

    try:
        r = _session.get(url, headers=HEADERS, timeout=30, allow_redirects=True)
        r.raise_for_status()
        img = Image.open(BytesIO(r.content)).convert("RGB")

        # Crop to square (centre crop)
        w, h = img.size
        side = min(w, h)
        left = (w - side) // 2
        top  = (h - side) // 2
        img  = img.crop((left, top, left + side, top + side))
        img  = img.resize(TARGET_SIZE, Image.LANCZOS)

        # Create xcassets imageset folder
        imageset_dir = os.path.join(OUTPUT_DIR, f"{asset_name}.imageset")
        os.makedirs(imageset_dir, exist_ok=True)

        # Save the image
        img_path = os.path.join(imageset_dir, f"{asset_name}.png")
        img.save(img_path, "PNG", optimize=True)

        # Write Contents.json required by Xcode
        contents = {
            "images": [
                {"idiom": "universal", "filename": f"{asset_name}.png", "scale": "1x"},
                {"idiom": "universal", "scale": "2x"},
                {"idiom": "universal", "scale": "3x"},
            ],
            "info": {"author": "xcode", "version": 1},
        }
        with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)

        print(f"  ✓ {asset_name}")
        return True

    except Exception as e:
        print(f"  ✗ {asset_name}: {e}")
        return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print(f"Downloading {len(SPECIES)} bird photos to:\n  {os.path.abspath(OUTPUT_DIR)}\n")
    success = 0
    failed  = []

    for asset_name, filename in SPECIES:
        # Skip if already downloaded
        imageset_dir = os.path.join(OUTPUT_DIR, f"{asset_name}.imageset")
        img_path = os.path.join(imageset_dir, f"{asset_name}.png")
        if os.path.exists(img_path):
            print(f"  - {asset_name} (already downloaded, skipping)")
            success += 1
            continue

        result = download_and_save(asset_name, filename)
        if result:
            success += 1
        else:
            failed.append(asset_name)
        time.sleep(1.0)   # be polite to Wikimedia servers

    print(f"\nDone: {success}/{len(SPECIES)} downloaded.")
    if failed:
        print("\nFailed (add placeholders or retry):")
        for f in failed:
            print(f"  - {f}")
    else:
        print("All photos downloaded successfully!")

    print("\nNext step: Open Xcode → Assets.xcassets. The imagesets are already in place.")


if __name__ == "__main__":
    main()
