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

## Execution Update

### Upstream branch executed

- Exact upstream base used for the rebase: `c2e35e0` (`origin/master`).
- Exact upstream branch under test after execution: `copilot/fix-8cc96c9f-14fa-4c73-89d2-a72cbdcbee20` at `218a0ca`.
- Final branch commit stack:
  - `218a0ca` `release: prepare 3.0.0`
  - `e48d846` `chore: bump @types/node, enable Dependabot updates, rebuild dist`
  - `1fff77c` `feat: move action runtime to node24 and require Node >=24`
- Stale plan assumptions corrected during execution:
  - current upstream `master` already uses `esbuild`; the branch was rebased onto that layout instead of reviving the older `ncc` shape
  - upstream package metadata on `master` was already `2.6.2`, so the release prep had to start from the current metadata rather than the older `2.4.x` branch snapshot
  - `RELEASE.md` already existed and was updated in place for the `v3` release flow

### Branch contents after rebase and release prep

- `action.yml` now declares `runs.using: node24`
- `package.json` build scripts now target Node 24, declare `engines.node >=24`, and bump the package version to `3.0.0`
- `@types/node` now tracks the Node 24 line and Dependabot no longer ignores future `@types/node` updates
- `README.md`, `CHANGELOG.md`, and `RELEASE.md` now document the `3.x` / Node 24 contract and the `v3` floating-tag flow
- `npm run updatetag` now moves `v3` and tolerates the first `v3` creation where the floating tag does not already exist

### Local verification

- Rebased branch verification passed:
  - `npm run fmtcheck`
  - `npm run typecheck`
  - `npm run build`
  - `npm test`
- Release-prep verification passed again after the `3.0.0` metadata and docs updates:
  - `npm run fmtcheck`
  - `npm run typecheck`
  - `npm run build`
  - `npm test`

### Major-flow harness matrix

Every major flow in [TESTS.md](TESTS.md) was exercised from this repo's `main` branch against the exact upstream ref `softprops/action-gh-release@copilot/fix-8cc96c9f-14fa-4c73-89d2-a72cbdcbee20`.

| Flow | Workflow evidence | Result |
| --- | --- | --- |
| Basic release creation and upload | [e2e 24298578300](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298578300) | pass |
| Assets outputs contract | [Linux 24298579264](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298579264), [Windows 24298580547](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298580547) | pass |
| Existing draft reuse | [keep 24298581500](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298581500), [publish 24298582636](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298582636) | pass |
| Release-linked discussion creation | [24298583690](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298583690) | pass |
| Shared-tag races | [repro-race 24298584683](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298584683), [repro-finalize-race 24298585638](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298585638) | pass |
| Windows release path | [repro-windows 24298586527](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298586527), [repro-windows-glob 24298596650](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298596650) | pass |
| Prerelease creation with `draft: false` | [24298587460](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298587460) | pass |
| Prerelease observer behavior | initial sweep [24298588353](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298588353) failed with stale expectations; corrected rerun [24298663088](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298663088) passed with both `observe-prereleased` and `observe-published` expected | pass after expectation correction |
| Existing release update by tag | [append_body 24298589412](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298589412), [refs/tags 24298591132](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298591132), initial omit-name sweep [24298590268](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298590268), isolated rerun [24298680672](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298680672) | pass after isolated omit-name rerun |
| Duplicate-asset concurrent upload | [24298591943](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298591943) | pass |
| Token precedence for remote repo | [24298593684](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298593684) | pass |
| Path resolution and `working_directory` | [home-tilde 24298594575](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298594575), [working-directory 24298595636](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298595636), [brace glob 24298597718](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298597718) | pass |
| Release metadata options | [target_commitish 24298599469](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298599469), [previous_tag 24298600422](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298600422), [body too long 24298601341](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298601341), isolated make-latest rerun [24298679827](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298679827) | pass |
| Asset-count and special-file coverage | [many-files 24298602317](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298602317), [dm asset 24298603247](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298603247), corrected dotfile rerun [24298662230](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298662230) | pass |
| Parentheses filename preservation | [24298604172](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298604172) | known GitHub raw-name normalization limitation; label restored but raw download name still normalized |
| Remote repository release creation | branch run [24298592800](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298592800), current `master` comparison [24298664861](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298664861) | still failing on current upstream; not introduced by the Node 24 branch |

### Triage notes for the non-green first-pass runs

- `repro-make-latest` first failed in the full concurrent sweep because another release-creating workflow updated the repo-wide latest release during the assertion window. The isolated rerun [24298679827](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298679827) passed.
- `repro-dotfile` first failed because the workflow still expected displayed asset name `default.config`. The actual asset record on the branch was raw name `default.config` plus label `.config`, which matches the current fixed behavior. The corrected rerun [24298662230](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298662230) passed.
- `trigger-prerelease` first failed because the workflow still expected `observe-prereleased` to stay idle. Current fixed behavior fires both observer workflows; the corrected rerun [24298663088](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298663088) passed.
- `repro-omit-name` failed once in the large concurrent sweep but passed both in the isolated branch rerun [24298680672](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298680672) and in the current-`master` comparison [24298663999](https://github.com/ruitest2/action-gh-release-test/actions/runs/24298663999). Treat the first failure as sweep noise, not a persistent regression.
- `repro-paren-asset` remains consistent with the documented GitHub normalization limitation for raw asset names. The branch restored the label `appName(x64)_1.0.0.1.msi`, but GitHub still stored the raw asset name as `appName.x64._1.0.0.1.msi`.
- `repro-remote-repo` failed on both the Node 24 branch and current upstream `master`. In both runs, the action created a remote release object and finished with an `untagged-...` release URL instead of making the requested tag discoverable in the remote repository. This remains a current-upstream follow-up item, not a regression introduced by the `3.0.0` branch.

### Execution verdict

- The Node 24 `3.0.0` branch is rebased onto current upstream `master`, locally green, and externally exercised across every major harness flow.
- After correcting harness expectation drift and rerunning the noisy cases in isolation, the exact-ref branch coverage is green across the major release, update, draft, prerelease, race, Windows, path-resolution, metadata, and asset-shape flows.
- Remaining non-green follow-ups are outside the scope of the Node 24 branch itself:
  - remote-repo release creation is still failing on current upstream `master`
  - parentheses filename preservation still reflects GitHub's raw asset-name normalization rather than an action-side fix regression
