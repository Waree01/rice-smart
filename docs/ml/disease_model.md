# Disease Detection Model Card

## Decisions log

| Decision | Choice | Rationale |
|---|---|---|
| Dataset source | Mendeley fwcj7stb8r/1 (Hasan et al., 2019), CC BY 4.0 | Only public 5-class dataset incl. sheath_blight + bacterial_leaf_blight + healthy. |
| Leaf Blast + Neck Blast | Collapsed into `rice_blast` | Keeps the app at 5 classes (CLAUDE.md scope). Revisit if Neck Blast diagnostics become a thesis goal. |
| Attribution placement | Root README + in-app About screen | Belt-and-braces CC BY 4.0 compliance. In-app screen tracked in #37. |
| Training authority | `ml/disease_model/train.py` | Single source-of-truth pipeline. |

---

## Current state

**Model file not yet generated.**
Run `ml/disease_model/train.py` to produce it.
See `ml/disease_model/README.md` for full setup instructions.

```
assets/models/rice_disease.tflite   — MISSING (run train.py to generate)
assets/models/disease_labels.txt    — PRESENT (5 classes, correct order)
```

---

## Provenance

| Field | Value |
|-------|-------|
| Training script | `ml/disease_model/train.py` |
| Primary dataset | Mendeley "Rice Diseases Image Dataset" — Hasan et al. (2019) |
| Primary dataset URL | https://data.mendeley.com/datasets/fwcj7stb8r/1 |
| Primary dataset DOI | 10.17632/fwcj7stb8r.1 |
| Primary dataset license | **CC BY 4.0** (permissive; attribution required in app credits — see #37) |
| Primary dataset classes | Bacterial Leaf Blight, Brown Spot, Leaf Blast, Neck Blast, Sheath Blight, Healthy |
| Blast collapse | `Leaf Blast` + `Neck Blast` → `rice_blast` (via `CLASS_ALIASES` in train.py) |
| Fallback dataset (reference only) | `Subh775/Rice-Disease-Classification-Dataset` (HuggingFace, Apache-2.0, 4 classes — **fails 5-class gate**) |
| Architecture | EfficientNet-B0, ImageNet transfer learning |
| Input shape | 224 × 224 × 3 uint8 |
| Output | float32 softmax `[1, 5]` |
| Quantization | INT8 with representative-dataset calibration |
| Target size | < 15 MB |
| Target accuracy | >= 80% test accuracy |

---

## Output class ordering

| Index | App class ID |
|-------|-------------|
| 0 | `rice_blast` |
| 1 | `brown_spot` |
| 2 | `bacterial_leaf_blight` |
| 3 | `sheath_blight` |
| 4 | `healthy` |

`disease_labels.txt` encodes this mapping. The inference service reads it at runtime.

---

## Phase 1 research summary (2026-05-31)

Six off-the-shelf TFLite / H5 / SafeTensors candidates were evaluated and all rejected:
missing sheath_blight, wrong format, no TFLite export, or non-permissive license.
Full evaluation table is preserved in this file's git history.

**Decision:** train from scratch using the Mendeley dataset + EfficientNet-B0.

---

## For the #31 implementer

### Input / output contract

- **Input tensor**: shape `[1, 224, 224, 3]`, dtype `uint8` (values 0–255).
  Feed raw pixel bytes directly — **do not divide by 255**. The INT8 model
  handles dequantization internally (`inference_input_type = tf.uint8` in the converter).
  Verify at runtime: `interpreter.getInputTensor(0).quantizationParams`.

- **Output tensor**: shape `[1, 5]`, dtype `float32` (softmax probabilities).
  No manual dequantization needed (`inference_output_type = tf.float32`).
  Verify: `interpreter.getOutputTensor(0).type`.

- **Class index**: `argmax` over the 5 output values → index into `disease_labels.txt`.
  Never hard-code indices in Dart — always load the labels file at runtime.

- **Label order**: matches `CLASSES` in `train.py` and `assets/models/disease_labels.txt`
  (rice_blast=0, brown_spot=1, bacterial_leaf_blight=2, sheath_blight=3, healthy=4).

---

## Replacement procedure

1. Replace `assets/models/rice_disease.tflite`.
2. If class order changes, update `assets/models/disease_labels.txt`.
3. Bump `"version"` in `ml/disease_model/training_report.json`.
4. Re-run smoke test described in #31.
5. Verify `flutter analyze` passes.
6. Open a new PR — do not amend previous merge commits.
