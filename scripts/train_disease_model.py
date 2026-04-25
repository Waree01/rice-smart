"""
Train an EfficientNet-B0 rice-disease classifier and export to TFLite.

Usage:
    # 1. Prepare a dataset folder (see docs/DATASETS.md for layout + sources)
    #    datasets/rice_disease/{rice_blast,brown_spot,...,healthy}/*.jpg
    # 2. Install deps:
    #      pip install tensorflow==2.15 pillow numpy scikit-learn
    # 3. Run:
    #      python scripts/train_disease_model.py \\
    #          --data datasets/rice_disease \\
    #          --output assets/models
    # 4. Flutter will pick up the exported rice_disease.tflite at next build.

Produces:
    assets/models/rice_disease.tflite
    assets/models/disease_labels.txt

Notes:
    - Swap `EfficientNetB0` for `MobileNetV3Small` if you need a tinier
      model (~5 MB) at the cost of ~2-3 percentage points of accuracy.
    - The labels file is read by `disease_inference_service.dart` — keep
      the order consistent with the training class indices.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path

import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

IMG_SIZE = (224, 224)
BATCH = 32
EPOCHS = 15
SEED = 42


def build_model(num_classes: int) -> tf.keras.Model:
    base = tf.keras.applications.EfficientNetB0(
        include_top=False,
        weights="imagenet",
        input_shape=(*IMG_SIZE, 3),
        pooling="avg",
    )
    base.trainable = False  # freeze backbone for phase 1

    inputs = tf.keras.Input(shape=(*IMG_SIZE, 3))
    x = tf.keras.applications.efficientnet.preprocess_input(inputs)
    x = base(x, training=False)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax")(x)
    model = tf.keras.Model(inputs, outputs)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


def load_dataset(data_dir: Path):
    classes = sorted([d.name for d in data_dir.iterdir() if d.is_dir()])
    labels, files = [], []
    for idx, cls in enumerate(classes):
        for p in (data_dir / cls).glob("*.*"):
            if p.suffix.lower() in {".jpg", ".jpeg", ".png"}:
                files.append(str(p))
                labels.append(idx)
    files = np.array(files)
    labels = np.array(labels)
    train_f, val_f, train_l, val_l = train_test_split(
        files, labels, test_size=0.2, stratify=labels, random_state=SEED
    )

    def make(ds_files, ds_labels, shuffle: bool):
        ds = tf.data.Dataset.from_tensor_slices((ds_files, ds_labels))
        if shuffle:
            ds = ds.shuffle(1024, seed=SEED)

        def _decode(path, label):
            img = tf.io.read_file(path)
            img = tf.image.decode_jpeg(img, channels=3)
            img = tf.image.resize(img, IMG_SIZE)
            return img, label

        ds = ds.map(_decode, num_parallel_calls=tf.data.AUTOTUNE)
        ds = ds.batch(BATCH).prefetch(tf.data.AUTOTUNE)
        return ds

    return classes, make(train_f, train_l, True), make(val_f, val_l, False)


def fine_tune(model: tf.keras.Model, train_ds, val_ds) -> tf.keras.Model:
    # Unfreeze the last few layers for phase 2.
    model.layers[2].trainable = True
    for layer in model.layers[2].layers[:-30]:
        layer.trainable = False
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-4),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(train_ds, validation_data=val_ds, epochs=5)
    return model


def export_tflite(model: tf.keras.Model, out_path: Path) -> None:
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_bytes = converter.convert()
    out_path.write_bytes(tflite_bytes)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--data", required=True)
    p.add_argument("--output", default="assets/models")
    args = p.parse_args()

    data_dir = Path(args.data)
    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)

    classes, train_ds, val_ds = load_dataset(data_dir)
    print(f"Classes: {classes}")

    model = build_model(num_classes=len(classes))
    print("Phase 1 — feature extraction")
    model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS)
    print("Phase 2 — fine-tuning")
    model = fine_tune(model, train_ds, val_ds)

    tflite_path = out_dir / "rice_disease.tflite"
    export_tflite(model, tflite_path)
    labels_path = out_dir / "disease_labels.txt"
    labels_path.write_text("\n".join(classes))
    print(f"Wrote {tflite_path} ({tflite_path.stat().st_size/1e6:.2f} MB)")
    print(f"Wrote {labels_path}")


if __name__ == "__main__":
    main()
