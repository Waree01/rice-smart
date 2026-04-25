# RiceSmart — Claude Code Team Policy

This file orchestrates how Claude Code agents collaborate on RiceSmart development.
It is loaded into every session and acts as the team's working agreement.

## Project context

RiceSmart is a Flutter mobile app helping Thai rice farmers reduce costs (15–25%)
and increase yield (20–35%) via on-device AI for disease/pest detection plus a
Thai-native chatbot (Pasadee) backed by a multi-LLM gateway.

**Scope is fixed at 3 features:** disease detection, pest identification, Pasadee
chatbot. Anything else is Future Work and must NOT bloat this thesis project.

## The agent team

| Agent | Role | When to invoke |
|---|---|---|
| @architect | Plan & design | Start of every new feature, before coding |
| @flutter-specialist | Implement | After architect's plan is accepted |
| @code-reviewer | Quality review | After implementation, before commit |
| @security-auditor | Security audit | Before every commit; mandatory before merge to main |
| @test-runner | Tests & coverage | After implementation; before merge |
| @pr-manager | Git/GitHub ops | When ready to ship |
| @docs-writer | Documentation | After feature ships, or when docs drift |

## Mandatory workflow

For any non-trivial feature (>1 file changed):

1. `@architect` produces a plan from the GitHub issue
2. `@flutter-specialist` implements per the plan
3. `@code-reviewer` reviews the diff
4. `@test-runner` validates tests pass and coverage targets met
5. `@security-auditor` scans (REQUIRED if touching auth, crypto, storage, network, or LLM keys)
6. `@pr-manager` opens the PR
7. `@docs-writer` updates README/CHANGELOG (after merge)

For a one-line bug fix, you may skip steps 1 and 7.

## Parallel execution rules

These can run in parallel (no dependencies):
- code-reviewer + security-auditor + test-runner

These must run sequentially:
- architect → flutter-specialist (plan before code)
- flutter-specialist → code-reviewer (code before review)
- everything → pr-manager (review/test/audit before PR)

To trigger parallel review:
```
@code-reviewer @security-auditor @test-runner — review changes in lib/features/chatbot/
```

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

## Cost discipline

Default subagent model is `haiku` (set via `CLAUDE_CODE_SUBAGENT_MODEL` env).
Per-agent overrides:
- `@architect` and `@security-auditor` use `opus` (deep reasoning required)
- Everyone else uses `sonnet` or `haiku`

Don't use `opus` for routine work — it's 5× the cost of haiku.

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
- Defer to the architect on design decisions; defer to the security-auditor on safety calls

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
