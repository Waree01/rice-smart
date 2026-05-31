"""
train.py — RiceSmart disease model training pipeline.

Run as a plain script:
    python train.py

Or open in VS Code / Colab — the # %% markers split it into cells.

Output:
    assets/models/rice_disease.tflite
    assets/models/disease_labels.txt
    ml/disease_model/training_report.json

Dataset (canonical source)
--------------------------
Mendeley "Rice Diseases Image Dataset" — Hasan et al. (2019)
License  : CC BY 4.0  (attribution required; see ml/disease_model/README.md)
URL      : https://data.mendeley.com/datasets/fwcj7stb8r/1
Citation : Hasan, Md. Jahid; Mahbub, Shahin; Alom, Md. Shamim; Nasim, Md. Abdul (2019),
           "Rice Disease Image Dataset", Mendeley Data, V1,
           doi: 10.17632/fwcj7stb8r.1

Download the zip, unzip to ml/disease_model/data/mendeley_rice_disease/, then run:
    python train.py
(USE_LOCAL_DATA defaults to True; no HuggingFace auth required.)
"""

# %% Phase 0 — Imports + config
import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# ---------------------------------------------------------------------------
# Constants — change these before re-running if needed
# ---------------------------------------------------------------------------
IMG_SIZE = 224
CLASSES = [
    "rice_blast",
    "brown_spot",
    "bacterial_leaf_blight",
    "sheath_blight",
    "healthy",
]
BATCH_SIZE = 32
EPOCHS_STAGE1 = 10   # head-only training
EPOCHS_STAGE2 = 20   # fine-tune last 30 base layers
LEARNING_RATE_STAGE1 = 1e-3
LEARNING_RATE_STAGE2 = 1e-5
REPRESENTATIVE_SAMPLES = 200  # samples used for INT8 calibration

# ---------------------------------------------------------------------------
# Dataset class names → our canonical 5-class IDs.
# Multiple source names can map to the same canonical class
# (e.g., Mendeley splits blast into Leaf Blast and Neck Blast;
# we collapse both into rice_blast to keep the app at 5 classes).
# Keys are normalised (lowercase, spaces/hyphens → underscores) before lookup.
# ---------------------------------------------------------------------------
CLASS_ALIASES: dict[str, str] = {
    "leaf_blast":            "rice_blast",
    "neck_blast":            "rice_blast",
    "blast":                 "rice_blast",
    "rice_blast":            "rice_blast",
    "bacterial_blight":      "bacterial_leaf_blight",
    "bacterial_leaf_blight": "bacterial_leaf_blight",
    "brown_spot":            "brown_spot",
    "sheath_blight":         "sheath_blight",
    "healthy":               "healthy",
}

# ---------------------------------------------------------------------------
# Primary dataset (Mendeley, CC BY 4.0) — covers all 5 classes.
# Download from https://data.mendeley.com/datasets/fwcj7stb8r/1
# Unzip into:  ml/disease_model/data/mendeley_rice_disease/
# Structure:   data/mendeley_rice_disease/<class_folder>/<image_files>
# ---------------------------------------------------------------------------
USE_LOCAL_DATA = os.environ.get("USE_LOCAL_DATA", "true").lower() == "true"
LOCAL_DATA_DIR = Path(os.environ.get("LOCAL_DATA_DIR", "./data/mendeley_rice_disease"))

# ---------------------------------------------------------------------------
# Fallback: HuggingFace Subh775 (Apache-2.0) — 4 classes only; kept for
# reference. Phase 1 will abort if any of our 5 required classes is missing.
# To use: set USE_LOCAL_DATA=false (or export USE_LOCAL_DATA=false before run)
# ---------------------------------------------------------------------------
# DATASET_NAME = "Subh775/Rice-Disease-Classification-Dataset"
DATASET_NAME = "Subh775/Rice-Disease-Classification-Dataset"  # fallback reference only

FALLBACK_DATASET_HINT = (
    "Mendeley 'Rice Diseases Image Dataset' (CC BY 4.0): "
    "https://data.mendeley.com/datasets/fwcj7stb8r/1  "
    "Download the zip, unzip to ml/disease_model/data/mendeley_rice_disease/, "
    "then run: python train.py  (USE_LOCAL_DATA defaults to true)."
)

# Output goes to assets/models/ (two levels up from this script)
OUTPUT_DIR = Path(__file__).resolve().parent.parent.parent / "assets" / "models"
REPORT_PATH = Path(__file__).resolve().parent / "training_report.json"

MIN_TEST_ACCURACY = 0.80        # abort threshold after Keras evaluation
MAX_TFLITE_BYTES = 15 * 1024 * 1024   # 15 MB hard limit
MAX_QUANTIZATION_DROP = 0.02    # allow up to 2 pp accuracy drop after INT8

print("=" * 60)
print("RiceSmart Disease Model — Training Pipeline")
print("=" * 60)
print(f"Target classes : {CLASSES}")
print(f"IMG_SIZE       : {IMG_SIZE}x{IMG_SIZE}")
print(f"BATCH_SIZE     : {BATCH_SIZE}")
print(f"Output dir     : {OUTPUT_DIR}")
print()


# %% Phase 1 — Load + verify dataset
def _normalize(name: str) -> str:
    """Lowercase, strip, spaces/hyphens → underscores."""
    return name.strip().lower().replace(" ", "_").replace("-", "_")


def _canonical(raw_name: str) -> str | None:
    """
    Convert a raw dataset class name to our canonical class ID via CLASS_ALIASES.
    Returns None if the class is out of scope (not an error — it will be dropped).
    """
    return CLASS_ALIASES.get(_normalize(raw_name))


def _check_class_coverage(dataset_classes: list[str]) -> dict[str, list[str]]:
    """
    Map each of our CLASSES to the list of raw dataset class names that alias to it.
    Uses CLASS_ALIASES so that e.g. 'Leaf Blast' and 'Neck Blast' both map to
    'rice_blast'.  Dataset class names that resolve to None are out-of-scope and
    will be silently dropped during Phase 2.
    Aborts loudly if any canonical class has zero dataset sources.
    Returns {canonical_class: [raw_dataset_class, ...]}.
    """
    # Build canonical → [raw names] mapping
    canonical_to_raws: dict[str, list[str]] = {c: [] for c in CLASSES}
    out_of_scope: list[str] = []
    for raw in dataset_classes:
        canon = _canonical(raw)
        if canon is None:
            out_of_scope.append(raw)
        elif canon in canonical_to_raws:
            canonical_to_raws[canon].append(raw)

    print("\n### Dataset class mapping (via CLASS_ALIASES)")
    print(f"{'Canonical class':<30} {'Dataset source(s)'}")
    print("-" * 72)
    missing: list[str] = []
    for our_class in CLASSES:
        raws = canonical_to_raws[our_class]
        if raws:
            print(f"{our_class:<30} {', '.join(raws)}")
        else:
            print(f"{our_class:<30} *** MISSING ***")
            missing.append(our_class)

    if out_of_scope:
        print(f"\n  Out-of-scope (will be dropped): {out_of_scope}")

    if missing:
        print()
        print("=" * 60)
        print("ABORT: The following required classes are MISSING from the dataset:")
        for m in missing:
            print(f"  - {m}")
        print()
        print(f"Dataset only covers {len(dataset_classes)} classes:")
        for i, c in enumerate(dataset_classes):
            print(f"  [{i}] {c}")
        print()
        print("RESOLUTION:")
        print(f"  {FALLBACK_DATASET_HINT}")
        print("=" * 60)
        sys.exit(1)

    return canonical_to_raws


if USE_LOCAL_DATA:
    print(f"Mode: LOCAL DATA (Mendeley) from {LOCAL_DATA_DIR}")

    if not LOCAL_DATA_DIR.exists():
        print(f"ERROR: LOCAL_DATA_DIR '{LOCAL_DATA_DIR}' does not exist.")
        print(f"  {FALLBACK_DATASET_HINT}")
        sys.exit(1)

    # Discover subdirectories as classes
    found_dirs = sorted([d.name for d in LOCAL_DATA_DIR.iterdir() if d.is_dir()])
    print(f"Found class directories: {found_dirs}")

    # canonical_to_raws: {our_class: [raw_dir_names that alias to it]}
    canonical_to_raws = _check_class_coverage(found_dirs)

    # Build a list of (path, label_index) from local files.
    # Multiple raw directories (e.g., "Leaf Blast" + "Neck Blast") may map to
    # the same canonical class ("rice_blast") — we merge their images.
    import random
    all_samples: list[tuple[Path, int]] = []
    dropped_count = 0
    for our_class, raw_dirs in canonical_to_raws.items():
        label_idx = CLASSES.index(our_class)
        class_images: list[Path] = []
        for raw_dir in raw_dirs:
            class_dir = LOCAL_DATA_DIR / raw_dir
            imgs = (
                list(class_dir.glob("*.jpg"))
                + list(class_dir.glob("*.jpeg"))
                + list(class_dir.glob("*.png"))
            )
            class_images.extend(imgs)
        for img_path in class_images:
            all_samples.append((img_path, label_idx))
        src_label = f"{raw_dirs}" if len(raw_dirs) > 1 else raw_dirs[0]
        print(f"  {our_class:<35} {len(class_images):>5} images  (from: {src_label})")

    # Count and report out-of-scope samples (directories not in CLASS_ALIASES)
    for d in found_dirs:
        if _canonical(d) is None:
            out_dir = LOCAL_DATA_DIR / d
            out_imgs = (
                list(out_dir.glob("*.jpg"))
                + list(out_dir.glob("*.jpeg"))
                + list(out_dir.glob("*.png"))
            )
            dropped_count += len(out_imgs)
    if dropped_count:
        print(f"  (dropped {dropped_count} images from out-of-scope directories)")

    random.shuffle(all_samples)
    hf_dataset = None  # not used in local mode

else:
    print(f"Mode: HuggingFace fallback — {DATASET_NAME}")
    print()
    print("NOTE: Subh775/Rice-Disease-Classification-Dataset has Apache-2.0 license")
    print("      but only 4 classes. Phase 1 will abort if any of our 5 required")
    print("      classes are missing. Consider switching to the Mendeley dataset.")
    print()

    try:
        from datasets import load_dataset
    except ImportError:
        print("ERROR: 'datasets' package not installed. Run: pip install -r requirements.txt")
        sys.exit(1)

    print(f"Loading '{DATASET_NAME}' from HuggingFace Hub …")
    hf_dataset = load_dataset(DATASET_NAME)

    print("\nDataset info:")
    print(f"  Splits: {list(hf_dataset.keys())}")
    first_split = list(hf_dataset.keys())[0]
    features = hf_dataset[first_split].features
    print(f"  Features: {features}")

    # Extract class names from the label feature
    label_feature = features.get("label") or features.get("labels")
    if label_feature is None or not hasattr(label_feature, "names"):
        print("ERROR: Cannot determine class names from dataset features.")
        print(f"  Features found: {features}")
        sys.exit(1)

    dataset_classes = label_feature.names
    print(f"  Dataset classes ({len(dataset_classes)}): {dataset_classes}")

    # canonical_to_raws: {our_class: [raw_hf_class_names]}
    canonical_to_raws = _check_class_coverage(dataset_classes)

    # Build hf_label_int → our CLASSES index (or None to drop)
    hf_label_to_our_idx: dict[int, int] = {}
    for our_class, raw_names in canonical_to_raws.items():
        our_idx = CLASSES.index(our_class)
        for raw in raw_names:
            hf_idx = dataset_classes.index(raw)
            hf_label_to_our_idx[hf_idx] = our_idx

    all_samples = None  # used only in local mode


# %% Phase 2 — Preprocess + split
import tensorflow as tf  # noqa: E402 — imported after dataset verification
from tensorflow.keras.applications.efficientnet import preprocess_input  # noqa: E402

print("\n### Phase 2 — Building tf.data.Dataset")

AUTOTUNE = tf.data.AUTOTUNE


def decode_pil_image(pil_img) -> np.ndarray:
    """Resize a PIL image to IMG_SIZE x IMG_SIZE, return float32 array [0,255]."""
    img = pil_img.convert("RGB").resize((IMG_SIZE, IMG_SIZE), Image.BILINEAR)
    return np.array(img, dtype=np.float32)


if USE_LOCAL_DATA:
    # Build dataset from local file paths
    paths = [str(s[0]) for s in all_samples]
    labels = [s[1] for s in all_samples]

    def load_local_image(path_tensor, label):
        path = path_tensor.numpy().decode("utf-8")
        img = Image.open(path)
        arr = decode_pil_image(img)
        arr = preprocess_input(arr)  # EfficientNet-style scaling
        return arr, label

    def tf_load_local(path, label):
        img, lbl = tf.py_function(
            load_local_image, [path, label], [tf.float32, tf.int32]
        )
        img.set_shape([IMG_SIZE, IMG_SIZE, 3])
        lbl.set_shape([])
        return img, lbl

    full_ds = (
        tf.data.Dataset.from_tensor_slices((paths, labels))
        .map(tf_load_local, num_parallel_calls=AUTOTUNE)
    )
    total = len(all_samples)
    n_train = int(total * 0.80)
    n_val = int(total * 0.10)
    n_test = total - n_train - n_val

    train_ds_raw = full_ds.take(n_train)
    val_ds_raw = full_ds.skip(n_train).take(n_val)
    test_ds_raw = full_ds.skip(n_train + n_val)

else:
    # HuggingFace dataset path — use hf_label_to_our_idx built in Phase 1
    def hf_row_to_tensor(example):
        ds_label = int(example["label"])
        if ds_label not in hf_label_to_our_idx:
            return None  # drop out-of-scope classes
        our_label = hf_label_to_our_idx[ds_label]
        img = decode_pil_image(example["image"])
        img = preprocess_input(img)
        return img, our_label

    def build_split_ds(split_name: str):
        split = hf_dataset[split_name]
        imgs, lbls = [], []
        for row in split:
            result = hf_row_to_tensor(row)
            if result is None:
                continue
            imgs.append(result[0])
            lbls.append(result[1])
        imgs_arr = np.array(imgs, dtype=np.float32)
        lbls_arr = np.array(lbls, dtype=np.int32)
        return tf.data.Dataset.from_tensor_slices((imgs_arr, lbls_arr))

    splits = list(hf_dataset.keys())
    if "train" in splits and "test" in splits:
        train_val_ds_raw = build_split_ds("train")
        test_ds_raw = build_split_ds("test")
        n_train_val = sum(1 for _ in train_val_ds_raw)
        n_val = int(n_train_val * 0.125)  # ~10% of total
        n_train = n_train_val - n_val
        train_ds_raw = train_val_ds_raw.take(n_train)
        val_ds_raw = train_val_ds_raw.skip(n_train)
        n_test = sum(1 for _ in test_ds_raw)
    elif "train" in splits and "validation" in splits:
        train_ds_raw = build_split_ds("train")
        val_ds_raw = build_split_ds("validation")
        test_ds_raw = build_split_ds("test") if "test" in splits else val_ds_raw
        n_train = sum(1 for _ in train_ds_raw)
        n_val = sum(1 for _ in val_ds_raw)
        n_test = sum(1 for _ in test_ds_raw)
    else:
        # Single split — do 80/10/10 manually
        full_ds_hf = build_split_ds(splits[0])
        total = sum(1 for _ in full_ds_hf)
        n_train = int(total * 0.80)
        n_val = int(total * 0.10)
        n_test = total - n_train - n_val
        full_ds_hf = full_ds_hf.shuffle(buffer_size=total, seed=42)
        train_ds_raw = full_ds_hf.take(n_train)
        val_ds_raw = full_ds_hf.skip(n_train).take(n_val)
        test_ds_raw = full_ds_hf.skip(n_train + n_val)

# Count per-class in each split and print summary
def count_classes(ds, name: str):
    counts = {c: 0 for c in CLASSES}
    for _, lbl in ds:
        counts[CLASSES[int(lbl)]] += 1
    total = sum(counts.values())
    print(f"\n  {name} split ({total} samples):")
    for c, n in counts.items():
        print(f"    {c:<35} {n:>5}")
    return total

print()
n_train_actual = count_classes(train_ds_raw, "Train")
n_val_actual = count_classes(val_ds_raw, "Val")
n_test_actual = count_classes(test_ds_raw, "Test")

# Build final batched datasets
def finalize_ds(ds, shuffle: bool = False):
    if shuffle:
        ds = ds.shuffle(buffer_size=1000, seed=42)
    return ds.batch(BATCH_SIZE).prefetch(AUTOTUNE)

train_ds = finalize_ds(train_ds_raw, shuffle=True)
val_ds = finalize_ds(val_ds_raw)
test_ds = finalize_ds(test_ds_raw)

# Keep an unbatched copy of train for representative dataset generation
train_ds_unbatched = train_ds_raw


# %% Phase 3 — Build model
print("\n### Phase 3 — Building EfficientNetB0 model")

from tensorflow.keras import layers, Model  # noqa: E402
from tensorflow.keras.applications import EfficientNetB0  # noqa: E402

# Augmentation layers (only active during training via `training=True`)
data_augmentation = tf.keras.Sequential(
    [
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.1),
        layers.RandomZoom(0.1),
    ],
    name="augmentation",
)

# Build functional model so augmentation is clearly in the graph
inputs = layers.Input(shape=(IMG_SIZE, IMG_SIZE, 3), name="input_image")
x = data_augmentation(inputs)

base_model = EfficientNetB0(
    weights="imagenet",
    include_top=False,
    input_shape=(IMG_SIZE, IMG_SIZE, 3),
)
base_model.trainable = False  # frozen for stage 1

x = base_model(x, training=False)
x = layers.GlobalAveragePooling2D(name="gap")(x)
x = layers.Dropout(0.2, name="dropout")(x)
outputs = layers.Dense(len(CLASSES), activation="softmax", name="predictions")(x)

model = Model(inputs, outputs, name="rice_disease_efficientnetb0")
model.summary(line_length=100)

print(f"\nBase model layers: {len(base_model.layers)}")
print(f"Total params: {model.count_params():,}")


# %% Phase 4 — Train (two stages)
print("\n### Phase 4 — Training")

early_stop = tf.keras.callbacks.EarlyStopping(
    monitor="val_accuracy", patience=5, restore_best_weights=True, verbose=1
)
reduce_lr = tf.keras.callbacks.ReduceLROnPlateau(
    monitor="val_loss", factor=0.5, patience=3, min_lr=1e-7, verbose=1
)
checkpoint_cb = tf.keras.callbacks.ModelCheckpoint(
    filepath="checkpoints/best_model.keras",
    monitor="val_accuracy",
    save_best_only=True,
    verbose=1,
)

os.makedirs("checkpoints", exist_ok=True)

# --- Stage 1: train head only ---
print("\n--- Stage 1: head-only training ---")
model.compile(
    optimizer=tf.keras.optimizers.Adam(LEARNING_RATE_STAGE1),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)
history1 = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS_STAGE1,
    callbacks=[early_stop, reduce_lr, checkpoint_cb],
    verbose=1,
)

# --- Stage 2: unfreeze last 30 base layers ---
print("\n--- Stage 2: fine-tuning last 30 base layers ---")
base_model.trainable = True
for layer in base_model.layers[:-30]:
    layer.trainable = False

trainable_count = sum(1 for l in base_model.layers if l.trainable)
print(f"Trainable base layers: {trainable_count} / {len(base_model.layers)}")

model.compile(
    optimizer=tf.keras.optimizers.Adam(LEARNING_RATE_STAGE2),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)
early_stop2 = tf.keras.callbacks.EarlyStopping(
    monitor="val_accuracy", patience=5, restore_best_weights=True, verbose=1
)
history2 = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS_STAGE2,
    callbacks=[early_stop2, reduce_lr, checkpoint_cb],
    verbose=1,
)

print("\nTraining complete.")


# %% Phase 5 — Evaluate
print("\n### Phase 5 — Evaluation on test set")

from sklearn.metrics import (  # noqa: E402
    classification_report,
    confusion_matrix,
)

test_loss, test_acc = model.evaluate(test_ds, verbose=1)
print(f"\nTest accuracy (Keras): {test_acc:.4f}")
print(f"Test loss    (Keras): {test_loss:.4f}")

# Collect predictions for per-class metrics
y_true, y_pred = [], []
for batch_imgs, batch_labels in test_ds:
    preds = model.predict(batch_imgs, verbose=0)
    y_pred.extend(np.argmax(preds, axis=1).tolist())
    y_true.extend(batch_labels.numpy().tolist())

print("\nPer-class metrics:")
report = classification_report(
    y_true, y_pred, target_names=CLASSES, output_dict=False
)
print(report)
report_dict = classification_report(
    y_true, y_pred, target_names=CLASSES, output_dict=True
)

cm = confusion_matrix(y_true, y_pred)
print("Confusion matrix (rows=true, cols=pred):")
print(f"Classes: {CLASSES}")
print(cm)

# Save metrics
training_report = {
    "version": "1.0.0",
    "dataset": DATASET_NAME if not USE_LOCAL_DATA else str(LOCAL_DATA_DIR),
    "architecture": "EfficientNetB0",
    "img_size": IMG_SIZE,
    "classes": CLASSES,
    "test_accuracy_keras": float(test_acc),
    "test_loss_keras": float(test_loss),
    "per_class_metrics": report_dict,
    "confusion_matrix": cm.tolist(),
    "train_samples": n_train_actual,
    "val_samples": n_val_actual,
    "test_samples": n_test_actual,
    "epochs_stage1": len(history1.history["loss"]),
    "epochs_stage2": len(history2.history["loss"]),
}
REPORT_PATH.write_text(json.dumps(training_report, indent=2))
print(f"\nSaved training report to {REPORT_PATH}")

if test_acc < MIN_TEST_ACCURACY:
    print()
    print("=" * 60)
    print(f"ABORT: Test accuracy {test_acc:.4f} is below minimum {MIN_TEST_ACCURACY:.2f}.")
    print("The model is not good enough to ship. Possible actions:")
    print("  - Increase EPOCHS_STAGE1 / EPOCHS_STAGE2")
    print("  - Use a larger or better-balanced dataset")
    print("  - Reduce Dropout or try EfficientNetB1/B2")
    print("=" * 60)
    sys.exit(1)


# %% Phase 6 — Convert to TFLite (INT8 quantized)
print("\n### Phase 6 — TFLite INT8 conversion")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
tflite_path = OUTPUT_DIR / "rice_disease.tflite"

# Representative dataset generator for INT8 calibration
def representative_dataset_gen():
    count = 0
    for img, _ in train_ds_unbatched:
        if count >= REPRESENTATIVE_SAMPLES:
            break
        # INT8 input expects uint8 [0, 255]; preprocess_input mapped to [-1,1]-ish range
        # We feed the float32 preprocessed tensor here — the converter handles quant params.
        img_batch = tf.expand_dims(img, axis=0)  # (1, 224, 224, 3)
        yield [img_batch]
        count += 1

print(f"Calibrating with {REPRESENTATIVE_SAMPLES} representative samples …")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset_gen
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.uint8     # mobile-friendly uint8 input
converter.inference_output_type = tf.float32  # keep softmax probs as float32

print("Converting …")
tflite_model = converter.convert()

tflite_path.write_bytes(tflite_model)
size_bytes = len(tflite_model)
size_mb = size_bytes / (1024 * 1024)
print(f"Saved: {tflite_path}  ({size_mb:.2f} MB, {size_bytes:,} bytes)")

if size_bytes > MAX_TFLITE_BYTES:
    print()
    print("=" * 60)
    print(f"ABORT: TFLite file size {size_mb:.2f} MB exceeds {MAX_TFLITE_BYTES/(1024*1024):.0f} MB limit.")
    print("Consider: pruning, weight clustering, or switching to EfficientNetB0-lite.")
    print("=" * 60)
    sys.exit(1)


# %% Phase 7 — Verify the .tflite
print("\n### Phase 7 — TFLite verification")

interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
print(f"TFLite input  : {input_details[0]['shape']}  dtype={input_details[0]['dtype']}")
print(f"TFLite output : {output_details[0]['shape']}  dtype={output_details[0]['dtype']}")

# Run test set through the interpreter
tflite_y_true, tflite_y_pred = [], []
for batch_imgs, batch_labels in test_ds:
    for img, label in zip(batch_imgs.numpy(), batch_labels.numpy()):
        # Convert float32 preprocessed image back to uint8 for INT8 model
        # EfficientNet preprocess_input maps [0,255] → roughly [-1, 1].
        # Reverse: add 1, divide by 2, multiply by 255, clip, cast.
        img_uint8 = np.clip(((img + 1.0) / 2.0 * 255.0), 0, 255).astype(np.uint8)
        img_input = np.expand_dims(img_uint8, axis=0)  # (1, 224, 224, 3)
        interpreter.set_tensor(input_details[0]["index"], img_input)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]["index"])[0]
        tflite_y_pred.append(int(np.argmax(output)))
        tflite_y_true.append(int(label))

tflite_acc = sum(p == t for p, t in zip(tflite_y_pred, tflite_y_true)) / len(tflite_y_true)
print(f"\nTFLite test accuracy : {tflite_acc:.4f}")
print(f"Keras  test accuracy : {test_acc:.4f}")
acc_drop = test_acc - tflite_acc
print(f"Accuracy drop (INT8) : {acc_drop:.4f}")

if acc_drop > MAX_QUANTIZATION_DROP:
    print()
    print("=" * 60)
    print(f"ABORT: INT8 quantization caused {acc_drop:.4f} accuracy drop (limit: {MAX_QUANTIZATION_DROP}).")
    print("Actions:")
    print("  - Increase REPRESENTATIVE_SAMPLES for better calibration")
    print("  - Try float16 quantization instead of full INT8")
    print("  - Use per-channel quantization (default for Conv2D in recent TF)")
    print("=" * 60)
    sys.exit(1)

# Update report with TFLite results
training_report["test_accuracy_tflite"] = float(tflite_acc)
training_report["tflite_size_mb"] = round(size_mb, 2)
training_report["tflite_size_bytes"] = size_bytes
training_report["accuracy_drop_int8"] = round(float(acc_drop), 4)
REPORT_PATH.write_text(json.dumps(training_report, indent=2))


# %% Phase 8 — Write labels.txt
print("\n### Phase 8 — Writing disease_labels.txt")

labels_path = OUTPUT_DIR / "disease_labels.txt"
labels_path.write_text("\n".join(CLASSES) + "\n")
print(f"Written: {labels_path}")
print("Contents:")
for i, c in enumerate(CLASSES):
    print(f"  [{i}] {c}")

# Final summary
print()
print("=" * 60)
print(f"  Model:  assets/models/rice_disease.tflite ({size_mb:.1f} MB)")
print(f"  Labels: assets/models/disease_labels.txt ({len(CLASSES)} classes)")
print(f"  Test accuracy: {test_acc:.4f} (Keras) / {tflite_acc:.4f} (TFLite)")
print()
print("Next steps:")
print("  git add assets/models/rice_disease.tflite \\")
print("          assets/models/disease_labels.txt \\")
print("          ml/disease_model/training_report.json")
print("  git commit -m 'feat(ml): add INT8 EfficientNetB0 rice disease TFLite model'")
print("  gh pr create  # closes #30")
print("=" * 60)
