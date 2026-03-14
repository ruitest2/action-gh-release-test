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
- Keep the default `e2e.yml` for simple tag-based smoke testing of release creation and asset upload.
- Use `.github/workflows/repro-make-latest.yml` for the `make_latest: false` regression and fix verification (`#703`, PR `#715`).
- Use `.github/workflows/repro-assets-output.yml` for invalid `assets` output URLs and fix verification (`#713`, PR `#738`).
- Use `.github/workflows/repro-race.yml` for parallel upload/finalization races (`#704`, `#705`, `#709`).
- Use `.github/workflows/trigger-prerelease.yml` together with `.github/workflows/observe-prereleased.yml` and `.github/workflows/observe-published.yml` for prerelease event behavior (`#708`).
- Use `.github/workflows/repro-dotfile.yml` for dotfile asset-name behavior (`#741`).
- Use `.github/workflows/repro-duplicate-asset.yml` for same-filename concurrent upload behavior (`#740`).
- Use `.github/workflows/repro-windows.yml` for Windows-runner regressions (`#729`); treat it as an attempted reproduction unless the workflow actually fails with the reported credential error.

## Done Criteria

- When making changes in `https://github.com/softprops/action-gh-release/`, run the relevant regression workflows here against the exact upstream ref before merging.
- Capture the resulting Actions run URLs, release URLs, and any notable tag names in the final work summary so there is external consumer-repo evidence for the upstream change.
