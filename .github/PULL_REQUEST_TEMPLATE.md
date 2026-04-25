<!--
  Thanks for contributing to RiceSmart!
  This template is referenced by the @pr-manager Claude Code agent.
-->

## What
<!-- One paragraph: what this PR changes from a user's perspective -->

## Why
<!-- Motivation; link to issue with "Closes #N" or "Refs #N" -->

## How
<!-- Technical approach; key files changed; new patterns introduced -->

## Test plan
- [ ] `flutter analyze` clean (zero warnings)
- [ ] `dart format .` applied
- [ ] Unit tests pass
- [ ] Widget tests pass
- [ ] Manual test on Android emulator
- [ ] Manual test on iOS simulator (if UI changes)
- [ ] Coverage target met for changed feature

## Screenshots / videos
<!-- Required for any UI change -->

## Security review
- [ ] No new secrets added (env vars use `envied`)
- [ ] No new permissions requested
- [ ] No new network endpoints (or HTTPS-only with cert pinning)
- [ ] Firestore rules reviewed (if data model changed)
- [ ] @security-auditor sign-off obtained (if touching auth/crypto/storage)

## Accessibility
- [ ] Text scales correctly (large text settings)
- [ ] Color contrast WCAG AA
- [ ] Screen reader labels present (semantics widget where needed)

## Localization
- [ ] User-facing strings in `.arb` files (Thai + English)
- [ ] No hardcoded Thai/English in widgets

## Performance
- [ ] No regressions on disease/pest inference time
- [ ] No new heavy synchronous work in build methods
- [ ] App startup time unchanged

## Breaking changes
<!-- List any, or write "None" -->

## Migration notes
<!-- If breaking, how should consumers update? -->

## Refs
- Closes #<issue>
- Depends on #<other PR>
- Related ADR: docs/adr/NNNN-title.md (if architectural)
