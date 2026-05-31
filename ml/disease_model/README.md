# RiceSmart Disease Model — Training Pipeline

## Purpose

This pipeline trains an EfficientNet-B0 model on rice disease images and exports
a quantized INT8 TFLite file ready for on-device inference in the RiceSmart Flutter app.
Outputs land at:

```
assets/models/rice_disease.tflite   — INT8 TFLite model (<15 MB hard limit)
assets/models/disease_labels.txt    — 5 class IDs in model output order
ml/disease_model/training_report.json — accuracy + confusion matrix
```

---

## Step 0 — Download the Mendeley dataset (required)

The canonical training dataset is:

> **Rice Diseases Image Dataset** — Hasan et al. (2019)
> License: **CC BY 4.0** (permissive; attribution required — see [Attribution](#attribution) below)
> URL: https://data.mendeley.com/datasets/fwcj7stb8r/1
> DOI: 10.17632/fwcj7stb8r.1

### How to download

1. Open https://data.mendeley.com/datasets/fwcj7stb8r/1
2. Click **Download** (no account required for CC BY datasets)
3. Save the zip file
4. Unzip into `ml/disease_model/data/mendeley_rice_disease/`

Expected folder structure after unzipping:

```
ml/disease_model/data/mendeley_rice_disease/
├── Bacterial Leaf Blight/
├── Brown Spot/
├── Leaf Blast/        ← collapsed into rice_blast by CLASS_ALIASES
├── Neck Blast/        ← collapsed into rice_blast by CLASS_ALIASES
├── Sheath Blight/
└── Healthy/
```

The training script normalises folder names (lowercase, spaces → underscores) and
applies `CLASS_ALIASES` so `Leaf Blast` and `Neck Blast` are both treated as
`rice_blast`. No manual renaming needed.

**No HuggingFace authentication required.** `USE_LOCAL_DATA` defaults to `true`.

---

## Quick Start (Google Colab — recommended)

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/your-org/rice-smart/blob/main/ml/disease_model/train.py)

> Replace `your-org` with the actual GitHub org/user before sharing the badge.

### Step-by-step on Colab

```python
# Cell 1 — clone the repo (use a personal access token for a private repo)
import os
TOKEN = "ghp_your_token_here"   # Settings → Developer settings → PAT (classic)
os.environ["GITHUB_TOKEN"] = TOKEN
!git clone https://{TOKEN}@github.com/nenoteerawat/rice-smart.git
%cd rice-smart
```

```python
# Cell 2 — install dependencies
!pip install -q -r ml/disease_model/requirements.txt
```

```python
# Cell 3 — upload the Mendeley zip you downloaded in Step 0, then:
!unzip -q Rice_Disease_Dataset.zip -d ml/disease_model/data/mendeley_rice_disease
```

```python
# Cell 4 — run the pipeline (USE_LOCAL_DATA=true is the default)
%run ml/disease_model/train.py
```

```python
# Cell 5 — download outputs from Colab
from google.colab import files
files.download("assets/models/rice_disease.tflite")
files.download("assets/models/disease_labels.txt")
files.download("ml/disease_model/training_report.json")
```

---

## Quick Start (local machine with GPU)

Minimum VRAM: ~8 GB (EfficientNet-B0 at batch 32).
CUDA 11.8 + cuDNN 8.6 recommended for TF 2.15.

```bash
cd rice-smart/ml/disease_model

# 1. Install deps
pip install -r requirements.txt

# 2. Download + unzip the Mendeley dataset into ./data/mendeley_rice_disease/
#    (see Step 0 above)

# 3. Run — USE_LOCAL_DATA defaults to true
python train.py
```

---

## Fallback: HuggingFace dataset

The HuggingFace dataset `Subh775/Rice-Disease-Classification-Dataset` (Apache-2.0)
is kept as a commented reference in `train.py`. It only has 4 classes and **will
cause Phase 1 to abort** because `sheath_blight` and `bacterial_leaf_blight` are
missing. Use the Mendeley dataset above instead.

To try the HF path anyway (for experimentation):

```bash
USE_LOCAL_DATA=false python train.py
```

---

## Expected runtime

| Hardware | Stage 1 (10 ep) | Stage 2 (20 ep) | Total |
|----------|-----------------|-----------------|-------|
| Colab T4 (free) | ~10 min | ~25 min | ~35–60 min |
| Colab A100 | ~4 min | ~10 min | ~15–20 min |
| RTX 3080 (local) | ~8 min | ~20 min | ~30–40 min |

Times assume ~4 000 images (full Mendeley dataset). Early stopping may reduce epochs.

---

## Output files (relative to repo root)

| File | Description |
|------|-------------|
| `assets/models/rice_disease.tflite` | INT8 quantized model, <15 MB hard limit |
| `assets/models/disease_labels.txt` | 5 class IDs, one per line, matching model output order |
| `ml/disease_model/training_report.json` | Accuracy, confusion matrix, per-class F1 |

---

## What to do after training

1. Verify `training_report.json`: test accuracy >= 0.80, TFLite accuracy drop <= 0.02.
2. Stage the output files:
   ```bash
   git add assets/models/rice_disease.tflite \
           assets/models/disease_labels.txt \
           ml/disease_model/training_report.json
   ```
3. Commit and open a PR that closes #30:
   ```bash
   git commit -m "feat(ml): add INT8 EfficientNetB0 rice disease TFLite model"
   gh pr create --title "feat(ml): rice disease TFLite model" --body "Closes #30"
   ```

---

## Updating the model

1. Bump the `"version"` field in `training_report.json` before re-running.
2. Re-run `train.py` with the same or updated dataset.
3. Replace `assets/models/rice_disease.tflite` with the new file.
4. Open a new PR — do not amend the previous merge commit.

---

## Attribution

This model is trained on the **Rice Diseases Image Dataset** by Hasan et al., 2019:

> Hasan, Md. Jahid; Mahbub, Shahin; Alom, Md. Shamim; Nasim, Md. Abdul (2019),
> "Rice Disease Image Dataset", Mendeley Data, V1, doi: 10.17632/fwcj7stb8r.1
> https://data.mendeley.com/datasets/fwcj7stb8r/1
> License: CC BY 4.0

Per CC BY 4.0, this attribution must also appear in the app's About / Licenses screen.
See issue #37 for the in-app credits screen implementation.
