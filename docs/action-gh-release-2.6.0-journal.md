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
- Current upstream open work that looks relevant to a small, maintainable `2.6.0` train:
  - `#654` Node 24 runtime upgrade
  - `#698` checked-in `dist/index.js` freshness verification
  - `#641` immutable-release compatibility

## Release-Train Principles

- Prefer narrow, user-facing improvements or maintainer-safety checks over broad refactors.
- Keep GitHub platform limits out of the active bug bucket unless current repro shows an action-side defect.
- Require exact-ref regression evidence from this repo before treating a behavior change as ready.

## Candidate Workstreams

### 1. `#654` Upgrade the action runtime to Node 24

- Type: code quality and compatibility
- Why it matters:
  GitHub-hosted Actions runtimes are moving away from Node 20. This action should stay on a supported runtime without changing its user-facing contract.
- Expected user-facing behavior:
  `softprops/action-gh-release` continues to create, update, and finalize releases exactly as before, but runs on the `node24` Actions runtime without deprecation pressure.
- Proposed regression coverage:
  - Upstream local checks: `npm run fmtcheck`, `npm run typecheck`, `npm run build`, `npm test`
  - Harness smoke: `.github/workflows/e2e.yml` pinned to the exact upstream ref
- Current status:
  Best near-term implementation candidate for `2.6.0`. This is a compatibility upgrade, not a behavior redesign.

### 2. `#698` Add a CI guard that verifies `dist/index.js` stays in sync

- Type: code quality and supply-chain hardening
- Why it matters:
  This action ships checked-in `dist/index.js`. A stale or manually altered bundle is a release risk even when source changes look correct.
- Expected user-facing behavior:
  No runtime behavior change. Maintainers get an automated failure when source and bundled output drift.
- Proposed regression coverage:
  - Upstream CI-only coverage in the main repo
  - No external harness workflow required unless the check changes build semantics
- Current status:
  Good `2.6.0` follow-on after the runtime upgrade because both touch the shipped bundle and maintainer workflow.

### 3. `#641` Verify immutable-release compatibility and only code if current `master` still publishes too early

- Type: feature validation or docs closeout, depending on current behavior
- Why it matters:
  If GitHub Immutable Releases blocks asset mutation after publish, the action must keep the release draft until uploads finish.
- Expected user-facing behavior:
  Asset uploads complete against a draft release, then the action publishes the release once uploads are done.
- Proposed regression coverage:
  - `.github/workflows/e2e.yml` for basic draft-to-publish smoke
  - `.github/workflows/repro-existing-draft.yml` for seeded draft reuse and publish behavior
- Current status:
  Verify before coding. The current action already has explicit draft/finalize flow, so this may be a closeout or docs item rather than new implementation work.

## Not In The Active Runtime Bug Bucket Unless New Evidence Appears

- `#393` and related special-character filename reports:
  keep as platform-limit or docs territory unless current repro shows an action-level defect beyond GitHub filename normalization.
- `#541` empty-string token handling:
  keep as docs or usage clarification unless a new repro shows the action ignoring a valid fallback path.
- `#645` release asset ordering:
  keep as GitHub-controlled display behavior unless the upload order itself is wrong.

## Initial `2.6.0` Execution Order

1. Advance the Node 24 runtime update as the first implementation candidate.
2. Add or refresh the `dist/index.js` freshness guard after the runtime work settles.
3. Re-verify immutable-release compatibility on current upstream before deciding whether `#641` needs code or only documentation.

## Regression Notes

- Keep all harness runs pinned to the exact upstream ref under test.
- Reuse existing focused workflows before inventing new harness scenarios.
- Capture Actions run URLs, tested refs, and release URLs in this journal or its follow-up entries once implementation starts.

## Current Status

- Journal created on 2026-03-15.
- No `2.6.0` implementation has been declared done yet.
- The first concrete implementation candidate is the Node 24 runtime upgrade from `#654`.
