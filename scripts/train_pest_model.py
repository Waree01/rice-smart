"""
Train a YOLOv5s rice-pest detector and export to TFLite (INT8).

This wraps the Ultralytics YOLOv5 training loop — we don't reimplement
training here because YOLOv5's `train.py` is the canonical entrypoint.

Usage:
    # 1. Install deps:
    #      pip install ultralytics onnx onnx-tf tensorflow==2.15
    # 2. Prepare a YOLO-format dataset (see docs/DATASETS.md):
    #      datasets/pest/
    #        images/{train,val}/*.jpg
    #        labels/{train,val}/*.txt   # one box per line: class cx cy w h
    #      datasets/pest/data.yaml      # classes: ['brown_planthopper', ...]
    # 3. Train:
    #      python scripts/train_pest_model.py --data datasets/pest/data.yaml
    # 4. The script then exports best.pt → ONNX → TFLite INT8
    #    into assets/models/pest_yolov5s.tflite.

Produces:
    assets/models/pest_yolov5s.tflite
    assets/models/pest_labels.txt
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def run(cmd: list[str]) -> None:
    print(" ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--data", required=True, help="Path to YOLO data.yaml")
    p.add_argument("--img", type=int, default=640)
    p.add_argument("--epochs", type=int, default=50)
    p.add_argument("--batch", type=int, default=16)
    p.add_argument("--output", default="assets/models")
    args = p.parse_args()

    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)

    # 1) Train
    run([
        sys.executable, "-m", "ultralytics",
        "detect", "train",
        f"data={args.data}",
        "model=yolov5s.pt",
        f"imgsz={args.img}",
        f"epochs={args.epochs}",
        f"batch={args.batch}",
        "project=runs/train",
        "name=rice_pest",
    ])

    best = Path("runs/train/rice_pest/weights/best.pt")
    if not best.exists():
        raise SystemExit(f"Training didn't produce {best}")

    # 2) Export to TFLite INT8
    run([
        sys.executable, "-m", "ultralytics",
        "export",
        f"model={best}",
        "format=tflite",
        "int8=True",
        f"imgsz={args.img}",
    ])

    exported = best.with_suffix(".tflite")
    # Ultralytics tucks the export next to `best.pt`; copy it where the
    # Flutter app expects.
    target = out_dir / "pest_yolov5s.tflite"
    target.write_bytes(exported.read_bytes())
    print(f"Wrote {target} ({target.stat().st_size/1e6:.2f} MB)")

    # 3) Copy class list (from data.yaml) into labels file
    import yaml  # lazy import, only needed here
    data = yaml.safe_load(Path(args.data).read_text())
    labels = data.get("names", [])
    (out_dir / "pest_labels.txt").write_text("\n".join(labels))
    print(f"Wrote {out_dir / 'pest_labels.txt'} ({len(labels)} classes)")


if __name__ == "__main__":
    main()
