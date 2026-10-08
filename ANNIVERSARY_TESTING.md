# Anniversary Edition: first NPC handoff comparison

Status: both Windows builds succeeded on 7 October 2026. Native compilation,
UI packaging, and artifact upload passed. Archive inspection and all in-game
tests remain pending; successful CI does not establish gameplay compatibility.

[Completed comparison run](https://github.com/Corberstein/skyrim-coop/actions/runs/37696430203)
used baseline `115b5019609b96eb9d63bbd03962043c30437dc8` and candidate
`aa61edfe2562ca00b94c51c9b84adc9f5aaf5c97`. All four artifacts were confirmed
unexpired, with expiry on 14 October 2026:

| Build | Mod package | Debugging symbols |
|---|---|---|
| Baseline | [115b5019 ZIP](https://github.com/Corberstein/skyrim-coop/actions/runs/37696430203/artifacts/11517175649) | [Baseline symbols](https://github.com/Corberstein/skyrim-coop/actions/runs/37696430203/artifacts/11517110759) |
| Candidate | [aa61edfe ZIP](https://github.com/Corberstein/skyrim-coop/actions/runs/37696430203/artifacts/11515724459) | [Candidate symbols](https://github.com/Corberstein/skyrim-coop/actions/runs/37696430203/artifacts/11516591381) |

The workspace download attempt returned HTTP 403, so `BUILD_SOURCE.txt`,
archive contents, and independently calculated file hashes have not yet been
inspected. A separate runner-side archive check was proposed but has not run.
Before gameplay testing, verify those files and both PCs' runtime, matching
Address Library data, and effective content/load order as described below.

## Target and patch

- Steam Skyrim Anniversary Edition, user-reported `SkyrimSE.exe` version
  `1.7.104.0`, with bundled Anniversary Creation Club content in scope.
- Baseline: `115b5019609b96eb9d63bbd03962043c30437dc8`.
- NPC candidate: Sergio Rayo's upstream
  [PR 898](https://github.com/tiltedphoques/TiltedEvolution/pull/898), commit
  `c72b1df57cb634151b6f6ee0aedcd2966f1f65b3`, integrated with attribution in
  this candidate. The package's `BUILD_SOURCE.txt` identifies the exact build.
- Purpose: determine whether restoring the weapon state after a refused
  forced draw/sheathe action fixes
  [issue 810](https://github.com/tiltedphoques/TiltedEvolution/issues/810).
  This is not a general Anniversary compatibility fix.

## Build comparison

In [the project repository](https://github.com/Corberstein/skyrim-coop), run the
`Anniversary NPC handoff comparison` workflow against the candidate branch.
It also runs on code/workflow pushes to `feature-anniversary-coop-npc-handoff`;
Markdown-only updates do not start another build. The workflow is registered
on the default branch. Check the Actions run
for current build status; this document is not proof of a completed build.

The workflow calls the existing Windows build twice: once for the pinned
baseline and once for the exact triggering commit. Both use `windows-2022`,
the existing x64 toolchain and dependencies, and `releasedbg` mode. They
package the native client, server, UI, mod game files, and separate debugging
symbols through the existing build process. They do not contain Skyrim itself.

Both build jobs must succeed. Download each job's package and debugging-symbol
artifact while retained by CI (currently seven days). Package names include
`git describe` output; `SkyrimTogetherReborn/BUILD_SOURCE.txt` records the full
source commit inside each package. Record the Actions run URL and SHA-256 of
each downloaded package. Keep baseline and candidate packages distinguishable.

If a build fails, retain its compiler/configuration logs and fix that failure
before asking for an in-game test. Do not substitute a released upstream binary
and label it as the candidate.

## Test setup

Use a separate test profile and copied test saves. Before testing, record both
PCs' executable versions, effective plugin load order and content fingerprints,
Address Library data, SKSE version if loaded, and other native plugins. The
Anniversary content inventory is still unknown; the project goal includes it.
Check that dependencies match runtime `1.7.104.0` and that both players have
matching content. A game-directory file list may miss a virtual mod profile.

Within each run, both clients and the server must use the same selected build.
Do not mix baseline and candidate. Start each comparison from the same copied
pre-encounter saves and matching server settings; close the clients and server
before switching packages. Keep the original playthrough saves untouched.

## Initial reproduction

1. Connect players A and B, form a party, and approach the bandit outside
   Embershard Mine (reference `000B6CE1`). Keep both players outside initially.
2. Player A enters the mine. Player B stays outside and provokes the bandit.
3. Observe whether the bandit draws its weapon and attacks B while A stays
   inside. Record the party leader, timing, and visible weapon state.
4. Repeat with player roles reversed, starting from the same encounter state.
5. Repeat the baseline and candidate cases with matching content and settings.

If the baseline does not reproduce the issue, record "not reproduced"; a
candidate behaving normally is then insufficient evidence that this patch
fixes the reported bug. Retain client/server logs and a recording or timestamped
observations for both builds. The proposed draw/sheathe rollback has a debug
log entry that may help correlate an event; its presence alone is not a pass.

## Regression cases

| Case | Expected behavior | Result |
|---|---|---|
| A enters, B stays outside | Bandit draws and attacks B without A returning | Not run |
| Roles and leader reversed | Same behavior regardless of which player leaves | Not run |
| Ten consecutive cell handoffs | No stuck weapon state, duplicate actors, or lost target | Not run |
| Disconnect/rejoin while weapon is drawn | Local and remote weapon states recover; AI remains functional | Not run |
| Leave an idle NPC, then return | Later aggro still produces valid draw/attack behavior | Not run |
| Other weapon-using NPC types | Draw, sheathe, attack, and ownership transfer stay coherent | Not run |

Record failed cases with exact source revisions, content, reproduction steps,
logs, and observed state. This comparison covers NPC handoff only. Anniversary
quests, housing/storage, followers, Survival Mode, fishing, and persistence
remain separate, unverified acceptance areas.
