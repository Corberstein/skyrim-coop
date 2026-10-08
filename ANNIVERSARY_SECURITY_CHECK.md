# Anniversary package inspection: 8 October 2026

**The player-reported launch-time Defender alert remains unresolved.**
The reported detection is `Behavior:Win32/DefenseEvasion.A!ml` against
`SkyrimTogether.exe`, with status **Quarantined**. Do not treat the successful
build or the on-demand scan below as a false-positive determination or a reason
to restore/allow the executable. No antivirus exclusions were added, and no
protection settings were disabled by this inspection.

## What was checked

[Inspection run 37727506255](https://github.com/Corberstein/skyrim-coop/actions/runs/37727506255)
completed successfully on its second attempt at **2026-10-08 04:28:56 UTC**.
Inspection workflow revision: `49605344efd889b2d8728e0069e01ac28f68c663`, on
branch `audit-anniversary-defender-20261008`.

The inspection downloaded the original artifacts from
[build run 37696430203](https://github.com/Corberstein/skyrim-coop/actions/runs/37696430203),
without rebuilding or launching their executables. It checked artifact identity
and expiry, independently recalculated all four archive hashes against the
recorded GitHub digests, validated archive paths, wrote file inventories and
hashes, and checked the source stamp and required binary/symbol files.

| Variant | Exact source found in BUILD_SOURCE.txt | Archive/source inspection | On-demand scan |
|---|---|---|---|
| Baseline | `115b5019609b96eb9d63bbd03962043c30437dc8` | Passed | No threats reported |
| Candidate | `aa61edfe2562ca00b94c51c9b84adc9f5aaf5c97` | Passed | No threats reported after retry |

The candidate's first scan attempt stopped before scanning because the Defender
security-intelligence update failed. Its archive/source checks had passed. The
retry updated/checked definitions and completed the on-demand scan with exit
code 0. Both completed scans used definition version `1.459.601.0`.

Both runners reported `AMServiceEnabled=true`, `AntivirusEnabled=true`, and
`AMRunningMode=Normal`. They also reported **BehaviorMonitorEnabled=false** and
**RealTimeProtectionEnabled=false** in the preexisting runner configuration.
The inspection did not change these settings. Therefore the completed custom
file scans do **not** reproduce the player's behavior-based detection.

## Downloaded-file evidence

| File | Independently calculated SHA-256 |
|---|---|
| Baseline package | `7f773f40b461596ad4c8b5870e2e71fff093b9926fb6dd84521ead2c02d35d38` |
| Baseline symbols | `cd7181b21ac5f024466fbf347b0888e378e84c19cbd8e19c9de2c8382a9d146f` |
| Candidate package | `02eaca195c5edb67f829054db9ad885a01b537b629495b0416ba995118825979` |
| Candidate symbols | `fd7402385311c74c419b1e0809972d7995659c1b4be881293bffa91b82d45c05` |
| Baseline SkyrimTogether.exe | `9c9cb4fbe4943c56ea288f0af455df843bb45ac4f42b5d1b04cc4dcb1116a17d` |
| Candidate SkyrimTogether.exe | `bffd0b5ca78a0939320f8378aa5dbef4c1f5c3a48fa3df65eed6094c70027112` |

Each inspected launcher is 6,504,960 bytes and reports Authenticode status
`NotSigned`. `SkyrimTogetherServer.exe` and `STServer.dll` were present and
unsigned in both packages. Both symbol archives contain nonempty
`SkyrimTogether.pdb` and `SkyrimTogetherServer.pdb`. Matching PDB internal build
identifiers was not part of this check.

Evidence archives contain `inspection.json`, `BUILD_SOURCE.txt`, package and
symbol CSV inventories with file hashes, and (when the scan ran) its output:

- [Baseline completed inspection](https://github.com/Corberstein/skyrim-coop/actions/runs/37727506255/artifacts/11528028884)
- [Candidate completed inspection](https://github.com/Corberstein/skyrim-coop/actions/runs/37727506255/artifacts/11527914492)
- [Candidate first attempt, definition-update failure](https://github.com/Corberstein/skyrim-coop/actions/runs/37727506255/artifacts/11528790888)

Inspection evidence is retained until 7 November 2026. The original playable
and symbol packages expire on 14 October 2026.

## Source review and remaining gate

The exact baseline-to-candidate comparison changes two native client files
(`Animation.cpp` and `Actor.cpp`), plus CI and documentation. The launcher source
is unchanged. Its existing `ExeLoader` manually maps game sections, changes
executable memory protections, and replaces executable headers. That is a
possible explanation for a behavior alert, **not a confirmed cause or a complete
security audit**. A source review alone cannot establish what ran on the player PC.

Next identify the local copy using `SkyrimTogetherReborn/BUILD_SOURCE.txt` and
the original downloaded ZIP's SHA-256, without restoring the quarantined EXE.
The local package hash must be compared with the appropriate package hash above.
The behavior alert then needs local diagnostic evidence or a Microsoft analysis
determination; there has been no such submission or determination yet.

Microsoft documents the difference between
[behavior monitoring](https://learn.microsoft.com/en-us/defender-endpoint/demonstration-behavior-monitoring)
and [on-demand command-line scans](https://learn.microsoft.com/en-us/defender-endpoint/command-line-arguments-microsoft-defender-antivirus).
Its [submission guide](https://learn.microsoft.com/en-us/unified-secops/submission-guide)
describes vendor review of suspected malware and incorrectly detected files.

Steam executable `1.7.104.0`, matching Address Library data, both PCs' effective
content/load order, and the controlled two-player NPC handoff test remain
separate unverified gates. See [ANNIVERSARY_TESTING.md](ANNIVERSARY_TESTING.md).
