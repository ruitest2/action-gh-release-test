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
  Active. Repro and root-cause confirmation are still pending.
- Working hypothesis:
  The post-`v2.4.2` draft-first release flow may prevent GitHub from creating the discussion thread during initial release creation, but this remains a hypothesis until the harness repro confirms it.
