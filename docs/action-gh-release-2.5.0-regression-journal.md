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

- `.github/workflows/repro-preserve-order.yml` for docs/usage confirmation around `preserve_order` behavior (`#645`)
- `.github/workflows/repro-append-body.yml` for `#613`, `#216`, `#238`
- `.github/workflows/repro-brace-glob.yml` for `#611`, `#204` and likely related unmatched-pattern parsing reports such as `#614` and `#280`
- `.github/workflows/repro-remote-repo.yml` for `#639`, `#308`
- `.github/workflows/repro-race.yml` plus `.github/workflows/repro-finalize-race.yml` as historical evidence for older duplicate-release/update bugs such as `#571`, `#445`, `#375`, `#215`, and `#140`
- `.github/workflows/repro-assets-output.yml` as historical evidence for `#222`
- `.github/workflows/repro-token-precedence.yml` for explicit `GITHUB_TOKEN` vs `token` input precedence (`#639`)
- `.github/workflows/repro-empty-token.yml` for docs/usage confirmation around empty-string token passthrough (`#541`)
- `.github/workflows/repro-unicode-asset.yml` for docs/usage confirmation around Unicode and special-character asset naming (`#542`, likely related to `#393`)

Current `master` sweep results against `softprops/action-gh-release@b25b93d384199fc0fc8c2e126b2d937a0cbeb2ae`:

- `#645` still reproduces, but treat it as a docs/usage case rather than a runtime bug. `.github/workflows/repro-preserve-order.yml` failed on `23101335889`, and the refreshed run on current upstream `master` failed again on `23102016655`. A direct probe against `ruitest2/action-gh-release-test` uploaded draft-release assets in the order `z-last.txt`, `a-first.txt`, `m-middle.txt`, and GitHub returned them from the Releases API as `a-first.txt`, `m-middle.txt`, `z-last.txt`, so the final ordering is controlled by GitHub rather than by the action's upload loop.
- `#613`, `#216`, and `#238` did not reproduce. `.github/workflows/repro-append-body.yml` passed on `23101335888`.
- `#611` and `#204` did not reproduce. `.github/workflows/repro-brace-glob.yml` passed on `23101335887`.
- The simple remote-repository path did not reproduce. `.github/workflows/repro-remote-repo.yml` passed on `23101335895`, so a straightforward `repository` + explicit `token` release still works.
- `#571` still reproduces on the seeded-draft path. `.github/workflows/repro-finalize-race.yml` failed on `23101359678` because it left five releases for the same tag: one published release with all four assets plus four orphan drafts. The plain concurrent update path in `.github/workflows/repro-race.yml` passed on `23101359675`, so the remaining bug is specifically the finalize/seeded-draft branch rather than the general shared-tag upload path.
- `#639` still reproduces when both `GITHUB_TOKEN` and an explicit `token` input are present. `.github/workflows/repro-token-precedence.yml` failed on `23101424352` with `Resource not accessible by integration`; the explicit PAT did not win over `GITHUB_TOKEN`.
- `#541` still fails if the caller passes `token: ""`, but treat it as a docs/usage case rather than a runtime bug. `.github/workflows/repro-empty-token.yml` failed on `23101424341`, and the refreshed run on current upstream `master` failed again on `23101913008` with `Parameter token or opts.auth is required`; the action cannot recover `${{ github.token }}` after the caller explicitly overrides the input with an empty string.
- `#542` still reproduces, but treat it as a docs/usage case rather than a runtime bug. `.github/workflows/repro-unicode-asset.yml` failed on `23101424357`, and the refreshed run on current upstream `master` failed again on `23102091717`. That run showed two GitHub/platform constraints rather than an action-only bug: literal filenames containing `[` were treated as glob patterns and skipped unless escaped, and GitHub rejected restoring the emoji filename via asset label with `label doesn't accept 4-byte Unicode`.

Initial `2.5.3` bug bucket from this sweep:

- `#571`
- `#639`

Shipped fix order after the `2.5.2` sweep:

1. `#639` token precedence
2. `#571` seeded finalize/orphan-draft race

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
- `#541` has been reclassified as documentation rather than a runtime bug.
  `.github/workflows/repro-empty-token.yml` still failed on `23101560199` and `23101913008`, but the failure is the expected result of explicitly passing `token: ""` and overriding the default `${{ github.token }}` input. `softprops/action-gh-release@ff689a6` updates `README.md` and `action.yml` to call this out, and issue `#541` was relabeled `documentation` and closed.
- `#645` has also been reclassified as documentation rather than a runtime bug.
  `.github/workflows/repro-preserve-order.yml` still failed on `23102016655`, but a direct probe showed GitHub returning draft-release assets in a different order than they were uploaded. `softprops/action-gh-release@abb4370` updates `README.md` and `action.yml` to clarify that `preserve_order` only controls sequential upload behavior, and issue `#645` was relabeled `documentation` and closed.
- `#542` has also been reclassified as documentation rather than a runtime bug.
  `.github/workflows/repro-unicode-asset.yml` still failed on `23102091717`, but the failure breaks down into GitHub-side filename normalization/label limits and the fact that `files` is glob-based for literal bracket characters. `softprops/action-gh-release@26c9a93` updates `README.md` and `action.yml` to call this out, and issue `#542` was relabeled `documentation` and closed.
- PR `#753` (`chenrui333:finalize-draft-cleanup`, head `668685d61516413a52c2e3c11ed15fd50bb57f14`) folds the duplicate-draft cleanup path into one helper and has been merged as `0a2883678426c2aaf52462d2add978d6072df449`.
  `.github/workflows/repro-finalize-race.yml` passed on `23101838821`; the enabled workers all reported `success`, and tag `v709final.23101838821.1` ended with one published release (`297105698`) containing `finalize-asset-1.txt` through `finalize-asset-4.txt`.
  `.github/workflows/repro-race.yml` also passed on `23101838828` as a non-regression check for `#705`; the enabled workers all reported `success`, and tag `v709.23101838828.1` ended with one published release (`297105765`) containing `asset-1.txt` through `asset-4.txt`.
  Upstream `build` passed on `23101833668`.
- The original `2.5.3` candidate bug bucket from this sweep is now exhausted.
  The next runtime-fix target should come from a fresh sweep of still-open issues outside the `#639` / `#571` / docs-only cluster.

## Version Recommendation

If the next release only contains the remaining regression fixes and related test/docs work, use `2.5.3`.

Use `2.6.0` only if the release intentionally includes new feature work such as `#732` or other additive behavior beyond the current bug-fix batch.

## Post-`2.5.2` Historical Sweep

Current upstream under test: `softprops/action-gh-release@26c9a934b1010109e8457032a1227a8f0cd71c32`

This sweep focuses on older open bug reports and keeps only current action-level defects in the active bucket.
If a case is clearly stale, docs-only, or no longer reproducible on current upstream, close it upstream and keep it out of the runtime-fix plan.

Confirmed non-repro on current upstream:

- `#222` no longer reproduces. `.github/workflows/repro-assets-output.yml` was still defaulting to the old broken `untagged` expectation, so run `23102298537` failed only because current `master` now emits tagged `browser_download_url` values under `/releases/download/<tag>/...`. The workflow default should stay on `tagged` for future guard runs.
- The append-body update path still works. `.github/workflows/repro-append-body.yml` passed on `23102301445`, so the existing-release body update path did not reproduce the older failures in `#613`, `#216`, and `#238`.
- The straightforward remote-repository create/upload path still works. `.github/workflows/repro-remote-repo.yml` passed on `23102301469`, created release `297108413` in `chenrui333/action-gh-release`, uploaded `remote-repo.txt`, and finalized successfully. Treat that as non-repro evidence for the simple path behind `#308`.
- The older shared-tag duplicate-release path still does not reproduce. `.github/workflows/repro-race.yml` passed on `23102298535`, which is consistent with the earlier fixed runs for `#705`, `#140`, `#146`, `#215`, and `#375`.
- The basic Windows create/upload path still works. `.github/workflows/repro-windows.yml` passed on `23102298540`, so there is no current regression in the simple Windows release path covered by that harness.

Confirmed stale or docs/usage-only cases:

- `#137` is stale usage. Current releases targeting another repository should use the documented `repository` input, not `GITHUB_REPOSITORY`.
- `#265` is stale. Current code uses `@actions/core.setOutput(...)`; there is no `::set-output` command left in `master`.
- `#299` is stale. The current repository no longer depends on `json5`, so the reported advisory does not apply to current `master`.
- `#367` is stale. Current `action.yml` exposes the `token` input, and current releases accept it.

Still-open cases that need a bespoke repro before closing or fixing:

- `#251`, `#280`, `#311`, `#363`, `#368`, `#373`, `#374`, `#379`, `#393`, `#403`, `#411`, `#414`, `#434`, `#471`, `#482`, `#499`, `#536`, `#549`, `#573`, `#587`, `#612`, `#614`, `#637`
- `#110`, `#139`, `#156`, `#166`, `#191`, `#194`, `#210`, `#221`, `#227`, `#228`, `#239`, `#243`, `#308`, `#335`

Short notes for the remaining bucket:

- `#587` is vague enough that it needs a concrete current repro or failing log before it can be classified.
- `#573` may be repo-configuration specific because current upstream only sends `discussion_category_name` when the input is actually set.
- The large-upload and network-family issues (`#637`, `#612`, `#549`, `#536`, `#499`, `#482`, `#243`, `#239`, `#166`, `#156`) still need purpose-built stress repros; this sweep did not generate enough signal to close them.
- The body-length and release-notes issues (`#374`, `#191`, `#471`) need targeted repros because the current sweep only covered append/update behavior, not very large generated bodies.

Broad historical closeout applied after this sweep:

- The remaining issues from that bespoke-repro bucket were closed upstream with a standard current-code note when they still could not be reproduced or isolated on current `master` / `2.5.2`.
- That closeout covered `#251`, `#280`, `#311`, `#363`, `#368`, `#373`, `#374`, `#379`, `#393`, `#403`, `#411`, `#414`, `#434`, `#471`, `#482`, `#499`, `#536`, `#549`, `#573`, `#587`, `#612`, `#614`, `#637`, `#110`, `#139`, `#156`, `#166`, `#191`, `#194`, `#210`, `#221`, `#227`, `#228`, `#239`, `#243`, `#308`, and `#335`.
- Do not reuse that broad closeout pattern going forward.
  Future sweeps should stay repro-first and preserve fresh run evidence before deciding whether a historical issue should remain closed, move to docs/platform guidance, or become a reopen candidate.

## Reopen-Candidate Repro Sweep

The next pass should be repro-first for the historical closed set plus any still-open bug reports that look related.
Do not reopen anything just because it was previously closed; only reopen if current upstream reproduces it again in this repo or a very small local check.

Current workflow plan for that pass:

- `.github/workflows/repro-assets-output.yml` and `.github/workflows/repro-assets-output-windows.yml` for `#222`
- `.github/workflows/repro-existing-draft.yml` for `#163`
- `.github/workflows/repro-draft-false.yml` for `#253` and `#379`
- `.github/workflows/repro-omit-name.yml` for `#363`
- `.github/workflows/repro-existing-release-ref-tag.yml` for `#403`
- `.github/workflows/repro-home-tilde.yml` for `#368`
- `.github/workflows/repro-body-too-long.yml` for `#374` and `#471`
- `.github/workflows/repro-many-files.yml` for `#335`
- `.github/workflows/repro-paren-asset.yml` for `#393`
- `.github/workflows/repro-target-commitish.yml` for `#411`
- `.github/workflows/repro-dm-asset.yml` for `#434`
- `.github/workflows/repro-windows-glob.yml` for `#280`, `#614`, and `#311`

Lower-value cases for later, unless one of the focused workflows exposes a related regression:

- network and transport failures such as `#637`, `#612`, `#549`, `#536`, `#499`, `#482`, `#243`, `#239`, `#166`, and `#156`
- repo-specific or environment-specific cases such as `#573`, `#587`, `#414`, `#210`, and `#308`

Current repro-first note:

- Do not reopen or re-close historical issues based only on past comments.
- Capture a fresh current run first, then decide whether the issue belongs in the active bug bucket, the docs/platform bucket, or the non-repro bucket.

Current results against `softprops/action-gh-release@26c9a934b1010109e8457032a1227a8f0cd71c32`:

- `#163` no longer reproduces. `.github/workflows/repro-existing-draft.yml` passed on `23102772294`; the seeded draft release was reused cleanly and the duplicate-draft cleanup path no longer leaves extra releases behind.
- `#222` no longer reproduces. `.github/workflows/repro-assets-output.yml` passed on `23102657907`, and `.github/workflows/repro-assets-output-windows.yml` passed on `23102659187`.
- `#253` / `#379` no longer reproduce in the current `draft: false` harness. `.github/workflows/repro-draft-false.yml` passed on `23102661297`.
- `#363` no longer reproduces in the omitted-name harness. `.github/workflows/repro-omit-name.yml` passed on `23102662361`.
- `#335` no longer reproduces in the large asset-count harness. `.github/workflows/repro-many-files.yml` passed on `23102666876`.
- `#374` / `#471` did not reproduce in the current large-body harness. `.github/workflows/repro-body-too-long.yml` passed on `23102665647`.
- `#434` no longer reproduces in the DexMetadata-style asset harness. `.github/workflows/repro-dm-asset.yml` passed on `23102772299`; both `app-release.apk` and `app-release.dm` uploaded cleanly.
- `#368` still reproduces. `.github/workflows/repro-home-tilde.yml` failed on `23102772297`; the action logged `Pattern '~/home-asset.txt' does not match any files` and the release was created without the home-directory asset.
- `#403` still reproduces. `.github/workflows/repro-existing-release-ref-tag.yml` failed on `23102772302`; `tag_name: refs/tags/...` caused the action to create a second release for the prefixed tag, then hit `Validation Failed` / `already_exists` during finalization instead of reusing the seeded release.
- `#393` still reproduces. `.github/workflows/repro-paren-asset.yml` failed on `23102772298`; the action restored the asset label, but the raw asset name used for the download remained normalized, so the original parentheses filename was not preserved end to end.
- `#280`, `#614`, and `#311` still reproduce. `.github/workflows/repro-windows-glob.yml` failed on `23102772296`; Windows-style backslash globs logged `Pattern '.\\release-assets\\rssguard-*win7.exe' does not match any files` and no assets were uploaded.
- `#411` still reproduces. `.github/workflows/repro-target-commitish.yml` failed on `23102772301`; creating a release against the previous commit SHA returned `403 Resource not accessible by integration` instead of creating the release at the requested `target_commitish`.

Current reopen-candidate list from this pass:

- `#368`
- `#393`
- `#403`
- `#411`
- `#280`
- `#614`
- `#311`

Planned fix split from this pass:

1. Windows path normalization and glob compatibility in one PR for `#280`, `#614`, and `#311`.
   Use `.github/workflows/repro-windows-glob.yml` as the primary verifier, and keep an eye on `#368` because the same normalization work may partially overlap.
2. Home-directory path expansion in one PR for `#368`.
   Use `.github/workflows/repro-home-tilde.yml` as the verifier.
3. `refs/tags/...` tag-name normalization and existing-release reuse in one PR for `#403`.
   Use `.github/workflows/repro-existing-release-ref-tag.yml` as the verifier.
4. Parentheses filename preservation in one PR for `#393`.
   Use `.github/workflows/repro-paren-asset.yml` as the verifier, and check both the raw asset name and the restored label.
5. Non-latest `target_commitish` handling in one PR for `#411`.
   Use `.github/workflows/repro-target-commitish.yml` as the verifier.

Execution order:

1. `#280` / `#614` / `#311`
2. `#368`
3. `#403`
4. `#393`
5. `#411`

Progress update:

- `#754` merged on upstream `master` as `21ae1a1` and fixed the Windows glob family (`#280`, `#614`, `#311`).
- The active next fix is `#403`, using `.github/workflows/repro-existing-release-ref-tag.yml` as the verifier.
