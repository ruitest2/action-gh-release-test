# action-gh-release 3.0.4 Release-Gate Regression

Pre-release consumer regression for the next `3.0.x` patch release, run on 2026-11-05 from this repository's `main` branch.

## Ref Under Test

- Exact upstream ref: `softprops/action-gh-release@ac0115469478f6d234bc639fb400df76407ebac1` (`master`, after `#864`).
- Comparison baseline: released `v3.0.3`.
- No `src/` or `action.yml` changes since `v3.0.3`. Runtime dependency changes bundled into `dist/index.js`:
  - `glob` 13.0.6 to 14.0.3, `minimatch` 10.2.4 to 11.0.4, `path-scurry` 2.0.2 to 3.0.0, `brace-expansion` 5.0.9 to 5.0.12 (file matching)
  - `undici` 6.28.0 to 6.29.1 (HTTP transport)
- Immutable releases were disabled on this repository for the whole sweep.

## Result

No regression against `v3.0.3`. Every flow with a fixed-behavior expectation passed on the exact ref; every remaining failure fails identically on `v3.0.3` and is either a documented platform limitation or a harness defect fixed alongside this journal.

### Passing flows on the exact ref

| Flow | Workflow evidence |
| --- | --- |
| Basic release creation and upload | [42040990668](https://github.com/ruitest2/action-gh-release-test/actions/runs/42040990668) |
| Assets outputs contract | [Linux](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041005519), [Windows](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041019947) |
| Existing draft reuse | [keep](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041040432), [publish](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041055086) |
| Release-linked discussion (`expected_discussion: present`) | [42041078788](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041078788) |
| Shared-tag races | [race](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041093744), [finalize-race](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041117477) |
| Windows release path and globbing | [windows](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041139672), [windows-glob](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041153436) |
| Path resolution and brace globs | [home-tilde](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041193798), [working-directory](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041207997), [brace-glob](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041173911) |
| Prerelease and draft transitions (`run_case: all`) | [42041228428](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041228428) |
| Prerelease observers (both `present`) | [42041248772](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041248772) |
| Existing release update by tag | [append_body](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041269716), [refs/tags](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041290725), [omit-name (isolated)](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042567925) |
| Duplicate and dotfile assets | [duplicate-asset](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041305258), [dotfile `.config`](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041327389) |
| Remote repository targeting | [ubuntu](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041363448), [windows](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041378206), [token-precedence (live target)](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042094515) |
| Release metadata | [body-too-long](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041436178), [make-latest (isolated, `previous`)](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042660722) |
| Asset-count and special files | [many-files](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041450348), [dm-asset](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041463938) |
| Blocked-tag cleanup diagnostics | [42041566928](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041566928) |
| Gitea asset overwrite (`#803`) | [1.24.7](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041591937), [1.26.4](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041607573) |

The glob and path verifiers (`repro-brace-glob`, `repro-windows-glob`, `repro-home-tilde`, `repro-windows`, `repro-dotfile`, `repro-many-files`) are the primary consumer evidence for the `glob` 14 / `minimatch` 11 bump.

### Documented platform limitations (identical on `v3.0.3`)

| Workflow | Evidence | Observation |
| --- | --- | --- |
| `repro-paren-asset` (`#393`) | [master](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041484118), [v3.0.3](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041845684) | label `appName(x64)_1.0.0.1.msi` restored; GitHub stores raw name `appName.x64._1.0.0.1.msi` |
| `repro-unicode-asset` (`#542`) | [master](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041504546), [v3.0.3](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041867628) | GitHub renames or collapses Unicode asset names |
| `repro-preserve-order` (`#645`) | [master](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041524649), [v3.0.3](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041887513) | GitHub's release asset order does not follow upload order |
| `repro-empty-token` (`#541`) | [master](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041545753), [v3.0.3](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041902599) | `token: ""` fails with `Parameter token or opts.auth is required`; documented semantics |

### Harness defects found and fixed

| Workflow | Evidence | Cause | Fix |
| --- | --- | --- | --- |
| `repro-token-precedence` | [master](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041341548), [v3.0.3](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041801963), fixed-target rerun [42042094515](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042094515) | default `release_repository` `chenrui333/action-gh-release` no longer exists (404) | default to `ruitest2/action-gh-release-target-no-discussions` |
| `repro-target-commitish` | [master](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041392396), [v3.0.3](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041814403), fixed branch run [42042329589](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042329589) | `GITHUB_TOKEN` gets 403 creating a tag on a commit whose `.github/workflows/` tree differs from `HEAD`; harness PRs since July changed workflows in every recent commit, so the old "commit did not touch workflows" filter now selects such a commit | select commits whose workflow tree equals `HEAD`'s, falling back to `HEAD` |
| `repro-previous-tag-release-notes` | [master](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041414450), [v3.0.3](https://github.com/ruitest2/action-gh-release-test/actions/runs/42041825005), fixed branch run [42042335666](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042335666) | same 403 while seeding comparison tags | same selection; seeded tags may share a commit because the compare links keep expected bodies distinct |
| `repro-make-latest` | wrong-input run [42042469895](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042469895), correct isolated run [42042660722](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042660722) | default `expected_latest: current` encodes the `#703` bug, not the fix | default to `previous` |

The same pass also moves `repro-release-discussion` (`present`), `trigger-prerelease` (`expected_prereleased: present`), and `repro-dotfile` (`.config`) defaults to the fixed behavior already recorded in the `3.0.0` journal.

## Pre-existing Finding: Orphan Drafts After Same-Tag Races

`repro-race` passes whenever at least one release exists, but losing workers can leave empty draft releases behind. In `canonicalizeCreatedRelease`, the duplicate-draft cleanup added in `#753` only runs when the worker's own new draft already appears in the `listReleases` response; when the listing has not caught up, the worker switches to the canonical release and skips deletion.

| Ref | Run | Releases for tag | Orphan drafts | Workers switched | Drafts cleaned |
| --- | --- | --- | --- | --- | --- |
| `v3.0.3` | [42042943865](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042943865) | 2 | 1 | 3 | 2 |
| `master` | [42042965349](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042965349) | 4 | 3 | 3 | 0 |
| `v3.0.3` | [42042980008](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042980008) | 1 | 0 | 3 | 3 |
| `master` | [42042995075](https://github.com/ruitest2/action-gh-release-test/actions/runs/42042995075) | 3 | 2 | 3 | 1 |
| `v3.0.3` | [42043304592](https://github.com/ruitest2/action-gh-release-test/actions/runs/42043304592) | 3 | 2 | 3 | 1 |
| `master` | [42043318945](https://github.com/ruitest2/action-gh-release-test/actions/runs/42043318945) | 1 | 0 | 3 | 3 |
| `v3.0.3` | [42043333469](https://github.com/ruitest2/action-gh-release-test/actions/runs/42043333469) | 1 | 0 | 3 | 3 |
| `master` | [42043356027](https://github.com/ruitest2/action-gh-release-test/actions/runs/42043356027) | 1 | 0 | 3 | 3 |
| `v3.0.3` | [42043372863](https://github.com/ruitest2/action-gh-release-test/actions/runs/42043372863) | 3 | 2 | 3 | 1 |
| `master` | [42043395732](https://github.com/ruitest2/action-gh-release-test/actions/runs/42043395732) | 4 | 3 | 3 | 0 |
| `v3.0.3` | [42043417204](https://github.com/ruitest2/action-gh-release-test/actions/runs/42043417204) | 1 | 0 | 3 | 3 |
| `master` | [42043433009](https://github.com/ruitest2/action-gh-release-test/actions/runs/42043433009) | 1 | 0 | 3 | 3 |

Totals: `v3.0.3` cleaned 13 of 18 losing drafts; the exact ref cleaned 10 of 20. Both refs leave orphans and `src/` is identical, so this is not a `3.0.4` regression. Earlier history shows the same pattern (`v2.6.0`-era runs left none; the `3.0.0` branch run left one). A follow-up fix should delete the worker's own created draft by ID when canonicalization picks another release, instead of requiring it to be visible in the listing first.

## Cleanup State

- Every workflow with a cleanup step removed its releases, tags, rulesets, and discussions; the remote target repository has no leftover releases or tags.
- Workflows without cleanup steps (`repro-assets-output`, `repro-dotfile`, `repro-duplicate-asset`, `repro-finalize-race`, `repro-home-tilde`, `repro-make-latest`, `repro-race`, `repro-windows`, `trigger-prerelease`) retained their releases as evidence, per the repository guardrails.

## Sweep Notes

- Run `repro-make-latest` and `repro-omit-name` serially with no other release-creating workflow in flight.
- `repro-race` outcomes vary run to run; compare refs with several interleaved runs and count drafts per tag.
