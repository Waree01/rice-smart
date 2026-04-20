# 🌾 rice-smart - AI-Powered Thai Rice Farming Assistant

> ระบบช่วยเหลือชาวนาไทยด้วย AI เพื่อลดต้นทุนและเพิ่มผลผลิตข้าว

[![CI/CD](https://github.com/nenoteerawat/rice-smart/actions/workflows/ci.yml/badge.svg)](https://github.com/nenoteerawat/rice-smart/actions/workflows/ci.yml)
[![Security](https://github.com/nenoteerawat/rice-smart/actions/workflows/dependency-review.yml/badge.svg)](https://github.com/nenoteerawat/rice-smart/actions/workflows/dependency-review.yml)

## About

rice-smart is a cross-platform mobile application built with Flutter that uses AI to help Thai rice farmers:

- **Reduce farming costs by 15-25%** through optimized resource management
- **Increase yield by 20-35%** through early disease/pest detection

The app features **Pasadee (พัสดี)**, a virtual farmer persona chatbot powered by a multi-LLM gateway.

## Core Features

### 1. Rice Disease Detection 🔬
- On-device CNN inference using TensorFlow Lite
- EfficientNet-B0 model for disease classification
- Works offline — no internet required for diagnosis

### 2. Pest Identification 🐛
- YOLOv5s model with INT8 quantization (~3-4 MB)
- Real-time pest detection from camera feed
- Treatment recommendations from knowledge base

### 3. Pasadee Chatbot (พัสดี) 💬
- Virtual farmer persona — friendly, trustworthy
- Multi-LLM Gateway: Claude, GPT, Gemini, Typhoon
- RAG with WangchanBERTa Thai embedding
- Weather-integrated farming suggestions (TMD API)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x / Dart |
| State Management | Riverpod |
| On-device AI | TensorFlow Lite (GPU/Metal delegates) |
| LLM Backend | Claude, GPT, Gemini, Typhoon |
| Thai NLP | WangchanBERTa embeddings |
| Weather | TMD API + NASA POWER fallback |
| Auth & DB | Firebase (Auth, Firestore, FCM) |
| Local Storage | SQLite + Hive |
| CI/CD | GitHub Actions |
| Security | Semgrep, Trivy, TruffleHog |

## Getting Started

### Prerequisites
- Flutter SDK 3.22+
- Dart 3.2+
- Android Studio / Xcode
- Firebase CLI

### Setup

```bash
# Clone the repo
git clone https://github.com/nenoteerawat/rice-smart.git
cd rice-smart

# Install dependencies
flutter pub get

# Copy environment template
cp .env.example .env
# Edit .env with your API keys

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Project Structure

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # App widget & theme
├── config/                    # Router, environment
├── core/
│   ├── constants/             # App-wide constants
│   ├── theme/                 # Colors, typography
│   ├── utils/                 # Helpers
│   └── services/              # LLM Gateway, notifications
├── features/
│   ├── dashboard/             # Home screen
│   ├── disease_detection/     # Rice disease CNN
│   ├── pest_identification/   # Pest YOLO detection
│   ├── chatbot/               # Pasadee chatbot
│   └── weather/               # TMD weather integration
├── models/                    # Shared data models
└── data/                      # Local & remote data sources
```

## Security

See [SECURITY.md](SECURITY.md) for our security policy and practices.

## Contributing

This is a graduation project. Contributions are welcome after the thesis defense.

## License

This project is part of an academic thesis. License TBD.

---

**Graduation Project** — Computer Science / IT  
**Developer:** Neno Teerawat  
**Academic Year:** 2026
