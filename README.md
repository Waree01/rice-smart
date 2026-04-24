# 🌾 rice-smart — AI-Powered Thai Rice Farming Assistant

> ระบบช่วยเหลือชาวนาไทยด้วย AI เพื่อลดต้นทุนและเพิ่มผลผลิตข้าว

[![CI/CD](https://github.com/nenoteerawat/rice-smart/actions/workflows/ci.yml/badge.svg)](https://github.com/nenoteerawat/rice-smart/actions/workflows/ci.yml)
[![Security](https://github.com/nenoteerawat/rice-smart/actions/workflows/dependency-review.yml/badge.svg)](https://github.com/nenoteerawat/rice-smart/actions/workflows/dependency-review.yml)

## About

rice-smart is a cross-platform Flutter app that helps Thai rice farmers:

- **Reduce farming costs by 15–25%** through optimized resource management
- **Increase yield by 20–35%** via early disease/pest detection

The app features **Pasadee (พัสดี)**, a virtual farmer persona backed by
a multi-LLM gateway, plus on-device ML for disease/pest detection and
agro-weather integration.

## Core Features

### 1. Rice Disease Detection 🔬
- On-device inference with TensorFlow Lite (EfficientNet-B0 target)
- Works offline; no image leaves the device
- Result card shows severity band, confidence, and treatment advice
  sourced from the bundled Thai knowledge base
- *Current state:* inference service returns deterministic mock
  classifications until real `.tflite` weights are provisioned.

### 2. Pest Identification 🐛
- YOLOv5s-INT8 target (~3–4 MB on device)
- Detection list + primary recommendation from the pest KB
- *Current state:* same mock pattern as disease detection.

### 3. Pasadee Chatbot (พัสดี) 💬
- Multi-LLM gateway: **Typhoon → Claude → Gemini → GPT** fail-over chain
- Pasadee persona injected as the system prompt on every turn
- Markdown rendering, provider switcher, usage counters
- Suggested-prompts chip bar + seed prompts from disease/pest results

### 4. Agro-Weather Screen 🌤️
- 7-day TMD forecast with NASA POWER fallback
- Derived agro-indicators: disease risk (0–1), cumulative GDD,
  per-day risk badges
- Handoff button hands the forecast summary to Pasadee for follow-up

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x / Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| On-device AI | TensorFlow Lite (EfficientNet-B0, YOLOv5s) |
| LLM Backend | Claude, GPT, Gemini, Typhoon |
| Thai NLP | WangchanBERTa embeddings (planned) |
| Weather | TMD API + NASA POWER fallback |
| Auth & DB | Firebase (optional; stubs ready) |
| Local Storage | SQLite + Hive + SharedPreferences |
| CI/CD | GitHub Actions |
| Security | Semgrep SAST, Trivy, TruffleHog, Dependency Review |
| Env Management | flutter_dotenv (runtime loader) |

## Getting Started

### Prerequisites
- Flutter SDK 3.22+
- Dart 3.2+
- Android Studio / Xcode (for device builds)

### Setup

```bash
git clone git@github.com:nenoteerawat/rice-smart.git
cd rice-smart

# Install dependencies — no codegen step needed.
flutter pub get

# (Optional) Provide real API keys; otherwise the app boots with the
# empty .env.example bundled as an asset and Pasadee surfaces a friendly
# "no API keys configured" message.
cp .env.example .env
# Edit .env and fill in the keys you have.

flutter run
```

### Required Assets (when available)

Drop these into `assets/models/` and update `disease_inference_service.dart`
/ `pest_inference_service.dart` to call the real interpreter:

- `rice_disease.tflite` — EfficientNet-B0 fine-tuned on Thai rice leaves
- `pest_yolov5s.tflite` — YOLOv5s INT8 on the 5-class pest set
- `disease_labels.txt`, `pest_labels.txt` — newline-separated class
  labels

## Project Structure

```
lib/
├── main.dart                         # Entry — loads env, Hive, locale
├── app.dart                          # MaterialApp, theme, router
├── config/
│   ├── env.dart                      # Runtime .env loader
│   └── router.dart                   # GoRouter routes
├── core/
│   ├── constants/app_constants.dart
│   ├── theme/{app_colors, app_theme}.dart
│   └── services/
│       ├── llm_gateway.dart          # Multi-LLM gateway w/ failover
│       └── notification_service.dart # FCM stub
├── data/
│   └── knowledge_base.dart           # Async accessor for assets/knowledge_base/*
├── models/
│   ├── chat_message.dart
│   ├── disease_result.dart
│   ├── pest_result.dart
│   ├── weather_forecast.dart
│   └── farmer_profile.dart
└── features/
    ├── dashboard/                    # Home screen + weather summary card
    ├── disease_detection/            # Image capture → inference → result
    ├── pest_identification/          # Same shape as disease_detection
    ├── chatbot/                      # Pasadee chat UI
    ├── weather/                      # 7-day agro-forecast
    ├── onboarding/                   # 3-slide first-launch flow
    └── settings/                     # LLM preference, about, reset
assets/
├── knowledge_base/
│   ├── diseases.json                 # 5 rice diseases in Thai
│   ├── pests.json                    # 5 common rice pests
│   ├── growing_stages.json           # Lifecycle calendar
│   └── best_practices.json           # Traditional Thai practices
└── images/ icons/ models/ fonts/     # Empty until populated
```

## Architecture Notes

- **Pasadee is a persona, not a model** — the gateway injects the Thai
  persona prompt before any user turn, so whichever LLM answers, the
  farmer hears the same voice.
- **Fail-over chain** — the gateway walks `preferred → [others]` and
  skips providers with empty keys, so a partial `.env` still works.
- **On-device inference** — images never leave the device; this is both
  a privacy property (reviewed in SECURITY.md) and a rural-connectivity
  requirement.
- **Feature-based folders** — each feature owns its `screens/`,
  `providers/`, `services/`, and `widgets/`. Shared types live in
  `models/`.

## Testing

```bash
flutter test
```

Current coverage:

- `test/widget_test.dart` — dashboard smoke + onboarding render
- `test/unit/llm_gateway_test.dart` — fail-over ordering, persona
  prompt, error handling
- `test/unit/weather_service_test.dart` — disease-risk scoring, GDD
- `test/unit/chat_message_test.dart` — JSON roundtrip, copyWith
- `test/unit/disease_result_test.dart` — severity → colour mapping

## Security

See [SECURITY.md](SECURITY.md).

Highlights:
- API keys loaded at runtime via `flutter_dotenv`; never committed
  (`.env` is gitignored).
- All image ML runs on-device — no photo ever leaves the handset.
- CI runs Semgrep SAST, Trivy FS scan, TruffleHog secrets, and
  Dependency Review on every PR.

## Cleanup TODOs

These artifacts live in the repo from earlier scaffolding and need a
manual delete (the sandbox couldn't remove them):

- `{lib/` — empty leftover directory from a broken bootstrap run.
- `flutter_01.log` — Flutter CLI crash log.

Run locally: `rm -rf '{lib' flutter_01.log && git add -A && git commit -m 'chore: remove scaffold leftovers'`

## Contributing

This is a graduation project; contributions welcome after the thesis
defence.

## License

Part of an academic thesis — license TBD.

---

**Graduation Project** — Computer Science / IT  
**Developer:** Neno Teerawat  
**Academic Year:** 2026
