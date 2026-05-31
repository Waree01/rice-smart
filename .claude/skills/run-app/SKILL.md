---
name: run-app
description: Launch the RiceSmart Flutter app on macOS desktop or iPhone (physical device or simulator). Use when the user says "run the app", "run this application", "launch the app", "start the app", "run on mac", "run on iphone", or wants to see the app running to verify a change.
---

# Run RiceSmart

Verified launch procedure for the RiceSmart Flutter app — captured from a working session so future sessions don't rediscover.

## Pre-flight (every target)

```bash
flutter pub get
```

**No codegen / build_runner needed.** `pubspec.yaml` has no `freezed`, `envied`, `riverpod_generator`, or `json_serializable`. Verified 2026-05-31. Don't run `dart run build_runner build` — it's a no-op and slow.

## Available targets

`flutter devices` lists what's connected. On this dev machine the expected output is:

| Target | Device ID example | Notes |
|---|---|---|
| macOS desktop | `macos` | Fastest. No camera → disease/pest detection won't work. Chatbot fine. |
| iPhone (physical) | UUID like `00008140-000518AC0A29801C` | Real device. Camera + TFLite work. First build ~5–8 min. |
| iOS Simulator | varies (must boot first) | Faster than physical, but no camera. |
| Chrome (web) | `chrome` | **Do not use** — TFLite + camera plugins have no working web fallback here. |

If the user doesn't specify, ask which target. Don't guess.

## macOS desktop (verified end-to-end)

Launch in background — `flutter run` doesn't exit on its own:

```bash
flutter run -d macos --release
```

Tool call: `Bash` with `run_in_background: true`. First build ~2–3 min on Apple Silicon.

**Wait until ready** — grep the background output file for the build artifact line:

```
✓ Built build/macos/Build/Products/Release/rice_smart.app
```

A loop like this works:

```bash
until grep -qE "(Built build/macos|error:|Failed)" "$OUTPUT_FILE"; do sleep 10; done
```

**Verify the process is alive:**

```bash
pgrep -f "rice_smart.app/Contents/MacOS/rice_smart"
```

**Drive it, don't just launch it** — screenshot the window to confirm UI rendered (a blank window means the launch entrypoint resolved but the app crashed at first frame):

```bash
osascript -e 'tell application "System Events" to set frontmost of (every process whose name is "rice_smart") to true'
sleep 2
screencapture -x /tmp/rice_smart_running.png
```

Then `Read /tmp/rice_smart_running.png`. The main screen should show:
- Green header strip: "RiceSmart · พัสดี" with settings gear
- Thai welcome: "สวัสดีครับ! ผมพัสดี"
- Three feature entries: Pasadee chatbot pulse (center), "วินิจฉัยโรคข้าว" card (left), "ระบุศัตรูพืช" card (right)
- Location prompt: "ยังไม่ได้เลือกตำแหน่ง แตะเพื่อเลือกจังหวัด"

## iPhone — physical device (documented, validate on first use)

```bash
flutter devices                    # find the iOS device UUID
flutter run -d <UUID>              # debug, fast iteration + hot reload
# or
flutter run -d <UUID> --release    # slower first build, production-like
```

Caveats:
- Device must be connected via USB and trusted.
- Code signing must be set up in `ios/Runner.xcodeproj`. If the build fails with `Code Signing Error` or `No profiles for 'com.example...'`, open the workspace in Xcode once to configure team / bundle ID.
- First build is 5–8 minutes; subsequent builds are much faster.
- Don't bypass signing or disable hooks (`--no-codesign`) — fix the signing setup instead.

## iOS Simulator (alternative when no device handy)

```bash
xcrun simctl list devices booted          # check if any sim already booted
open -a Simulator                          # boot the default sim if none
flutter devices                            # the sim now appears in the list
flutter run -d <simulator-id>
```

## Build warnings to ignore

These appear on every macOS build and are NOT actionable from this project:

- `flutter_tts` Swift 6 mode warnings about exhaustive `switch` over `AVSpeechSynthesisVoiceQuality` / `AVSpeechSynthesisVoiceGender`
- `geolocator_apple` warning about `MACOSX_DEPLOYMENT_TARGET=10.11`

Both are in pub-cache dependencies. Don't try to fix them.

## Stopping the app

- If you have the `flutter run` process in the foreground, press `q`.
- If background, either send `q` to its stdin, or `kill <PID>` (find with `pgrep -f rice_smart`).
- Closing the macOS window also terminates the process.

## Routing notes (for the main session)

- This is a command-runner workflow; main session (Opus) drives Bash directly. No subagent needed.
- The skill replaces the generic built-in `run` skill for this project.
- Don't delegate the launch to a subagent — it's interactive long-running work that needs the main session to manage the background process handle.
