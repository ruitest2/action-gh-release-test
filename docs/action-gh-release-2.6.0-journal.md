# action-gh-release 2.6.0 Research and Implementation Journal

Date: 2026-03-15

This repository is the consumer-side regression harness for `softprops/action-gh-release`.
This journal starts the `2.6.0` release-train backlog and is intentionally independent of any single upstream branch or PR.

## Purpose

- Track likely `2.6.0` work across bug fixes, feature validation, and code-quality improvements.
- Record the expected user-facing behavior for each item before implementation starts.
- Define the smallest regression coverage needed in this harness so upstream changes stay proof-driven.

## Inputs Used

- Current upstream `master` state on 2026-03-15.
- The existing regression evidence in `action-gh-release-2.5.0-regression-journal.md`.
- Current upstream code and contract surfaces:
  - `src/github.ts`
  - `src/util.ts`
  - `README.md`
  - `action.yml`
  - `.github/workflows/main.yml`
  - current tests under `__tests__/`
- Current upstream open work that still looks relevant to a small, maintainable `2.6.0` train:
  - `#698` checked-in `dist/index.js` freshness verification
  - `#641` immutable-release compatibility

## Release-Train Principles

- Prefer narrow, user-facing improvements or maintainer-safety checks over broad refactors.
- Keep GitHub platform limits out of the active bug bucket unless current repro shows an action-side defect.
- Require exact-ref regression evidence from this repo before treating a behavior change as ready.

## Independent Codebase Findings

### 1. `working_directory` exists in the action contract but is missing from the README inputs table

- Finding source:
  `action.yml`, `src/util.ts`, `src/main.ts`, and `__tests__/util.test.ts` all support `working_directory`, but the README input table does not document it.
- Why it matters:
  This is a user-visible contract drift. Callers can use the input successfully, but the main docs do not teach it or explain how it interacts with `files`.
- Suggested `2.6.0` handling:
  Small docs sync in the main repo. No runtime code change required.
- Proposed regression coverage:
  Keep the existing util tests and add a README or docs sync in the upstream change set. No new harness workflow needed.

### 2. Concurrent upload retry cleanup only matches renamed assets by raw name, not by restored label

- Finding source:
  In `src/github.ts`, the normal overwrite path matches an existing asset by raw name, aligned name, or label, but the `422 already_exists` race retry path only looks for `alignAssetName(name)`.
- Why it matters:
  Dotfiles and other GitHub-renamed assets can restore their display label while keeping a normalized raw API name. In a concurrent upload race, the retry cleanup can miss that asset and fail to recover cleanly.
- Suggested `2.6.0` handling:
  Treat as a real bug-fix candidate. Reuse the same logical match rules in the race retry path that the ordinary overwrite path already uses.
- Proposed regression coverage:
  Add a targeted unit test in the upstream repo and extend `.github/workflows/repro-duplicate-asset.yml` or add a close sibling workflow that uses a renamed asset fixture such as `.config`.

### 3. Immutable-release validation is not settled for prereleases

- Finding source:
  `src/github.ts` still creates prereleases without the forced draft-first path unless `draft: true` is explicitly requested.
- Why it matters:
  The current draft/finalize flow likely covers standard releases, but any immutable-release work must avoid reintroducing the previously fixed prerelease event regression from `#708`.
- Suggested `2.6.0` handling:
  Keep this as a verification-first item. Only change runtime behavior if a current repro shows that published prereleases are incompatible with GitHub's immutable-release rules in practice.
- Proposed regression coverage:
  Start with `.github/workflows/e2e.yml` and `.github/workflows/repro-existing-draft.yml`. If code is required, add a prerelease-specific harness path instead of changing semantics blindly.

### 4. The main CI workflow still has the checked-dist drift guard commented out

- Finding source:
  `.github/workflows/main.yml` still has the uncommitted-change verification step commented out after `npm run build`.
- Why it matters:
  This repo ships checked-in `dist/index.js`. Without an automated drift check, maintainers can merge source changes without noticing a stale bundle.
- Suggested `2.6.0` handling:
  Keep `#698` active for the release train as a maintainer-safety improvement.
- Proposed regression coverage:
  Upstream CI-only validation. No external harness workflow required unless the check changes build behavior.

## Candidate Workstreams

### 1. Fix the renamed-asset race cleanup gap

- Type: bug fix
- Why it matters:
  Concurrent uploads already have a race-recovery path, but renamed assets appear to fall through a narrower match rule than the ordinary overwrite path.
- Expected user-facing behavior:
  Concurrent uploads of assets whose raw names are GitHub-normalized should recover the same way plain filenames do when `overwrite_files` remains enabled.
- Proposed regression coverage:
  - Upstream unit tests around `upload()`
  - Harness validation using the duplicate-upload path with a renamed asset fixture
- Current status:
  Best independent bug-fix candidate found from current source review.

### 2. Sync the public docs for `working_directory`

- Type: docs and contract sync
- Why it matters:
  The input already works, but the main README contract is incomplete.
- Expected user-facing behavior:
  README users can discover and correctly use `working_directory` together with `files`.
- Proposed regression coverage:
  - Upstream docs sync only
  - Rely on existing util tests for behavior coverage
- Current status:
  Small, low-risk `2.6.0` contract cleanup.

### 3. `#698` Add a CI guard that verifies `dist/index.js` stays in sync

- Type: code quality and supply-chain hardening
- Why it matters:
  This action ships checked-in `dist/index.js`. A stale or manually altered bundle is a release risk even when source changes look correct.
- Expected user-facing behavior:
  No runtime behavior change. Maintainers get an automated failure when source and bundled output drift.
- Proposed regression coverage:
  - Upstream CI-only coverage in the main repo
  - No external harness workflow required unless the check changes build semantics
- Current status:
  Good `2.6.0` maintainer-safety item once the first bug fix lands.

### 4. `#641` Verify immutable-release compatibility and only code if current `master` still publishes too early

- Type: feature validation or docs closeout, depending on current behavior
- Why it matters:
  If GitHub Immutable Releases blocks asset mutation after publish, the action must keep the release draft until uploads finish without regressing prerelease events.
- Expected user-facing behavior:
  Asset uploads complete against a draft release, then the action publishes the release once uploads are done.
- Proposed regression coverage:
  - `.github/workflows/e2e.yml` for basic draft-to-publish smoke
  - `.github/workflows/repro-existing-draft.yml` for seeded draft reuse and publish behavior
  - Add a prerelease-specific verifier only if current `master` actually fails
- Current status:
  Verify before coding. Current source review shows a likely prerelease tradeoff, so this stays behind proof.

## Deferred Beyond `2.6.0`

- `#654` Node 24 runtime upgrade:
  treat as a `3.0.0` item because it changes the shipped GitHub Actions runtime contract rather than just tightening current `2.x` behavior.

## Not In The Active Runtime Bug Bucket Unless New Evidence Appears

- `#393` and related special-character filename reports:
  keep as platform-limit or docs territory unless current repro shows an action-level defect beyond GitHub filename normalization.
- `#541` empty-string token handling:
  keep as docs or usage clarification unless a new repro shows the action ignoring a valid fallback path.
- `#645` release asset ordering:
  keep as GitHub-controlled display behavior unless the upload order itself is wrong.

## Initial `2.6.0` Execution Order

1. Fix the renamed-asset concurrent-upload cleanup gap.
2. Sync the README for `working_directory`.
3. Add or refresh the `dist/index.js` freshness guard.
4. Re-verify immutable-release compatibility on current upstream before deciding whether `#641` needs code or only documentation.

## Regression Notes

- Keep all harness runs pinned to the exact upstream ref under test.
- Reuse existing focused workflows before inventing new harness scenarios.
- Capture Actions run URLs, tested refs, and release URLs in this journal or its follow-up entries once implementation starts.

## Current Status

- Journal created on 2026-03-15.
- No `2.6.0` implementation has been declared done yet.
- The first concrete implementation candidate is the renamed-asset concurrent-upload cleanup gap.
