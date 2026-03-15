# action-gh-release-test

This repository exists to regression-test changes in `https://github.com/softprops/action-gh-release/`.
Treat it as a minimal consumer repo that verifies release creation and asset upload behavior from the outside.

## Guardrails

- Keep the workflow intentionally small and focused on end-to-end release behavior.
- Keep [TESTS.md](TESTS.md) current as the major user-facing regression matrix. Update it whenever a new workflow becomes the primary verifier for a feature surface or release path.
- When testing a specific upstream PR or commit, pin `.github/workflows/e2e.yml` to the exact `softprops/action-gh-release` ref under test instead of relying on `master`.
- Prefer disposable branches and unique tags for each regression run so the resulting workflow runs and releases are easy to trace.
- Keep `test-assets/` stable unless a regression case explicitly requires different fixtures.
- When referring to upstream `softprops/action-gh-release` issues or PRs in this repo's docs, comments, or commit messages, wrap them in backticks like ``#112`` so GitHub does not auto-link them to this test repo's own issue namespace.
- Do not turn this into a general development repo; it is a harness for validating upstream `action-gh-release` changes.

## Regression Workflow Map

- Use `workflow_dispatch` on `main` and pass the exact upstream `action_repository` and `action_ref` under test.
- If the upstream changes only exist locally in `$HOME/softprops/action-gh-release`, push them to a branch or fork first; this repo's workflows check out a remote ref.
- Start with `docs/action-gh-release-2.5.0-regression-journal.md` when you need the current evidence set, merge order, or known harness limitations for the 2.5.0 bug cluster.
  After `v2.5.1`, treat that journal as the running plan for the next bug-fix round as well; it records which regressions were fixed in `2.5.1` and which open bugs remain.
- Keep the default `e2e.yml` for simple tag-based smoke testing of release creation and asset upload.
- Use `.github/workflows/repro-make-latest.yml` for the `make_latest: false` regression and fix verification (`#703`, PR `#715`).
- Use `.github/workflows/repro-assets-output.yml` for invalid `assets` output URLs and fix verification (`#713`, `#222`, PR `#738`).
  Current fixed versions should emit tagged release-asset URLs, so keep the workflow default on `expected_url_kind: tagged` unless you are intentionally reproducing the old broken behavior.
- Use `.github/workflows/repro-race.yml` for concurrent same-tag creation races (`#705`) and related duplicate-release checks such as `#140`, `#146`, `#215`, and `#375`.
- Use `.github/workflows/repro-finalize-race.yml` for the draft-finalization retry path (`#704`, `#709`).
  Re-run both against current upstream `master` before opening a race-fix PR so the journal reflects which race still reproduces after the latest merged fixes.
- Use `.github/workflows/trigger-prerelease.yml` together with `.github/workflows/observe-prereleased.yml` and `.github/workflows/observe-published.yml` for prerelease event behavior (`#708`).
  Configure an `ACTION_GH_RELEASE_TRIGGER_TOKEN` repo secret first; release workflows triggered with the default `GITHUB_TOKEN` are suppressed by GitHub and will not exercise the observer workflows.
- Use `.github/workflows/repro-dotfile.yml` for dotfile asset-name behavior (`#741`).
- Use `.github/workflows/repro-duplicate-asset.yml` for same-filename concurrent upload behavior (`#740`) and renamed-asset race checks.
  The workflow accepts `asset_name` and `expected_display_name`, so reuse it for both plain filenames and GitHub-renamed assets such as `.config`.
- Use `.github/workflows/repro-windows.yml` for Windows-runner regressions (`#729`); treat it as an attempted reproduction unless the workflow actually fails with the reported credential error.
- Use `.github/workflows/repro-blocked-tag.yml` for blocked-tag finalization and orphan-draft cleanup behavior (`#722`).
  Configure `ACTION_GH_RELEASE_TRIGGER_TOKEN` first; the workflow creates and removes a temporary tag ruleset in the target repository.
- Use `.github/workflows/repro-preserve-order.yml` only to confirm docs/usage behavior for `preserve_order` (`#645`).
  Do not keep `#645` in the active bug-fix bucket unless the workflow shows an action-level ordering defect rather than GitHub's own release-asset ordering.
- Use `.github/workflows/repro-append-body.yml` for existing-release update and `append_body` behavior (`#613`, `#216`, `#238`).
- Use `.github/workflows/repro-assets-output-windows.yml` for Windows `outputs.assets` checks (`#222`).
- Use `.github/workflows/repro-brace-glob.yml` for brace/comma glob parsing (`#611`, `#204`).
- Use `.github/workflows/repro-windows-glob.yml` for Windows backslash-heavy file glob behavior (`#280`, `#614`, `#311`).
- Use `.github/workflows/repro-remote-repo.yml` for remote-repository release creation and asset upload (`#639`, `#308`).
  Configure `ACTION_GH_RELEASE_TRIGGER_TOKEN` first; the workflow targets a separate repository and cleans up the test release after inspection.
- Use `.github/workflows/repro-token-precedence.yml` for remote-repository token precedence (`#639`).
  Configure `ACTION_GH_RELEASE_TRIGGER_TOKEN` first; the workflow intentionally sets `GITHUB_TOKEN` and expects the explicit `token` input to win.
- Use `.github/workflows/repro-existing-draft.yml` for existing-draft reuse and draft-state behavior (`#163`, PR `#245`).
  Pass `draft_mode: keep` to verify the release stays draft, or `draft_mode: publish` to verify the seeded draft is reused and then published when `draft` is omitted.
- Use `.github/workflows/repro-draft-false.yml` for `draft: false` behavior when creating prereleases outside a tag-triggered job (`#253`, `#379`).
  For immutable-release verification (`#641`), enable immutable releases on this repo, run `repro-draft-false.yml` with `expected_release_outcome: failure`, and pair it with `repro-existing-draft.yml` in `draft_mode: publish` to confirm the failure is limited to brand-new prereleases. The local maintainer toggle is `gh api -H 'X-GitHub-Api-Version: 2022-11-28' -X PUT repos/ruitest2/action-gh-release-test/immutable-releases` to enable and the matching `-X DELETE` call to disable.
- Use `.github/workflows/repro-omit-name.yml` for omitted-name update behavior against an existing tagged release (`#363`).
- Use `.github/workflows/repro-existing-release-ref-tag.yml` for `tag_name: refs/tags/...` update behavior (`#403`).
- Use `.github/workflows/repro-home-tilde.yml` for home-directory path expansion (`#368`).
- Use `.github/workflows/repro-body-too-long.yml` for large body handling and env-size stress around release notes (`#374`, `#471`).
- Use `.github/workflows/repro-many-files.yml` for large asset-count behavior (`#335`).
- Use `.github/workflows/repro-paren-asset.yml` for parentheses filename handling on Windows (`#393`).
- Use `.github/workflows/repro-target-commitish.yml` for non-latest `target_commitish` release creation (`#411`), and make sure it targets a recent commit that did not modify `.github/workflows/`.
- Use `.github/workflows/repro-dm-asset.yml` for DexMetadata-style `.dm` asset uploads (`#434`).
- Use `.github/workflows/repro-previous-tag-release-notes.yml` for the `previous_tag` / explicit-release-notes-range feature work around PR `#372`.
  This harness seeds two prior releases and only passes if the action-generated release body matches GitHub's `generateReleaseNotes` output for the explicitly requested older `previous_tag`, not the most recent release.
- Use `.github/workflows/repro-empty-token.yml` only to confirm docs/usage behavior for empty-string token handling (`#541`).
  Do not keep `#541` in the active bug-fix bucket unless the workflow shows a distinct runtime defect beyond the documented `token: ""` semantics.
- Use `.github/workflows/repro-unicode-asset.yml` only to confirm docs/usage behavior for Unicode and special-character asset naming (`#542`, likely related to `#393`).
  Do not keep `#542` in the active bug-fix bucket unless the workflow shows an action-level defect beyond GitHub's own filename normalization and label limits.
- When doing historical bug sweeps, stay repro-first.
  Record concrete current evidence in the journal before suggesting a closeout, a docs reclassification, or a reopen candidate.
- Separate historical issues into three buckets in the journal: confirmed non-repro on current upstream, confirmed docs/usage or platform limitations, and still-reproducible current defects.
  Only keep the third bucket as active runtime bugs.
- Do not treat an old close comment as proof that a case is resolved.
  If a closed issue still reproduces on current upstream, capture the current run evidence first and then let the upstream repo decide whether it is worth reopening.

## Done Criteria

- When making changes in `https://github.com/softprops/action-gh-release/`, run the relevant regression workflows here against the exact upstream ref before merging.
- Capture the resulting Actions run URLs, release URLs, and any notable tag names in the final work summary so there is external consumer-repo evidence for the upstream change.
