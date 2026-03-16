# action-gh-release 2.6.1 Research and Implementation Journal

Date: 2026-03-15

This repository is the consumer-side regression harness for `softprops/action-gh-release`.
This journal starts the `2.6.1` bug-fix train and is intentionally focused on one active runtime regression at a time.

## Purpose

- Track narrow `2.6.1` bug-fix candidates that need external proof before they should ship.
- Record expected user-facing behavior before upstream code changes begin.
- Define the smallest regression coverage needed in this harness so any fix stays reproducible and reviewable.

## Inputs Used

- Current upstream `master` state on 2026-03-15.
- The completed `2.6.0` research and implementation journal in `docs/action-gh-release-2.6.0-journal.md`.
- Current upstream contract and implementation surfaces:
  - `README.md`
  - `action.yml`
  - `src/main.ts`
  - `src/github.ts`
  - `src/util.ts`
  - current tests under `__tests__/`
- Newly reported upstream bug:
  - `#764` discussion threads are no longer generated

## Release-Train Principles

- Prefer narrow bug fixes over structural churn.
- Reproduce on current released upstream before changing behavior.
- Treat GitHub platform semantics separately from action regressions.
- Keep external proof in this repo tied to an exact upstream ref or released version.

## Active 2.6.1 Candidate

### 1. `#764` Discussion threads are no longer generated

- Type: bug fix
- Why it matters:
  Users who set `discussion_category_name` expect the release create path to open the linked discussion thread. If that stops happening, the release contract regresses even though the release itself still succeeds.
- Reported version window:
  - reported good: `v2.4.2`
  - reported broken: `v2.5.0`, `v2.6.0`, and `v2`
- Expected user-facing behavior:
  When `discussion_category_name` is set to an existing category and the workflow has `discussions: write`, the created release should have a linked discussion thread.
- Proposed regression coverage:
  - upstream unit coverage around release creation and finalize behavior
  - a focused harness workflow that can run against an exact upstream ref and assert whether a discussion thread is linked to the created release
  - comparison runs against:
    - last known good `v2.4.2`
    - current released `v2.6.0`
    - exact upstream fix ref under test
- Current status:
  Active. Reproduced on released upstream and confirmed on an exact upstream fix branch.
- Working hypothesis:
  Confirmed. The post-`v2.4.2` draft-first release flow creates the release as a draft, uploads assets, and then publishes it without resending `discussion_category_name`. GitHub still creates the linked discussion when the category is present on the publish/update call, so the regression is action-side, not a platform removal.

## Reproduction and Root Cause

- Harness setup:
  - enabled Discussions on `ruitest2/action-gh-release-test`
  - confirmed default discussion categories via GraphQL, including `Announcements`
- Direct GitHub API proof against `ruitest2/action-gh-release-test`:
  - published create with `discussion_category_name: Announcements` created a linked discussion:
    - release: `https://github.com/ruitest2/action-gh-release-test/releases/tag/vdisc.1773621927.published`
    - discussion: `https://github.com/ruitest2/action-gh-release-test/discussions/1`
  - draft create plus publish **without** `discussion_category_name` did not create a linked discussion:
    - release: `https://github.com/ruitest2/action-gh-release-test/releases/tag/vdisc.1773621927.draft-no-discussion`
  - draft create plus publish **with** `discussion_category_name` created a linked discussion:
    - release: `https://github.com/ruitest2/action-gh-release-test/releases/tag/vdisc.1773621927.draft-with-discussion`
    - discussion: `https://github.com/ruitest2/action-gh-release-test/discussions/2`
- Conclusion:
  the minimal upstream fix is to preserve `discussion_category_name` on the finalize/publish update call.

## Harness Coverage Added

- Added `.github/workflows/repro-release-discussion.yml`
- Purpose:
  create a release with one asset and `discussion_category_name: Announcements`, then assert whether the observed release has a linked `discussion_url`
- Primary matrix role:
  this is now the major external verifier for `discussion_category_name`

## Versioned Reproduction Evidence

- Historical good:
  - ref: `v2.4.2`
  - run: `23123294205`
  - run URL: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23123294205`
  - release: `https://github.com/ruitest2/action-gh-release-test/releases/tag/v764.23123294205.1`
  - observed discussion: `https://github.com/ruitest2/action-gh-release-test/discussions/3`
- Released broken:
  - ref: `v2.6.0`
  - run: `23123296284`
  - run URL: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23123296284`
  - release: `https://github.com/ruitest2/action-gh-release-test/releases/tag/v764.23123296284.1`
  - observed discussion: none

## Fix Verification Evidence

- Exact upstream fix ref:
  - branch: `fix-discussion-thread-regression`
  - commit: `c79d4c6`
- Discussion regression workflow:
  - run: `23123350773`
  - run URL: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23123350773`
  - release: `https://github.com/ruitest2/action-gh-release-test/releases/tag/v764.23123350773.1`
  - observed discussion: `https://github.com/ruitest2/action-gh-release-test/discussions/4`
- Broader smoke:
  - `e2e.yml` exact-ref run:
    - run: `23123350783`
    - run URL: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23123350783`
    - release: `https://github.com/ruitest2/action-gh-release-test/releases/tag/ve2e.23123350783.1`
- Draft reuse/finalize safety check:
  - `repro-existing-draft.yml` with `draft_mode: publish`
    - run: `23123356978`
    - run URL: `https://github.com/ruitest2/action-gh-release-test/actions/runs/23123356978`
    - result: passed; seeded draft was reused and published successfully

## Upstream Change Scope

- Expected upstream code change:
  preserve `discussion_category_name` in the release finalize/update call
- Expected upstream test change:
  unit coverage around `finalizeRelease` and `GitHubReleaser.finalizeRelease`
- README / `action.yml` expectation:
  no contract-doc change needed if the fix only restores the documented existing behavior

## Baseline Update

- On 2026-03-16, after `softprops/action-gh-release` released `v2.6.1`, this harness moved its default released baseline from `v2.6.0` to `v2.6.1`.
- Operational changes:
  - `.github/workflows/e2e.yml` now pins the simple tag-push smoke to `softprops/action-gh-release@v2.6.1`
  - all `workflow_dispatch` repro workflows now default `action_ref` to `v2.6.1`
  - `AGENTS.md` and `TESTS.md` now describe `v2.6.1` as the default released baseline
- Historical evidence for `v2.6.0` remains in this journal because it is still the comparison point for the `#764` regression.
