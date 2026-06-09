#!/usr/bin/env python3
"""
convert_birdnet_to_coreml.py
Bird Song iOS App — BirdNET TFLite → CoreML converter

Converts the BirdNET-Analyzer V2.4 TFLite model to a CoreML .mlpackage
ready to drop into Xcode.

Requirements:
    pip install tensorflow coremltools numpy

Steps:
    1. Download BirdNET-Analyzer from https://github.com/birdnet-team/BirdNET-Analyzer
    2. Copy the model file to this scripts/ folder:
           BirdNET_GLOBAL_6K_V2.4_Model_FP32.tflite
       (found in BirdNET-Analyzer/checkpoints/V2.4/)
    3. Copy the labels file to this scripts/ folder:
           BirdNET_GLOBAL_6K_V2.4_Labels.txt
       (found in BirdNET-Analyzer/checkpoints/V2.4/)
    4. Run: python3 convert_birdnet_to_coreml.py
    5. Drag the output BirdNET.mlpackage into your Xcode project (add to Bird Song target)
    6. Set USE_REAL_MODEL = true in BirdClassifier.swift

BirdNET V2.4 model specs:
    - Input: two-channel mel spectrogram, shape [1, 2, 96, 511]
      Channel 0: fmin=0 Hz,   fmax=3000 Hz
      Channel 1: fmin=500 Hz, fmax=15000 Hz
    - nfft: 1024, hop_size: 280, mel_bins: 96
    - Audio: 3 seconds at 48000 Hz, normalized to [-1, 1]
    - Output: logits over ~6522 species classes
"""

import os
import sys
import json
import numpy as np

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
TFLITE_PATH  = os.path.join(SCRIPT_DIR, "BirdNET_GLOBAL_6K_V2.4_Model_FP32.tflite")
LABELS_PATH  = os.path.join(SCRIPT_DIR, "BirdNET_GLOBAL_6K_V2.4_Labels.txt")
OUTPUT_MODEL = os.path.join(SCRIPT_DIR, "..", "Bird Song", "BirdNET.mlpackage")
OUTPUT_LABELS = os.path.join(SCRIPT_DIR, "..", "Bird Song", "BirdNET_Labels.json")

# ---------------------------------------------------------------------------
# Validate inputs
# ---------------------------------------------------------------------------

def check_files():
    missing = []
    if not os.path.exists(TFLITE_PATH):
        missing.append(f"  {TFLITE_PATH}")
    if not os.path.exists(LABELS_PATH):
        missing.append(f"  {LABELS_PATH}")
    if missing:
        print("ERROR: Missing required files:\n" + "\n".join(missing))
        print("\nDownload BirdNET-Analyzer from:")
        print("  https://github.com/birdnet-team/BirdNET-Analyzer")
        print("Then copy the files listed above into scripts/ and re-run.")
        sys.exit(1)

# ---------------------------------------------------------------------------
# Load labels
# ---------------------------------------------------------------------------

def load_labels() -> list[str]:
    """Load species labels from BirdNET label file (one per line: 'Common Name_Scientific Name')."""
    with open(LABELS_PATH, "r") as f:
        labels = [line.strip() for line in f if line.strip()]
    print(f"Loaded {len(labels)} species labels.")
    return labels

# ---------------------------------------------------------------------------
# Convert TFLite → CoreML via SavedModel intermediate
# ---------------------------------------------------------------------------

def convert():
    check_files()

    try:
        import tensorflow as tf
        import coremltools as ct
    except ImportError as e:
        print(f"Missing dependency: {e}")
        print("Run: pip install tensorflow coremltools")
        sys.exit(1)

    labels = load_labels()

    # ---- Step 1: Load TFLite and wrap as TF SavedModel ----
    print("Loading TFLite model...")
    interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
    interpreter.allocate_tensors()

    input_details  = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"  Input shape:  {input_details[0]['shape']}")
    print(f"  Output shape: {output_details[0]['shape']}")

    # ---- Step 2: Build a concrete TF function around the interpreter ----
    # This is needed because coremltools converts TF SavedModels, not TFLite
    print("Wrapping interpreter as TF function...")

    input_shape = input_details[0]["shape"]   # e.g. [1, 2, 96, 511]

    @tf.function(input_signature=[tf.TensorSpec(shape=input_shape, dtype=tf.float32)])
    def inference_fn(x):
        """Run one TFLite inference step and return logits."""
        interpreter.set_tensor(input_details[0]["index"], x)
        interpreter.invoke()
        return interpreter.get_tensor(output_details[0]["index"])

    # Save as a concrete SavedModel
    saved_model_dir = os.path.join(SCRIPT_DIR, "_birdnet_savedmodel_tmp")
    tf.saved_model.save(
        obj=tf.Module(),
        export_dir=saved_model_dir,
        signatures={"serving_default": inference_fn.get_concrete_function()}
    )
    print(f"  Saved intermediate model to {saved_model_dir}")

    # ---- Step 3: Convert SavedModel → CoreML ----
    print("Converting to CoreML...")
    mlmodel = ct.convert(
        saved_model_dir,
        convert_to="mlprogram",
        inputs=[ct.TensorType(
            name="input",
            shape=ct.Shape(shape=input_shape),
            dtype=np.float32
        )],
        classifier_config=ct.ClassifierConfig(labels),
        minimum_deployment_target=ct.target.iOS16,
        compute_units=ct.ComputeUnit.ALL,
    )

    # ---- Step 4: Set human-readable metadata ----
    mlmodel.short_description = "BirdNET V2.4 — Bird sound identification"
    mlmodel.input_description["input"] = (
        "Two-channel mel spectrogram [1, 2, 96, 511]. "
        "Channel 0: 0–3 kHz, Channel 1: 0.5–15 kHz. "
        "Audio: 3 sec @ 48 kHz, normalized to [-1, 1]."
    )
    mlmodel.output_description["classLabel"]       = "Top predicted species label"
    mlmodel.output_description["classLabel_probs"] = "Probability for each of the ~6K species"

    # ---- Step 5: Save .mlpackage ----
    mlmodel.save(OUTPUT_MODEL)
    print(f"\n✓ Saved: {OUTPUT_MODEL}")

    # ---- Step 6: Export labels as JSON for BirdClassifier.swift ----
    with open(OUTPUT_LABELS, "w") as f:
        json.dump(labels, f, indent=2)
    print(f"✓ Saved: {OUTPUT_LABELS}")

    # ---- Cleanup temp SavedModel ----
    import shutil
    shutil.rmtree(saved_model_dir, ignore_errors=True)

    print("\n--- NEXT STEPS ---")
    print("1. In Xcode: drag BirdNET.mlpackage into the Bird Song target")
    print("2. Also add BirdNET_Labels.json to the target (copy bundle resources)")
    print("3. In BirdClassifier.swift: set USE_REAL_MODEL = true")
    print("4. Build and run on a real device (mic required)")


if __name__ == "__main__":
    convert()
