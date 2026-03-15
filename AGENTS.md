# action-gh-release-test

This repository exists to regression-test changes in `https://github.com/softprops/action-gh-release/`.
Treat it as a minimal consumer repo that verifies release creation and asset upload behavior from the outside.

## Guardrails

- Keep the workflow intentionally small and focused on end-to-end release behavior.
- When testing a specific upstream PR or commit, pin `.github/workflows/e2e.yml` to the exact `softprops/action-gh-release` ref under test instead of relying on `master`.
- Prefer disposable branches and unique tags for each regression run so the resulting workflow runs and releases are easy to trace.
- Keep `test-assets/` stable unless a regression case explicitly requires different fixtures.
- Do not turn this into a general development repo; it is a harness for validating upstream `action-gh-release` changes.

## Regression Workflow Map

- Use `workflow_dispatch` on `main` and pass the exact upstream `action_repository` and `action_ref` under test.
- If the upstream changes only exist locally in `/Users/rchen/softprops/action-gh-release`, push them to a branch or fork first; this repo's workflows check out a remote ref.
- Start with `docs/action-gh-release-2.5.0-regression-journal.md` when you need the current evidence set, merge order, or known harness limitations for the 2.5.0 bug cluster.
  After `v2.5.1`, treat that journal as the running plan for the next bug-fix round as well; it records which regressions were fixed in `2.5.1` and which open bugs remain.
- Keep the default `e2e.yml` for simple tag-based smoke testing of release creation and asset upload.
- Use `.github/workflows/repro-make-latest.yml` for the `make_latest: false` regression and fix verification (`#703`, PR `#715`).
- Use `.github/workflows/repro-assets-output.yml` for invalid `assets` output URLs and fix verification (`#713`, PR `#738`).
- Use `.github/workflows/repro-race.yml` for concurrent same-tag creation races (`#705`) and related duplicate-release checks.
- Use `.github/workflows/repro-finalize-race.yml` for the draft-finalization retry path (`#704`, `#709`).
  Re-run both against current upstream `master` before opening a race-fix PR so the journal reflects which race still reproduces after the latest merged fixes.
- Use `.github/workflows/trigger-prerelease.yml` together with `.github/workflows/observe-prereleased.yml` and `.github/workflows/observe-published.yml` for prerelease event behavior (`#708`).
  Configure an `ACTION_GH_RELEASE_TRIGGER_TOKEN` repo secret first; release workflows triggered with the default `GITHUB_TOKEN` are suppressed by GitHub and will not exercise the observer workflows.
- Use `.github/workflows/repro-dotfile.yml` for dotfile asset-name behavior (`#741`).
- Use `.github/workflows/repro-duplicate-asset.yml` for same-filename concurrent upload behavior (`#740`).
- Use `.github/workflows/repro-windows.yml` for Windows-runner regressions (`#729`); treat it as an attempted reproduction unless the workflow actually fails with the reported credential error.
- Use `.github/workflows/repro-blocked-tag.yml` for blocked-tag finalization and orphan-draft cleanup behavior (`#722`).
  Configure `ACTION_GH_RELEASE_TRIGGER_TOKEN` first; the workflow creates and removes a temporary tag ruleset in the target repository.
- Use `.github/workflows/repro-preserve-order.yml` for asset ordering behavior with `preserve_order: true` (`#645`).
- Use `.github/workflows/repro-append-body.yml` for existing-release update and `append_body` behavior (`#613`, `#216`, `#238`).
- Use `.github/workflows/repro-brace-glob.yml` for brace/comma glob parsing (`#611`, `#204`).
- Use `.github/workflows/repro-remote-repo.yml` for remote-repository release creation and asset upload (`#639`, `#308`).
  Configure `ACTION_GH_RELEASE_TRIGGER_TOKEN` first; the workflow targets a separate repository and cleans up the test release after inspection.
- Use `.github/workflows/repro-token-precedence.yml` for remote-repository token precedence (`#639`).
  Configure `ACTION_GH_RELEASE_TRIGGER_TOKEN` first; the workflow intentionally sets `GITHUB_TOKEN` and expects the explicit `token` input to win.
- Use `.github/workflows/repro-empty-token.yml` only to confirm docs/usage behavior for empty-string token handling (`#541`).
  Do not keep `#541` in the active bug-fix bucket unless the workflow shows a distinct runtime defect beyond the documented `token: ""` semantics.
- Use `.github/workflows/repro-unicode-asset.yml` for Unicode and special-character asset naming (`#542`, likely related to `#393`).

## Done Criteria

- When making changes in `https://github.com/softprops/action-gh-release/`, run the relevant regression workflows here against the exact upstream ref before merging.
- Capture the resulting Actions run URLs, release URLs, and any notable tag names in the final work summary so there is external consumer-repo evidence for the upstream change.
