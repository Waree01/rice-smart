# RiceSmart — Claude Code Team Policy

This file orchestrates how Claude Code agents collaborate on RiceSmart development.
It is loaded into every session and acts as the team's working agreement.

## Project context

RiceSmart is a Flutter mobile app helping Thai rice farmers reduce costs (15–25%)
and increase yield (20–35%) via on-device AI for disease/pest detection plus a
Thai-native chatbot (Pasadee) backed by a multi-LLM gateway.

**Scope is fixed at 3 features:** disease detection, pest identification, Pasadee
chatbot. Anything else is Future Work and must NOT bloat this thesis project.

## How the team works now

Priority: **speed + quality**, not cost. Strict division of labor by model:

- **Opus 4.7 — the main session, only.** Talks to the user, asks questions,
  plans, analyzes, decides what to delegate. Does NOT write production code,
  run tests, edit docs, or do mechanical work. Opus is for thinking.
- **Sonnet — the default for every subagent.** Coding, code review, security
  audit, search, lookups, research, doc edits. Whenever the output quality
  matters, this is the floor.
- **Haiku — only for narrow, mechanical command-runner tasks** where there is
  essentially no judgment and the output is a tool result, not analysis.
  Examples: running a known test command, executing a git push, applying a
  formatter. If you're not sure → use Sonnet.

**Subagents are NEVER Opus.** If a task needs Opus-level reasoning to execute,
the main session does it inline; it does not spawn an Opus subagent.

Why this tilt: Haiku has drifted on read-only "Explore" prompts in this repo
(returned empty replies pretending to have prior context). Sonnet does not.
Quality first, cost second.

There are no project-level agent files. The main session uses **built-in
agents** (from the harness list) and passes an **explicit `model:` parameter**
on every `Agent` call.

## Task → subagent → model routing

| Task | Subagent | Model |
|---|---|---|
| Quick code search / "where is X" | `general-purpose` | sonnet |
| General Q&A or one-off lookup | `general-purpose` | sonnet |
| Multi-step research / synthesis across files | `general-purpose` | sonnet |
| Flutter feature implementation | `flutter-specialist` | sonnet |
| Dart/Flutter build or analyzer fix | `dart-build-resolver` | sonnet |
| Code review (Flutter/Dart) | `flutter-reviewer` | sonnet |
| Generic code review | `code-reviewer` | sonnet |
| Security audit (Semgrep/Trivy/TruffleHog) | `security-auditor` | sonnet |
| README / CHANGELOG / ADR edits | `docs-writer` | sonnet |
| Run a fixed test command, report pass/fail | `test-runner` | haiku |
| Routine git commit / push / open PR | `pr-manager` | haiku |
| Hard architecture / design analysis | **main session (Opus)** — no subagent | — |
| Decide between two approaches / requirement tradeoffs | **main session (Opus)** — no subagent | — |

**Rules of thumb the main session follows:**
- Pass `model:` on every `Agent` call. Never rely on inheritance.
- Default subagent = **Sonnet**. Drop to Haiku only if the task is a pure command runner.
- Never spawn an Opus subagent. Planning / analysis stays in the main session.
- Independent subagents run **in parallel** — multiple `Agent` calls in one message.
- Prefer one well-scoped Sonnet subagent over a long chain of Haiku ones.

## Mandatory workflow for non-trivial features

For any feature touching more than one file:

1. **Plan (Opus, main session)** — read the issue / spec, decompose into tasks. No subagent here.
2. **Implement** — delegate to `flutter-specialist` (sonnet).
3. **Quality gates in parallel** — `flutter-reviewer` (sonnet) + `security-auditor` (sonnet) + `test-runner` (haiku) in one message.
4. **Iterate (Opus)** — read findings, decide fixes, delegate again. Max 3 cycles before asking the user.
5. **Ship** — `pr-manager` (haiku) opens the PR.
6. **Docs** — `docs-writer` (haiku) updates README/CHANGELOG after merge.

For a one-line bug fix: main session plans → spawns one `flutter-specialist` (sonnet) → `test-runner` (haiku) → `pr-manager` (haiku).

## Hard limits (main session pauses and asks the user)

- Adding a new top-level dependency
- Quality gates fail 3 times in a row
- `security-auditor` flags CRITICAL with no obvious fix
- A single PR would change >20 files
- Request is outside the 3 core features
- About to spawn any subagent on Opus (this should never happen — pause and rethink)

## Main session boundaries

- Cannot merge PRs (user does)
- Cannot push to `main` directly
- Cannot override CRITICAL security findings without explicit user OK

## Hard rules (never violate)

### Security
- API keys MUST use `envied` with obfuscation; never plaintext in source
- Firebase service accounts NEVER in repo
- TFLite models loaded from `assets/` only, never network
- Local storage of farmer data MUST be encrypted at rest
- HTTPS only; no plain HTTP calls
- `.env`, `*.key`, `*.pem`, `service-account*.json` files are blocked from reading by settings.json

### Git
- NEVER `git push --force` to main or shared branches
- NEVER `git reset --hard` on shared branches
- NEVER commit secrets, even temporarily
- All changes go through PR — no direct commits to main

### Scope
- 3 features only — disease, pest, Pasadee
- New top-level dependencies require justification in the PR description
- Pasadee covers the rice lifecycle and farming advice; cost/financial logic is
  the AI system's job, NOT the chatbot's

### Code quality
- `flutter analyze` must show zero warnings before merge
- `dart format .` applied to all changes
- New code requires at least one test
- Coverage targets: ML inference 90%, repos 80%, UI 60%

## Model discipline (quality + speed first)

- Default subagent model is **Sonnet**, enforced via `CLAUDE_CODE_SUBAGENT_MODEL`
  in `.claude/settings.local.json` — safety net so silent inheritance can't
  fall back to Opus.
- Every `Agent` call passes an **explicit** `model:` (`"sonnet"` or `"haiku"`).
- **No subagent ever uses Opus.** Hard tasks stay in the main session.
- Haiku is reserved for narrow command-runner tasks (`test-runner`,
  `pr-manager`). If you'd hesitate to use Haiku, use Sonnet.
- Cost is a side concern, not a constraint. Quality of the deliverable and
  speed-to-result come first. Opus stays on the conversation so Sonnet can
  focus on the typing without losing fidelity.

## Branch and commit conventions

- Branch: `<type>/<short-kebab-name>` (feat/, fix/, refactor/, chore/, docs/, security/)
- Commits: conventional commits (`feat(scope): subject`, `fix(scope): subject`)
- One logical change per PR; squash merges to main

## Communication

- Code, comments, commits, PR descriptions: English
- User-facing UI strings: Thai (via `intl` package, .arb files)
- README: English primary; optional `README.th.md` for Thai

## When in doubt

- Push back if a request would expand scope beyond 3 features
- Ask for clarification rather than guessing on security-sensitive changes
- Prefer "no" over "maybe" for destructive operations
- Hard design / requirement tradeoffs: main session (Opus) handles inline — never spawn an opus subagent
- Safety calls: spawn `security-auditor` (sonnet)

## Local commands the team relies on

```bash
# Setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Quality
flutter analyze
dart format .
flutter test --coverage

# Security scans
semgrep --config=p/dart --config=p/owasp-top-ten lib/
trivy fs --severity CRITICAL,HIGH .
trufflehog filesystem . --only-verified

# Build
flutter build apk --release
flutter build ios --release
```
