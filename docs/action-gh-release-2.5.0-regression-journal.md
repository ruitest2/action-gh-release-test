# action-gh-release 2.5.0 Regression Journal

Date: 2026-03-14

This repository is the consumer-side regression harness for `softprops/action-gh-release`.
Use this journal as the current evidence set for the 2.5.0 bug cluster and the related open fix PRs.

## Harness Scope

- Repo under test: `https://github.com/softprops/action-gh-release`
- Harness repo: `https://github.com/ruitest2/action-gh-release-test`
- Workflow entrypoints:
  - `.github/workflows/repro-assets-output.yml`
  - `.github/workflows/repro-make-latest.yml`
  - `.github/workflows/repro-race.yml`
  - `.github/workflows/repro-finalize-race.yml`
  - `.github/workflows/repro-dotfile.yml`
  - `.github/workflows/repro-duplicate-asset.yml`
  - `.github/workflows/repro-windows.yml`
  - `.github/workflows/trigger-prerelease.yml`

## Release Notes Label Mapping

`softprops/action-gh-release/.github/release.yml` currently maps labels like this:

- `bug` -> `Bug fixes 🐛`
- `enhancement`, `feature` -> `Exciting New Features 🎉`
- unlabeled or anything else -> `Other Changes 🔄`

For the currently relevant PRs:

- `#715` should be labeled `bug`
- `#725` should be labeled `bug`
- `#738` should be labeled `bug`
- `#732` should be labeled `enhancement` if it is merged

## Confirmed Findings

### 2.5.0 regressions

- `#713` invalid `assets` output URL reproduced on `v2.5.0`
  - repro: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097825545`
  - control (`v2.4.2`): `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097859814`
  - fix candidate (`#738` branch): `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097825537`
- `#703` / PR `#715` `make_latest: false` regression reproduced on `v2.5.0`
  - repro: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097946267`
  - control (`v2.4.2`): `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097932777`
  - fix candidate (`#715` branch): `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097932786`
- `#704` / `#709` finalize-on-shared-release regression reproduced on `v2.5.0`
  - repro: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23099365202`
  - tag used: `v709final.23099365202.1`
  - worker evidence: worker 1 created a new release instead of finding the seeded draft, then hit `Validation Failed: {"resource":"Release","code":"already_exists","field":"tag_name"}` during finalize and aborted with `Too many retries.`
  - resulting release state: one published release plus four leftover draft/untagged releases for the same logical tag
- current `master` no longer reproduces `#704` / `#709`
  - verify: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23099365201`
  - tag used: `v709final.23099365201.1`
  - outcome: worker 1 found the seeded draft release, the workflow completed successfully, and the single published release contains all four uploaded assets
  - inference: the merged direct `getReleaseByTag` lookup in PR `#725` is the most likely reason current `master` no longer misses the pre-existing draft release

### Older or separate bugs

- `#705` duplicate releases on the same tag predates 2.5.0
  - control run (`v2.4.2`): `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097960706`
  - tag used: `v709.23097960706.1`
  - outcome: duplicate releases were still created, but the 2.5.0 finalize retry failure did not appear
  - current `master` still reproduces the broader duplicate-release race in `.github/workflows/repro-race.yml`
  - verify: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23099281968`
  - tag used: `v709.23099281968.1`
  - outcome: four releases were still created for one tag, but the finalize retry failure did not appear
- `#740` same filename uploaded by concurrent flows reproduced
  - repro: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097970110`
  - tag used: `v740.23097970110.1`
  - outcome: two releases created for one tag, both containing `shared.txt`, plus the retry loop on one uploader
- `#741` dotfile rename reproduced
  - repro: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097970087`
  - tag used: `v741.23097970087.11`
  - actual assets: `default.config`, `vmlinux`
- `#729` Windows credential issue not reproduced in same-repo testing
  - attempt: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23097970083`
  - outcome: Windows created a draft prerelease successfully for `v729.23097970083.11`

## Not Reproducible Here

- `#708` prerelease event regression cannot be validated in this repo without a non-default token
  - reason: releases created with `GITHUB_TOKEN` do not trigger downstream release workflows
  - requirement: configure repo secret `ACTION_GH_RELEASE_TRIGGER_TOKEN` before using `.github/workflows/trigger-prerelease.yml`
- `#724` cannot be reproduced in this harness because it requires a repository with more than 10,000 releases

## Merge Priority

1. Merge `#738`
2. Merge `#715`
3. Fix `#704` / `#709`
4. Revisit the older shared-tag race in `#705` and likely handle `#740` with the same work
5. Keep `#725` queued; it is a real fix but lower urgency because this harness cannot hit the 10k-release condition

## Current Master State

As of 2026-03-14, the following fix PRs are merged into `softprops/action-gh-release/master`:

- `#738` `fix: fetch correct asset URL after finalization; test; some refactoring`
- `#715` `fix: release marked as 'latest' despite make_latest: false`
- `#725` `fix: use getReleaseByTag API instead of iterating all releases`

The dedicated `#704` / `#709` finalize-race regression is no longer reproducible on current `master`.
The remaining confirmed race bug is the older shared-tag duplicate-release path in `#705` (and likely `#740`).

## 2.5.1 Shipped State

`softprops/action-gh-release` released `v2.5.1` on 2026-03-14:

- release: `https://github.com/softprops/action-gh-release/releases/tag/v2.5.1`
- closed after release: `#703`, `#704`, `#709`

That means the next bug-fix round should no longer spend time on the `#704` / `#709` finalize path except as historical regression evidence.
The remaining open bug cluster for the next release is:

- `#705` shared-tag duplicate release race
- `#708` prereleased event regression from the draft-first release flow
- `#741` dotfile asset name regression
- `#742` Node 24 runtime migration

Recommended scope for `2.5.2`:

1. Fix `#705` first and expect that it may also improve `#740`
2. Attempt `#708` only if the harness has `ACTION_GH_RELEASE_TRIGGER_TOKEN` configured; otherwise record it as still blocked in this repo
3. Keep `#741` and `#742` as follow-up work unless they naturally fit after the race fix

## Next Execution Order

1. Re-run `.github/workflows/repro-race.yml` against current `softprops/action-gh-release/master` or `v2.5.1` to keep a fresh baseline for `#705`
2. Attempt `.github/workflows/trigger-prerelease.yml` for `#708`; if the trigger token is still missing, record that the issue remains blocked in this harness
3. Build the next upstream bug-fix PR from current `master`, starting with `#705`
4. Re-run the relevant regression workflows against the fix branch
5. Label any new bug-fix PR `bug`

## Version Recommendation

If the next release only contains the regression fixes and related test/docs work, use `2.5.1`.

Use `2.6.0` only if the release intentionally includes new feature work such as `#732` or other additive behavior beyond the 2.5.0 bug-fix batch.
