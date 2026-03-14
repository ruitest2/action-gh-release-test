# action-gh-release-test

This repository exists to regression-test changes in `https://github.com/softprops/action-gh-release/`.
Treat it as a minimal consumer repo that verifies release creation and asset upload behavior from the outside.

## Guardrails

- Keep the workflow intentionally small and focused on end-to-end release behavior.
- When testing a specific upstream PR or commit, pin `.github/workflows/e2e.yml` to the exact `softprops/action-gh-release` ref under test instead of relying on `master`.
- Prefer disposable branches and unique tags for each regression run so the resulting workflow runs and releases are easy to trace.
- Keep `test-assets/` stable unless a regression case explicitly requires different fixtures.
- Do not turn this into a general development repo; it is a harness for validating upstream `action-gh-release` changes.
