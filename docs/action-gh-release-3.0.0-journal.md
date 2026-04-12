# action-gh-release 3.0.0 Node 24 Rebase and Release Plan

Date: 2026-04-12

This repository is the consumer-side regression harness for `softprops/action-gh-release`.
This journal records the planned `3.0.0` work before upstream code changes begin so the
runtime upgrade, release prep, and external validation stay scoped and reviewable.

## Purpose

- Rebase the upstream work for `copilot/fix-8cc96c9f-14fa-4c73-89d2-a72cbdcbee20` onto the latest upstream `master`.
- Carry the action runtime from `node20` to `node24` without regressing release creation, asset upload, or finalize behavior.
- Prepare the first `3.x` release train with explicit contract updates, tag movement rules, and external harness proof.

## Current Upstream Starting Point

- Upstream `origin/master` is currently on `2.6.2`.
- `origin/master` already moved the bundle pipeline from `ncc` to `esbuild`, but `action.yml` still declares `runs.using: node20` and the build scripts still target `node20`.
- The Copilot branch currently carries three branch-only commits on top of an older base:
  - initial planning
  - move the action runtime to `node24` and require `Node >=24`
  - bump `@types/node`, relax Dependabot ignores, and rebuild `dist`
- That branch is materially behind current upstream `master`, so the safe plan is to reapply the runtime upgrade on top of the current `master` shape instead of trying to preserve the old bundle/layout assumptions.

## Why This Is a `3.0.0`

- Changing `runs.using` from `node20` to `node24` changes the minimum GitHub Actions runtime expected by the action.
- Consumers pinned to older GitHub Enterprise Server versions, older self-hosted runner images, or older compatibility assumptions may not be able to adopt the new runtime without prep work.
- The version bump should therefore communicate a deliberate major compatibility boundary, not look like a routine patch release.

## Planned Upstream Change Scope

### 1. Rebase and port the runtime upgrade

- Start from fresh upstream `master`.
- Reapply the Node 24 runtime change as a narrow behavior update, not as a restore of the old branch layout.
- Keep the current `esbuild` pipeline and retarget it for Node 24 rather than reintroducing old `ncc`-based build behavior.
- Keep the current release logic from `master`, including the asset upload and finalize-path fixes already merged since the old branch point.

### 2. Update the external contract

- Update `action.yml` to `runs.using: node24`.
- Update `package.json` build targets to Node 24 and keep the bundle format aligned with current `master`.
- Set the package version to `3.0.0` during release prep, not during the initial runtime-port commit.
- Add or refresh README guidance so users can see that `3.x` requires the Node 24 GitHub Actions runtime.
- Add a top-of-file `CHANGELOG.md` entry that explains the major-runtime change in user terms instead of burying it under dependency noise.

### 3. Update release mechanics for the new major line

- Do not repoint the floating `v2` tag. It should remain on the latest released `2.x` line.
- Prepare a `v3` floating tag workflow for the `3.0.0` release.
- Update `package.json` helper scripts and `RELEASE.md` instructions so the current-major tag operation moves `v3`, not `v2`.
- Keep the full release tag as `v3.0.0`.

## Local Verification Plan In The Upstream Repo

Run the standard upstream verification set after the rebase and again after release-prep edits:

- `npm run fmtcheck`
- `npm run typecheck`
- `npm run build`
- `npm test`

Verification notes:

- Confirm `dist/index.js` is regenerated from the rebased source and current build toolchain.
- Confirm the final bundle target and action metadata both reflect Node 24.
- Keep README, `action.yml`, tests, and `dist/index.js` aligned before treating the branch as release-ready.

## Required External Harness Coverage

Run these workflows from this repository's `main` branch against the exact upstream ref under test.
Keep the default released baseline on `v2.6.1` until `3.0.0` is actually released.

### Minimum gating suite

- `.github/workflows/e2e.yml`
  - exact-ref smoke for basic release creation and asset upload
- `.github/workflows/repro-assets-output.yml`
  - Linux outputs contract: `assets`, `url`, `id`, `upload_url`
- `.github/workflows/repro-assets-output-windows.yml`
  - Windows outputs smoke for `assets`
- `.github/workflows/repro-existing-draft.yml`
  - run with `draft_mode: publish` to cover seeded-draft reuse plus finalization
- `.github/workflows/repro-release-discussion.yml`
  - keep finalize-path discussion creation covered because finalize regressions have already occurred in this project
- `.github/workflows/repro-race.yml`
  - concurrent same-tag create path
- `.github/workflows/repro-finalize-race.yml`
  - draft-finalization retry path
- `.github/workflows/repro-windows.yml`
  - Windows runner path and release behavior smoke

### Run-if-touched suite

If the rebase or release-prep work changes these surfaces, add the matching verifier before release:

- `.github/workflows/repro-previous-tag-release-notes.yml` if release-notes or changelog-generation behavior changes
- `.github/workflows/repro-make-latest.yml` if `make_latest` handling changes
- `.github/workflows/repro-remote-repo.yml` and `.github/workflows/repro-token-precedence.yml` if token or remote-repo behavior changes
- `.github/workflows/repro-home-tilde.yml` and `.github/workflows/repro-windows-glob.yml` if path or file-resolution logic changes

## Evidence To Capture

Before calling the upstream branch ready, capture:

- exact upstream branch name and head commit
- Actions run URLs for each required harness workflow
- resulting release URLs from the exact-ref runs
- any notable temporary tags created during the validation run

This evidence should be recorded in the final upstream work summary and, if needed, appended to this journal after execution.

## Release-Prep Sequence After The Runtime Port Is Green

1. Rebase or replay the Node 24 runtime change onto current upstream `master`.
2. Land the smallest code and contract update needed for the runtime upgrade.
3. Run the full upstream local verification set.
4. Run the required exact-ref harness workflows from this repo and collect run URLs.
5. If the branch is green, prepare the release commit:
   - bump version to `3.0.0`
   - add the `3.0.0` changelog entry
   - refresh `package-lock.json`
   - update release-tag helper instructions for `v3`
6. Re-run the local verification set after release-prep edits.
7. If the release-prep commit changes behavior-relevant files, rerun the exact-ref harness smoke set against the release-prep ref.
8. Only after those checks pass should the upstream repo create `v3.0.0` and move the floating `v3` tag.

## Exit Criteria

- The upstream branch is based on current upstream `master`.
- The Node 24 runtime change is implemented on top of the current `esbuild` layout.
- README, `action.yml`, `CHANGELOG.md`, tests, and `dist/index.js` reflect the final contract.
- The exact-ref harness suite above is green and the run URLs are captured.
- The `3.0.0` release plan preserves `v2` and introduces `v3` as the new floating major tag.
