---
name: binary-artifact-sourcing
description: Use when an issue or task asks for a binary artifact (ML model, trained checkpoint, dataset, TLS certificate, signed config, image, keystore, archive) to exist at a specific path in the repo. Triggers on phrasing like "source the model/dataset/cert", "add <filename>.<binary-extension> to the repo", "use the trained X to do Y", or any acceptance criterion of the shape `[ ] <path/to/binary.ext> exists`. Pause before writing code and follow the 3-step sourcing playbook.
---

# Binary-Artifact Sourcing — A Different Shape of Work

## When to invoke

Trigger on the **artifact noun**, not on the verb. Apply when the task description includes:

- "source the model / dataset / cert / image / weights"
- "add `<filename>.<binary-extension>` to the repo" — extensions like `.tflite`, `.onnx`, `.pt`, `.h5`, `.pem`, `.keystore`, `.jks`, `.zip`, `.bin`
- "use the trained X to do Y" — implying X needs to exist first
- any acceptance criterion of shape `[ ] <path/to/binary.ext> exists`

If you're about to start writing code in response to one of these, stop. Run this playbook first.

## The trap

Issues whose acceptance criteria include a binary file invite the trap of jumping into code. But you can't write code that conjures a trained model, a paid certificate, or a legally-clean dataset. The first hour of "code work" gets wasted because the missing artifact isn't a code problem.

Example from RiceSmart: issue #30 was titled "[disease] Source EfficientNet-B0 TFLite model and labels file". It reads like a coding task. It is not. The first move that made progress was admitting that.

## The 3-step playbook

### 1. Pause and ask the sourcing question

Before writing code, ask the user how the artifact gets sourced. The answer is usually some combination of:

| Option | When it applies |
|---|---|
| Download from public source | Common; verify license + spec before committing time |
| Train / generate it | Best quality; needs GPU + dataset + hours, usually off-session |
| Buy / license it | Vendor artifacts; commercial certs; paid datasets |
| Ship a placeholder + open follow-up | Unblocks downstream wiring work; flag honestly |
| Hand off to someone with capacity Claude doesn't have | GPU runs, hardware signing, manual data collection |

Use `AskUserQuestion` if multiple paths are plausible. Don't guess.

### 2. Set strict acceptance gates upfront, in writing

Before any search starts, write down what the artifact must satisfy. Hand these to the search subagent as **hard gates** with explicit "REJECT if any gate fails" instructions.

Common gates by artifact type:

| Artifact | Gates to set |
|---|---|
| ML model | License (permissive: MIT / Apache / CC-BY); architecture; input shape; output classes (exact names + order); quantization; file-size ceiling; model card present |
| Dataset | License; class coverage (every class you need, by name); sample count per class; image / record format; permitted use case (commercial / research / educational) |
| TLS cert | Key algorithm + length; SAN list; CA chain; expiry; intended use (server / client / code-signing) |
| Keystore | Format (JKS / PKCS12); key alias; password policy; intended use |
| Pretrained weights | License; framework version compatibility; checksum; companion config |

When a candidate fails a gate, **the right answer is to bail**, not to take the best of a bad bunch. Document every rejection so the next session doesn't re-search the same dead ends — write to `docs/<feature>/sourcing-audit.md` or similar.

### 3. If you can't ship the artifact in this session, ship the pipeline

Some artifacts require capacity Claude doesn't have: GPU training, paid certificate issuance, manual data collection, hardware signing. In those cases:

- Scaffold a **reproducible pipeline**: a script that produces the artifact, with pinned dependencies, version-locked tools, and a documented runtime.
- Add a **one-click runner**: Colab notebook with Open-in-Colab badge for GPU work; `docker compose up` for sandboxed prod-like setups; a GitHub Action for CI-driven artifact builds.
- Land the **canonical config / labels / schema** that the artifact will plug into — these are pure data and can be in the PR even when the binary isn't.
- Use **`Refs #N` not `Closes #N`** in the commit. The issue stays open honestly until the artifact actually lands.
- Open a **follow-up commit / sub-issue** for "drop the trained artifact in" — a 1-line task someone can do off-session.

## Common consequence: license obligations generate tickets

When you pick a CC-BY / MIT-Attribution / similar artifact, the license terms generate follow-up work — in-app credits screen, About / Licenses page, README acknowledgement, NOTICE file. **Open these as separate issues immediately**, labeled as blockers on whatever PR ships the artifact in a release build. Don't let attribution rot in a TODO comment.

## Worked example from this repo

Issue #30 wanted `assets/models/rice_disease.tflite`. The session:

1. **Asked the sourcing question** — user picked "download a pre-trained one".
2. **Set the gates**: 5 specific classes including `sheath_blight` + `healthy`, permissive license (MIT/Apache/CC-BY), 224×224×3 input, INT8, ≤25 MB, model card present.
3. **Sonnet evaluated 6 public candidates** → all failed at least one gate → **bailed at Phase 1** rather than ship a 3-class model that would break the next issue.
4. **Pivoted**: user picked "train it". Scaffolded `ml/disease_model/{train.py, train.ipynb, requirements.txt, .gitignore}`, Open-in-Colab badge, canonical `assets/models/disease_labels.txt`, decisions log at `docs/ml/disease_model.md`. PR opened with `Refs #30`.
5. **License obligation became its own issue** (#37 — in-app CC BY 4.0 credits screen), labeled to block the next PR's merge.

The `.tflite` itself ships when the user runs Colab. The PR didn't lie about completeness.

## Red flags that mean you skipped this skill

- You're writing code to "wire up" an artifact that doesn't exist yet
- The PR description says "model" but the diff has no `.tflite`, `.onnx`, or `.pt` file
- You're about to commit `// TODO: real model goes here` and call the issue done
- A subagent claims it "found a good fit" but didn't show you the license string
- The chosen artifact's license has "attribution" or "share-alike" in it and there's no follow-up issue tracking that obligation
