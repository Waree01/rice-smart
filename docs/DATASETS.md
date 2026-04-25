# Datasets

The on-device ML models shipped with RiceSmart are currently mocks.
Before the thesis defence they need to be swapped for real TFLite
weights. This doc lists the dataset sources and layouts expected by the
training scripts in `scripts/`.

## Rice disease classification (EfficientNet-B0)

### Layout

```
datasets/rice_disease/
├── rice_blast/*.jpg
├── brown_spot/*.jpg
├── bacterial_leaf_blight/*.jpg
├── sheath_blight/*.jpg
└── healthy/*.jpg
```

Folder names MUST match the `id` field in `assets/knowledge_base/diseases.json`.

### Sources

| Source | URL | Notes |
| ------ | --- | ----- |
| Rice Leaf Diseases (Kaggle) | https://www.kaggle.com/datasets/vbookshelf/rice-leaf-diseases | 5,932 images, 3 classes — good starting set |
| Rice Diseases Image Dataset | https://www.kaggle.com/datasets/minhhuy2810/rice-diseases-image-dataset | 3,355 images, 4 classes |
| Plant Village (rice subset) | https://www.kaggle.com/datasets/emmarex/plantdisease | Large tree of crop diseases; filter for rice |
| RiceLeafs GitHub | https://github.com/aldrin233/RiceDiseases-DataSet | ~400 images per class, Thai-friendly lighting |
| Author-collected | Field photos from Sukhothai / Phichit provinces | Captured with app prototype |

### Training

```bash
pip install tensorflow==2.15 pillow numpy scikit-learn
python scripts/train_disease_model.py \
    --data datasets/rice_disease \
    --output assets/models
```

Expected wall-clock on an M-series Mac: ~20 minutes for 5k images at 15 epochs.

### Validation targets (thesis)

- Per-class precision / recall
- Confusion matrix (use `sklearn.metrics.confusion_matrix`)
- Top-1 accuracy ≥ 85% on held-out 20%
- Model size ≤ 20 MB after TFLite conversion

---

## Rice pest detection (YOLOv5s INT8)

### Layout

Standard YOLO format:

```
datasets/pest/
├── images/
│   ├── train/*.jpg
│   └── val/*.jpg
├── labels/
│   ├── train/*.txt       # one object per line: class cx cy w h (normalized)
│   └── val/*.txt
└── data.yaml
```

`data.yaml`:

```yaml
path: datasets/pest
train: images/train
val: images/val
names:
  - brown_planthopper
  - rice_stem_borer
  - rice_leaffolder
  - rice_bug
  - golden_apple_snail
```

### Sources

| Source | URL | Notes |
| ------ | --- | ----- |
| IP102 Pest Dataset | https://github.com/xpwu95/IP102 | 75k images, 102 pest classes — filter to rice subset |
| Rice Pest IP102 subset | curated from IP102; see `scripts/filter_ip102.py` | Not included; derive with IP102 class mapping |
| IRRI Pest Gallery | http://www.knowledgebank.irri.org/ | Photo reference for manual labeling |
| Author-collected | Field photos + labelme annotations | 200+ images per class |

### Training

```bash
pip install ultralytics onnx onnx-tf tensorflow==2.15 pyyaml
python scripts/train_pest_model.py --data datasets/pest/data.yaml
```

Expected wall-clock on an M-series Mac with MPS: ~45 minutes for 50 epochs on a 2k-image set.

### Validation targets (thesis)

- mAP@0.5 ≥ 0.70
- Per-class AP matrix
- Model size ≤ 7 MB after INT8 quantization
- Frame latency ≤ 120 ms on a mid-range Android phone

---

## Swapping mocks for real models

After running the training scripts above, the `.tflite` files land in
`assets/models/`. Then in the Flutter app:

1. In `lib/features/disease_detection/services/disease_inference_service.dart`,
   replace the body of `_runModel` with a real `Interpreter.fromAsset(...)`
   call. The code comment in that file lists the exact preprocessing
   (resize to 224×224, EfficientNet preprocess).
2. Same for `lib/features/pest_identification/services/pest_inference_service.dart` —
   use the YOLO post-processing path (letterbox → inference → NMS).
3. Ship the labels files:
   - `assets/models/disease_labels.txt`
   - `assets/models/pest_labels.txt`
4. Bump the app version in `pubspec.yaml` and update the README's
   "Current state" notes.

---

## LLM benchmark questions

The `assets/knowledge_base/benchmark_questions.json` file holds a 15-item
Thai agricultural Q&A set used by the in-app LLM Benchmark screen. Growing
this to 50–100 items will strengthen the thesis's comparative results.
Each question should include:

- `id` — short stable id (`q16`, `q17`, ...)
- `category` — disease / pest / fertilizer / water / seed / weather / cost / harvest / soil
- `question` — free-text Thai
- `expected_keywords` — 3–6 discriminating terms the "good" answer should mention

Human evaluation (rate answers 1-5 for *accuracy*, *fluency*, *actionability*)
can be layered on top of the keyword-coverage score already computed.
