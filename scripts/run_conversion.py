#!/usr/bin/env python3
"""
run_conversion.py
Converts the extracted BirdNET V2.4 audio-model.tflite directly to CoreML.
Run from the Bird Song project root:
    python3 scripts/run_conversion.py
"""

import os, sys, json, shutil, warnings
warnings.filterwarnings("ignore")
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

SCRIPT_DIR    = os.path.dirname(os.path.abspath(__file__))
TFLITE_PATH   = os.path.join(SCRIPT_DIR, "birdnet_model", "audio-model.tflite")
LABELS_PATH   = os.path.join(SCRIPT_DIR, "birdnet_model", "labels", "en_us.txt")
OUTPUT_DIR    = os.path.join(SCRIPT_DIR, "..", "Bird Song")
OUTPUT_MODEL  = os.path.join(OUTPUT_DIR, "BirdNET.mlpackage")
OUTPUT_LABELS = os.path.join(OUTPUT_DIR, "BirdNET_Labels.json")
TMP_SAVED     = os.path.join(SCRIPT_DIR, "_tmp_savedmodel")

def load_labels():
    """Load en_us labels — one 'CommonName_ScientificName' per line."""
    with open(LABELS_PATH) as f:
        return [l.strip() for l in f if l.strip()]

def main():
    print("=== BirdNET V2.4 → CoreML Conversion ===\n")

    for path in [TFLITE_PATH, LABELS_PATH]:
        if not os.path.exists(path):
            print(f"ERROR: Missing {path}"); sys.exit(1)

    import numpy as np
    import tensorflow as tf
    import coremltools as ct

    labels = load_labels()
    print(f"Labels loaded: {len(labels)} species")

    # ── 1. Inspect TFLite input/output shapes ────────────────────────
    print("\nInspecting TFLite model...")
    interp = tf.lite.Interpreter(model_path=TFLITE_PATH)
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    print(f"  Input  name={inp['name']}  shape={inp['shape']}  dtype={inp['dtype']}")
    print(f"  Output name={out['name']}  shape={out['shape']}  dtype={out['dtype']}")
    input_shape = list(inp["shape"])

    # ── 2. TFLite → ONNX via tf2onnx ────────────────────────────────
    import subprocess, sys as _sys
    ONNX_PATH = os.path.join(SCRIPT_DIR, "_birdnet_audio.onnx")
    print("\nConverting TFLite → ONNX via tf2onnx...")
    result = subprocess.run([
        _sys.executable, "-m", "tf2onnx.convert",
        "--tflite", TFLITE_PATH,
        "--output", ONNX_PATH,
        "--opset", "17",
    ], capture_output=True, text=True)
    if result.returncode != 0:
        print("tf2onnx stderr:", result.stderr[-2000:])
        sys.exit(1)
    print(f"  ONNX saved to {ONNX_PATH}")

    # ── 3. ONNX → CoreML via coremltools ────────────────────────────
    print("\nConverting ONNX → CoreML (this may take a minute)...")
    mlmodel = ct.convert(
        ONNX_PATH,
        convert_to="mlprogram",
        inputs=[ct.TensorType(
            name="input",
            shape=ct.Shape(shape=input_shape),
            dtype=np.float32
        )],
        minimum_deployment_target=ct.target.iOS16,
        compute_units=ct.ComputeUnit.ALL,
    )

    # ── 4. Annotate metadata ─────────────────────────────────────────
    mlmodel.short_description = "BirdNET V2.4 audio classifier (6522 species)"
    mlmodel.input_description["input"] = (
        f"Raw audio PCM float32, shape {input_shape}. "
        "3 seconds at 48 kHz, normalized to [-1, 1]."
    )

    # ── 5. Save ──────────────────────────────────────────────────────
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    mlmodel.save(OUTPUT_MODEL)
    print(f"\n✓ Saved model: {OUTPUT_MODEL}")

    # ── 6. Export labels as JSON ─────────────────────────────────────
    with open(OUTPUT_LABELS, "w") as f:
        json.dump(labels, f, indent=2)
    print(f"✓ Saved labels: {OUTPUT_LABELS} ({len(labels)} species)")

    # ── 7. Print output feature names (needed to update BirdClassifier) ──
    spec = mlmodel.get_spec()
    output_names = [o.name for o in spec.description.output]
    print(f"\nModel output feature names: {output_names}")
    print("→ Update BirdClassifier.swift featureValue(for:) to match the first output name.")

    print("\n=== DONE ===")
    print("Next steps:")
    print("1. In Xcode: drag 'Bird Song/BirdNET.mlpackage' into the Bird Song target")
    print("2. Also add 'Bird Song/BirdNET_Labels.json' to Copy Bundle Resources")
    print("3. In BirdClassifier.swift: set USE_REAL_MODEL = true")
    print("4. Update featureValue(for:) key to match the output name printed above")

if __name__ == "__main__":
    main()
