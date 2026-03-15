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
  - `.github/workflows/repro-blocked-tag.yml`
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
- `#729` still does not reproduce in remote-repository Windows testing on current `master`
  - repro refresh: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100750572`
  - tag used: `v729.23100750572.11`
  - release repository: `chenrui333/action-gh-release`
  - outcome: the workflow succeeded on Windows with a PAT-backed remote `repository:` target, so this harness still does not hit the reported `Bad credentials` failure
- `#722` orphaned draft release when tag creation is blocked reproduces on current `master`
  - repro refresh: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100875487`
  - tag used: `v722.23100875487.1`
  - release repository: `chenrui333/action-gh-release`
  - action evidence: the action created draft release `297099280`, uploaded `blocked-tag.txt`, then failed finalization three times with `pre_receive Repository rule violations found` and `Published releases must have a valid tag`
  - harness evidence: `getReleaseByTag` did not see the orphan draft, but `listReleases` found it and the harness cleanup removed both the draft release and the temporary ruleset after summarizing the run

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
The recent 2.5.x regression cluster is merged into current `master`.

The next open bug-fix candidates are:

- `#722` orphaned draft release when tag creation is blocked by repo rules
- `#729` Windows x64 remote-repository release lookup failure, which still does not reproduce in this harness

Fresh `v2.5.1` baselines for the next bug-fix round:

- `#740` reproduces on current `master`
  - repro refresh: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100479521`
  - tag used: `v740.23100479521.1`
  - observed worker outcomes:
    - uploader 1: `success`
    - uploader 2: `failure`
  - worker evidence: uploader 2 aborted during the upload step with `Not Found - https://docs.github.com/rest/releases/assets#update-a-release-asset`
  - resulting release state: `https://github.com/ruitest2/action-gh-release-test/releases/tag/v740.23100479521.1`
  - outcome: the published release ended with zero assets
- `#708` reproduces on current `master` once the harness uses a PAT-backed trigger token
  - repro: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100150348`
  - tag used: `v708.23100150348.1-rc.1`
  - observed downstream runs:
    - no `observe-prereleased` run
    - `observe-published`: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100153414`
  - implication: current `master` still misses the `prereleased` event even though the release is published as a prerelease
- `#741` reproduces on current `master`
  - repro: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100306812`
  - tag used: `v741.23100306812.11`
  - outcome: the workflow failed when the expected displayed name was `.config`
  - observed asset record: raw name `default.config`, empty label

Recommended scope for the next bug-fix pass:

1. Keep `.github/workflows/repro-duplicate-asset.yml` as the regression guard for `#740`
2. Keep `.github/workflows/repro-blocked-tag.yml` as the regression guard for `#722`
3. Prepare the next fix PR for `#722`
4. Revisit `#729` only if new evidence narrows the Windows-specific credential failure

## Active Fix Candidates

- PR `#750` `fix: clean up orphan drafts when tag creation is blocked`
  - merge target: `https://github.com/softprops/action-gh-release/pull/750`
  - upstream build: `https://github.com/softprops/action-gh-release/actions/runs/23100954970`
  - verify: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100959572`
  - tag used: `v722.23100959572.1`
  - release repository: `chenrui333/action-gh-release`
  - observed action failure: `Tag creation for v722.23100959572.1 is blocked by repository rules. Deleted draft release 297099915 to avoid leaving an orphaned draft release.`
  - cleanup verification: no release and no temporary ruleset remained in `chenrui333/action-gh-release` after the run
  - interpretation: the fix keeps the step failing for blocked tag creation, but it now cleans up the orphan draft instead of leaving a hidden draft release behind
- PR `#746` `fix: canonicalize releases after concurrent create` is merged into `master`
  - merge target: `https://github.com/softprops/action-gh-release/pull/746`
  - verify: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23099930957`
  - tag used: `v709.23099930957.1`
  - outcome: exactly one published release remained for the tag and it contains all four assets:
    - `asset-1.txt`
    - `asset-2.txt`
    - `asset-3.txt`
    - `asset-4.txt`
  - release id: `297093126`
  - interpretation: `#705` is fixed on current `master`; the next bug-fix round should not reopen that path unless a regression appears
- PR `#748` `fix: preserve prereleased events for prereleases` is merged into `master`
  - merge target: `https://github.com/softprops/action-gh-release/pull/748`
  - verify: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100224144`
  - tag used: `v708.23100224144.1-rc.1`
  - observed downstream runs:
    - `observe-prereleased`: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100226375`
    - `observe-published`: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100226358`
  - interpretation: `#708` is fixed on current `master`; the next bug-fix round should move to `#741`
- PR `#749` `fix: restore dotfile asset labels` is merged into `master`
  - merge target: `https://github.com/softprops/action-gh-release/pull/749`
  - verify: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100387469`
  - tag used: `v741.23100387469.11`
  - observed asset record:
    - raw name: `default.config`
    - label: `.config`
  - interpretation: current `master` restores the displayed dotfile name while preserving GitHub's normalized raw asset name
- PR `#745` `fix: handle upload already_exists races across workflows` is merged into `master`
  - merge target: `https://github.com/softprops/action-gh-release/pull/745`
  - upstream build: `https://github.com/softprops/action-gh-release/actions/runs/23100595292`
  - verify: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23100613403`
  - tag used: `v740.23100613403.1`
  - observed worker outcomes:
    - uploader 1: `success`
    - uploader 2: `success`
  - resulting release state: `https://github.com/ruitest2/action-gh-release-test/releases/tag/v740.23100613403.1`
  - observed release asset list:
    - `shared.txt`
  - interpretation: current `master` fixes the same-filename concurrent upload race on top of the `#746` canonicalization changes

## Next Execution Order

1. Keep `.github/workflows/repro-dotfile.yml` as the fixed regression guard for `#741`
2. Keep `.github/workflows/repro-duplicate-asset.yml` as the fixed regression guard for `#740`
3. Keep `.github/workflows/repro-blocked-tag.yml` as the active repro for `#722`
4. Keep labeling any new bug-fix PR `bug`

## 2.5.3 Candidate Sweep

The next historical bug sweep should use this repo to separate still-reproducible issues from issues that are already covered by shipped fixes.
If a case still reproduces on current `master`, keep it in the `2.5.3` bucket. If it does not reproduce, record the evidence and leave it out of the bucket.

Planned workflow-to-issue mapping:

- `.github/workflows/repro-preserve-order.yml` for `#645`
- `.github/workflows/repro-append-body.yml` for `#613`, `#216`, `#238`
- `.github/workflows/repro-brace-glob.yml` for `#611`, `#204` and likely related unmatched-pattern parsing reports such as `#614` and `#280`
- `.github/workflows/repro-remote-repo.yml` for `#639`, `#308`
- `.github/workflows/repro-race.yml` plus `.github/workflows/repro-finalize-race.yml` as historical evidence for older duplicate-release/update bugs such as `#571`, `#445`, `#375`, `#215`, and `#140`
- `.github/workflows/repro-assets-output.yml` as historical evidence for `#222`
- `.github/workflows/repro-token-precedence.yml` for explicit `GITHUB_TOKEN` vs `token` input precedence (`#639`)
- `.github/workflows/repro-empty-token.yml` for empty-string token passthrough (`#541`)
- `.github/workflows/repro-unicode-asset.yml` for Unicode and special-character asset naming collisions (`#542`, likely related to `#393`)

Current `master` sweep results against `softprops/action-gh-release@b25b93d384199fc0fc8c2e126b2d937a0cbeb2ae`:

- `#645` still reproduces. `.github/workflows/repro-preserve-order.yml` failed on `23101335889` because the final asset order did not match the input order even with `preserve_order: true`.
- `#613`, `#216`, and `#238` did not reproduce. `.github/workflows/repro-append-body.yml` passed on `23101335888`.
- `#611` and `#204` did not reproduce. `.github/workflows/repro-brace-glob.yml` passed on `23101335887`.
- The simple remote-repository path did not reproduce. `.github/workflows/repro-remote-repo.yml` passed on `23101335895`, so a straightforward `repository` + explicit `token` release still works.
- `#571` still reproduces on the seeded-draft path. `.github/workflows/repro-finalize-race.yml` failed on `23101359678` because it left five releases for the same tag: one published release with all four assets plus four orphan drafts. The plain concurrent update path in `.github/workflows/repro-race.yml` passed on `23101359675`, so the remaining bug is specifically the finalize/seeded-draft branch rather than the general shared-tag upload path.
- `#639` still reproduces when both `GITHUB_TOKEN` and an explicit `token` input are present. `.github/workflows/repro-token-precedence.yml` failed on `23101424352` with `Resource not accessible by integration`; the explicit PAT did not win over `GITHUB_TOKEN`.
- `#541` still reproduces. `.github/workflows/repro-empty-token.yml` failed on `23101424341`, so an empty-string `token` input still does not fall back to the default token path.
- `#542` still reproduces. `.github/workflows/repro-unicode-asset.yml` failed on `23101424357` because the uploaded Unicode/special-character assets were renamed or collapsed instead of remaining distinct.

Initial `2.5.3` bug bucket from this sweep:

- `#645`
- `#571`
- `#639`
- `#541`
- `#542`

Planned fix order after the `2.5.2` sweep:

1. `#639` token precedence
2. `#571` seeded finalize/orphan-draft race
3. `#541` empty-string token passthrough
4. `#645` preserve-order output and asset ordering
5. `#542` Unicode and special-character asset naming, with `#393` checked alongside it

Expected workflow for each fix:

1. Implement the code change in `softprops/action-gh-release`
2. Open a draft PR
3. Verify the fix in this repo against the PR head
4. Label the PR `bug`
5. Final human check and merge only after the repro workflow passes

Verification notes:

- PR `#751` (`chenrui333:token-selection-fix`, head `2654943c5bcc2249ea0a89eee11ac2b55040ddb8`) fixes the explicit-token precedence path for `#639` and has been merged.
  `.github/workflows/repro-token-precedence.yml` passed on `23101560200`, and upstream `build` passed on `23101555026`.
- PR `#752` clarifies the token precedence docs in `action.yml` and `README.md`; it does not change runtime behavior.
- `#541` is still open after the `#751` merge.
  `.github/workflows/repro-empty-token.yml` still failed on `23101560199` with `Parameter token or opts.auth is required`, so the empty-string token case needs its own follow-up.
- PR `#753` (`chenrui333:finalize-draft-cleanup`, head `668685d61516413a52c2e3c11ed15fd50bb57f14`) folds the duplicate-draft cleanup path into one helper and is ready for final human review.
  `.github/workflows/repro-finalize-race.yml` passed on `23101838821`; the enabled workers all reported `success`, and tag `v709final.23101838821.1` ended with one published release (`297105698`) containing `finalize-asset-1.txt` through `finalize-asset-4.txt`.
  `.github/workflows/repro-race.yml` also passed on `23101838828` as a non-regression check for `#705`; the enabled workers all reported `success`, and tag `v709.23101838828.1` ended with one published release (`297105765`) containing `asset-1.txt` through `asset-4.txt`.
  Upstream `build` passed on `23101833668`.

## Version Recommendation

If the next release only contains the remaining regression fixes and related test/docs work, use `2.5.3`.

Use `2.6.0` only if the release intentionally includes new feature work such as `#732` or other additive behavior beyond the current bug-fix batch.
