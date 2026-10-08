# Prepared Microsoft Defender review request

Status: prepared, **not submitted**. External submission requires the user's
authorization. This draft requests investigation of a suspected false positive;
it does not assert a security determination.

Destination: [Microsoft Security Intelligence file submission](https://www.microsoft.com/en-us/wdsi/filesubmission).

Material to send:

- `SkyrimTogether.exe`, extracted from the verified candidate ZIP, 6,504,960 bytes.
- SHA-256: `bffd0b5ca78a0939320f8378aa5dbef4c1f5c3a48fa3df65eed6094c70027112`.
- Detection name: `Behavior:Win32/DefenseEvasion.A!ml`.
- Product: Microsoft Defender Antivirus.
- The technical description below, including public repository and build links.

## Technical description

Request: investigate a suspected false positive; no determination assumed.

Detection: Behavior:Win32/DefenseEvasion.A!ml

Detected file: SkyrimTogether.exe

Player status: Quarantined following a launch attempt on Windows.

Executable SHA-256: bffd0b5ca78a0939320f8378aa5dbef4c1f5c3a48fa3df65eed6094c70027112

Executable size: 6504960 bytes

Authenticode status: NotSigned

Source revision: aa61edfe2562ca00b94c51c9b84adc9f5aaf5c97

Source repository: https://github.com/Corberstein/skyrim-coop

Build run: https://github.com/Corberstein/skyrim-coop/actions/runs/37696430203

Inspection run: https://github.com/Corberstein/skyrim-coop/actions/runs/37727506255

The uploaded package and launcher hashes match the original GitHub Actions artifacts.
Updated on-demand Microsoft Defender scans reported no threats with signatures
1.459.601.0. These were file scans only; behavior monitoring and real-time
protection were disabled in the runner's preexisting configuration, and no game
was launched. No antivirus settings were disabled by our checks.

The project is a Skyrim co-op mod derived from tiltedphoques/TiltedEvolution.
The existing launcher manually maps the locally installed game's executable.
Its loader source is unchanged between the baseline and this candidate. This
candidate adds an NPC weapon-state handoff fix in two native client files,
with CI and documentation changes. The relationship between game loading
and the detection is a hypothesis; the launch-time detection has not been
reproduced or explained. Please investigate the detection for this exact
executable.
