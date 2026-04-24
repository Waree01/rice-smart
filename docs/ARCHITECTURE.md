# RiceSmart Architecture

## Layering

```
UI (Screens / Widgets)
  ↑ watches
Riverpod providers (StateNotifier / FutureProvider)
  ↑ calls
Services (LlmGateway, WeatherService, Inference services, KB)
  ↑ uses
Models (pure Dart value classes)
```

All state flows through Riverpod. Screens never call services directly
— they watch the provider that owns the service result.

## Core services

### LlmGateway
- Centralizes all LLM calls.
- Injects Pasadee persona as the system prompt.
- Priority: `typhoon → claude → gemini → gpt`.
- Skips providers with empty API keys so partial configuration works.
- Adapter methods per provider — each adapter converts the shared
  `ChatMessage` list into the provider's expected wire format.

### WeatherService
- Primary: TMD `/forecast/location/daily/at` (token required).
- Fallback: NASA POWER daily agro-climate API (no auth).
- Synthetic fallback: built-in 7-day sample data so the UI never crashes
  offline.
- Agro-indicators (`disease risk`, `GDD`) are pure functions on the
  service so they can be unit-tested without network.

### Inference services
- `DiseaseInferenceService` and `PestInferenceService` each expose a
  single async entry point (`classify` / `detect`).
- The current body is a deterministic mock keyed on the image path. The
  swap point for real TFLite is clearly documented in-code
  (`_runModel`).

### KnowledgeBase
- Loads four JSON assets once per app session and caches the decoded
  maps.
- Inference services pull treatment advice from here so the KB is the
  single source of truth for farmer-facing recommendations.

## Data flow — Disease detection

```
User taps "ถ่ายรูป"
  → image_picker returns file path
  → DiseaseDetectionController.analyze(path)
      → DiseaseInferenceService.classify(path)
          → _runModel(path)           # mock today, TFLite tomorrow
          → KnowledgeBase.diseaseById # pull localized advice
      → state = AsyncData(result)
  → DiseaseResultCard renders
  → onAskPasadee → context.push('/chatbot', extra: seed)
      → ChatbotScreen picks up `initialPrompt` and auto-sends
          → ChatbotController.send
              → LlmGateway.sendMessage(...)
```

## Failure handling

- **LLM down** → user sees a friendly Thai message with guidance to
  configure `.env` or retry.
- **TMD down** → silent fallback to NASA POWER; logged at warn.
- **NASA down** → synthetic week is returned; screen still renders.
- **Camera denied** → snackbar with permission hint.

## Security boundary

- `.env` is never committed. `.env.example` ships as a bundled asset
  with empty values so first-run boots cleanly.
- Images are processed entirely on-device; the network is only used by
  the LLM gateway (chatbot) and weather service.
- CI runs Semgrep SAST, Trivy FS scan, and TruffleHog on every PR.
