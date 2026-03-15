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
  Add a targeted unit test in the upstream repo and extend `.github/workflows/repro-duplicate-asset.yml` so it can run against a renamed asset fixture such as `.config`.

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
  - Harness validation using `.github/workflows/repro-duplicate-asset.yml` twice:
    - baseline `asset_name: shared.txt`
    - renamed-asset case `asset_name: .config`, `expected_display_name: .config`
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

## Implementation Progress

### 2026-03-15: renamed-asset concurrent upload fix

- Upstream branch under test:
  `fix-renamed-asset-race`
- Final verified upstream ref:
  `0f4b216be284d9d41b71ff59f6d6577eac540ae8`
- Upstream merge state:
  merged to `softprops/action-gh-release` `master` as `#760` / `6ca3b5d`
- Final upstream outcome:
  narrow runtime bug fix plus targeted tests and regenerated `dist/index.js`
- What the upstream change now covers:
  - poll release assets briefly after release-asset metadata 404s instead of assuming immediate visibility
  - treat upload-endpoint 404s that point at the `update-a-release-asset` docs as the same recoverable metadata race
  - keep the retry scoped to the asset upload path rather than changing unrelated release orchestration
- Harness coverage added in this repo:
  - `.github/workflows/repro-duplicate-asset.yml` now accepts `asset_name` and `expected_display_name`
  - verified both:
    - `asset_name: shared.txt`
    - `asset_name: .config`, `expected_display_name: .config`
- Final regression evidence against `0f4b216be284d9d41b71ff59f6d6577eac540ae8`:
  - assets output smoke:
    `https://github.com/ruitest2/action-gh-release-test/actions/runs/23115425264`
  - dotfile display-name repro:
    `https://github.com/ruitest2/action-gh-release-test/actions/runs/23115426256`
  - duplicate asset race, `shared.txt`:
    `https://github.com/ruitest2/action-gh-release-test/actions/runs/23115427270`
  - duplicate asset race, `.config`:
    `https://github.com/ruitest2/action-gh-release-test/actions/runs/23115428432`
- Intermediate proof during implementation:
  - `4a75d2e06369f089b20677676584b6f5d7413a97` still failed the plain duplicate-asset race because a post-upload metadata 404 could surface before the matching asset was rediscoverable.
  - `9cbdf27fcd293e5a8c7c9c178a064ca07d44722b` improved the timing path but still failed because the 404 classifier did not recognize the real upload-endpoint request shape.
- Remaining platform note:
  final successful runs still show GitHub-hosted Node 20 deprecation annotations for this action and supporting marketplace actions. That is relevant release-train context, but it is a runtime-upgrade track item rather than part of this bug fix.

### 2026-03-15: `working_directory` contract sync

- Upstream branch under test:
  `docs-working-directory-readme`
- Current upstream ref:
  `e0738d63474019348cc54b6ab16bb09979dc91be`
- Upstream merge state:
  merged to `softprops/action-gh-release` `master` as `#761` / `438c15d`
- Current upstream outcome:
  docs-only contract sync in `README.md` plus wording correction in `action.yml`
- What the upstream change covers:
  - add the missing `working_directory` entry to the README inputs table
  - add a short usage example showing `files` patterns relative to `working_directory`
  - clarify that the action resolves `files` from the workspace root when `working_directory` is omitted
  - align `action.yml` wording with current GitHub Actions behavior instead of implying `run` step `working-directory` semantics
- Verification performed:
  - `npm run fmtcheck`
  - `npm run typecheck`
  - `npm run build`
  - `npm test`
- External regression coverage:
  not run for this item because the branch is docs-only and does not change runtime behavior
- GitHub-platform note validated during docs review:
  GitHub's `defaults.run.working-directory` setting applies to `run` steps, so this action's own `working_directory` input remains the correct way to resolve release asset globs under a subdirectory for a `uses:` step.

### 2026-03-15: `dist/index.js` freshness guard

- Upstream branch under test:
  `ci-dist-freshness-guard`
- Current upstream ref:
  `728647f07c33da14988fa8e654174bf41c7f64d5`
- Upstream merge state:
  merged to `softprops/action-gh-release` `master` as `#762` / `8a8510e`
- Current upstream outcome:
  narrow CI-only maintainer-safety check in `.github/workflows/main.yml`
- What the upstream change covers:
  - run `git diff --exit-code --stat -- dist/index.js` after `npm run build`
  - fail CI with a direct maintainer-facing message when the checked-in bundle drifts from the built output
  - keep the guard scoped to `dist/index.js` instead of reviving a generic working-tree cleanliness check
- Verification performed:
  - `npm run fmtcheck`
  - `npm run typecheck`
  - `npm run build`
  - `npm test`
  - `git diff --exit-code --stat -- dist/index.js`
- External regression coverage:
  not run for this item because the branch is CI-only and does not change runtime behavior

### 2026-03-15: immutable-release verification

- Upstream branch under test:
  `verify-immutable-release`
- Current upstream ref:
  `fadef12636129a8719d57afbbb21e49964dbb22a`
- Current upstream outcome:
  narrow docs plus clearer error messaging, without changing prerelease publish semantics
- What current GitHub behavior was verified:
  - GitHub immutable releases reject asset uploads after publish.
  - Standard releases in `softprops/action-gh-release` already avoid that by uploading assets before publish.
  - Brand-new prereleases with assets still fail on immutable-release repositories because the action keeps them published by default.
  - Seeded draft releases still work on immutable-release repositories when they are published after upload.
  - Current GitHub release workflows observe both `prereleased` and `published` for mutable prerelease creation.
  - GitHub's documented draft-prerelease path emits `published` rather than preserving a `prereleased`-only contract when the prerelease is published from a draft.
- Why the attempted draft-first prerelease implementation was not kept:
  - experimental upstream ref `462b2120fceb6ce294bbe4aae610b205578cb545` made immutable prerelease uploads succeed
  - the same ref changed the downstream event contract by publishing from a draft, which GitHub surfaced through `published`
  - because that event shift is platform-controlled, the final `2.6.0` branch kept current prerelease semantics and switched to clearer docs and a clearer immutable-release error instead of a silent contract change
- Final upstream change now covers:
  - a more actionable immutable-release upload error for prerelease asset uploads
  - README and `action.yml` clarification for immutable prerelease usage with `draft: true`
- Harness coverage added in this repo:
  - `TESTS.md` now captures the major user-facing regression scenarios for future release trains
  - `.github/workflows/repro-draft-false.yml` now supports both:
    - mutable success verification with `expected_release_outcome: success`
    - immutable prerelease limitation verification with `expected_release_outcome: failure`
  - `AGENTS.md` now points future maintainers at `TESTS.md` and the immutable-release workflow expectations
- Regression evidence against `fadef12636129a8719d57afbbb21e49964dbb22a`:
  - immutable prerelease limitation, expected failure:
    `https://github.com/ruitest2/action-gh-release-test/actions/runs/23116148551`
  - immutable seeded draft reuse and publish:
    `https://github.com/ruitest2/action-gh-release-test/actions/runs/23116148548`
  - mutable prerelease `draft: false` success:
    `https://github.com/ruitest2/action-gh-release-test/actions/runs/23116163991`
  - mutable prerelease observers:
    `https://github.com/ruitest2/action-gh-release-test/actions/runs/23116186045`
  - observer workflow runs from the mutable prerelease check:
    - `observe-prereleased`: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23116188001`
    - `observe-published`: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23116188071`
- Notable upstream log evidence:
  the immutable failure-mode run now surfaces:
  `Cannot upload asset draft-false.txt to an immutable release. GitHub only allows asset uploads before a release is published, but draft prereleases publish with the release.published event instead of release.prereleased.`

## Current Status

- Journal created on 2026-03-15.
- The renamed-asset concurrent-upload fix is merged on upstream `master`.
- The `working_directory` docs sync is merged on upstream `master`.
- The `dist/index.js` freshness guard is merged on upstream `master`.
- Immutable-release verification is complete enough for maintainer review.
- No further `2.6.0` runtime candidates are active in this journal after the immutable prerelease clarification branch.
