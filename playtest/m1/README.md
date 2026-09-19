# Royal Forest M1 Retune Playtest

This is the required human gate before M2 content production. The retune addresses the first M1 playtest: weapon readability, enemy strike tracking, guard/chip communication, and instant de-aggro behind cover.

## Launch

Run from the Royal Forest folder:

```sh
# Linux
$HOME/.local/opt/godot --path . res://game/app/game_root.tscn

# Windows 10 (PowerShell; adjust the executable path if needed)
.\Godot_v4.4.1-stable_win64.exe --path . res://game/app/game_root.tscn
```

On Windows, the standard Godot 4.4.1 build is enough; this project uses GDScript, not C#/Mono. Download and extract `Godot_v4.4.1-stable_win64.exe.zip`; no installer, .NET/Mono, Python, Git, compiler, SDK, or Xvfb is required to play. Current graphics drivers are recommended. Alternatively, open Godot, choose **Import**, select this folder's `project.godot`, then press **F5**. The first import regenerates `.godot/` and may take a few seconds.

The scripts under `tools/` are Linux/bash/Xvfb developer checks and are not required on Windows. Git for Windows is optional if future builds will be pulled instead of sent as ZIP files.

When reporting the retest, include the resolution/window mode and whether keyboard/mouse or an XInput controller was used; note any Windows-specific mouse-capture, sensitivity, controller, or HUD-scaling issue.

## Controls

- Keyboard/mouse: **WASD** move, **mouse** look, **left mouse** attack, **Q** Spectral Bolt, **F** healing vessel, **C** toggle crouch, **Space** dodge, **right mouse (hold)** guard, **R** reset, **Esc** release mouse.
- Controller: **left stick** move, **right stick** look, **right trigger** attack, **right shoulder** Spectral Bolt, **D-pad Up** healing vessel, **D-pad Down** toggle crouch, **A / Cross** dodge, **left trigger (hold)** guard, **Y / Triangle** reset.
- Diagnostics: **F9** starts/stops synchronized gameplay telemetry and local video capture; **F10** flashes and records an issue marker at the exact bad moment. Recording does not cap the game; the saved MP4 is converted to 24 FPS at up to 720p.

### Recording a hard-to-describe issue

1. Press **F9**, reproduce only the issue (ideally 15–40 seconds), and press **F10** when it happens.
2. Press **F9** again to stop. On this Linux development machine, Godot samples only its own rendered game viewport at 24 FPS without capping the game itself. Temporary JPEG frames are converted to a compact H.264 MP4 and deleted only after the MP4 verifies successfully. The matching JSONL contains 20 Hz player/enemy state.
3. Use **Test Royal Forest.desktop → Open diagnostic recordings** to view the files. The canonical local folder is `~/.local/share/godot/app_userdata/Royal Forest/recordings`.
4. Say that the recording is ready; the newest same-named `.mp4` and `.jsonl` pair can be analyzed together. After the issue is confirmed fixed, use **Delete diagnostic recordings**; it previews the exact files and asks before deletion.

The Linux capture records the game viewport only, not the desktop or other windows. On Windows, F9 still records telemetry and burns the diagnostic HUD into the game, but video capture uses Xbox Game Bar: press **Win+Alt+R** at the same start/stop points. Send the resulting MP4 together with the matching JSONL if possible.

## 2–5 minute retest

1. Attack the Shambler from clearly inside and outside sword range. Watch the gray-box sword windup, active swing, and recovery. A connected hit flashes/staggers/nudges the enemy and briefly displays `HIT`.
2. Circle-strafe continuously around the enemy for several attacks. While green, it should rapidly turn to face you instead of falling permanently behind. Orange windup turning remains capped at 45°/s; once it turns red, dodge sideways—the strike direction and visible danger wedge must remain committed until the red window ends. Green recovery should then promptly re-aim without translating.
3. Hold guard through a strike. The raised shield and HUD should make guarding obvious. A normal block reduces damage by 80%, intentionally deals 20% chip damage (4.8 HP from the current Shambler), spends stamina, and displays `BLOCKED — … CHIP`. Exhaust stamina once to compare the distinct guard-break response.
4. Break line of sight behind the tall pillar. The enemy should retain awareness briefly and hunt around the pillar toward your last-known position instead of stopping at a detour corner. First peek back out from the **same side you used to enter cover**; it should route around and re-engage. Repeat from the other side, then hide long enough for it to give up and begin walking home before stepping into clear view again. All three reveals should re-engage within detection range.
5. At the short waist-high block, confirm the enemy sees you while standing. Press **C / D-pad Down** to crouch without changing position: the `STANCE CROUCHED` HUD text should appear, movement should slow, and continuous concealment should make the enemy enter search after its brief LOS grace. Stand to reveal yourself and confirm immediate reacquisition. Also try crouching beneath low clearance; standing and dodge must fail without clipping until you move clear. Attack, cast, heal, and guard should still work while crouched.

## Five feedback questions

Answer **yes/no**, adding details where anything feels wrong:

1. Does the sword make attack timing and range legible—can you now tell why a swing hit or missed?
2. Can the enemy rapidly re-aim between attacks during continuous circle-strafing while the red strike itself still commits and misses when you dodge during its locked window?
3. Is it obvious that you are guarding and that successful blocks provide the accepted 80% reduction with 20% chip damage?
4. Does the enemy hunt around the pillar toward your last-known position without stalling at a detour corner, then reacquire whether you reappear from the same or a different direction?
5. Does crouching behind the short block provide understandable concealment without feeling like a full stealth system, and does the 40% movement speed feel appropriately deliberate?

Verdict: **Proceed to M2**, **Retune M1 again**, or **Rethink the core loop**.

## Recorded verdict — 2026-09-18

**Verdict: Proceed to M2 systems work with one bounded M1 follow-up.** The game-feel director explicitly asked for a local checkpoint commit and for M2 implementation to continue; the newest green-recovery turning change will be reviewed together with M2 rather than blocking systems work.

| Required area | Recorded disposition | Evidence / owner |
|---|---|---|
| Movement speed, acceleration, stopping | Accepted | Earlier M1 playtest accepted core movement; locked 3.2 m/s remains unchanged. |
| Camera, FOV, sensitivity, comfort | Accepted for this gate | Earlier M1 playtest accepted the movement/camera baseline; locked 70° and 0.0022 remain unchanged. |
| Attack weight, range, arc, timing, recovery | Accepted | Follow-up report: weapon readability “work[s] great”; windup and red attack also “working great.” |
| Dodge and shield usefulness | Accepted | Core dodge/stamina was accepted; guard readability works; 80% reduction with 20% chip damage was explicitly accepted. |
| Enemy tell, strike, pursuit, punish timing | Accepted with bounded follow-up | Pillar pathing was explicitly confirmed fixed. Green RECOVERY re-aim is implemented and automated; **human feel review remains pending** with M2. Owner: implementer; tuning is one value in `shambler.tres`. |
| Damage, exhaustion, death feedback | Accepted for continued systems work | No blocking issue was reported after guard/chip feedback became readable; automated smoke and named visual checkpoints remain mandatory. |
| Exploration-to-combat rhythm | Deferred to M2 route review | The gray-box room cannot prove a 20–30 minute exploration rhythm. Owner: M2e route playtest; this is not a blocker for M2a–M2d systems work. |
| Circle-strafe, doorway, elevation exploits | Bounded follow-up | Pillar/detour exploit is fixed. Circle-strafe exploit is addressed by fast green re-aim, limited orange turning, and direction commitment only during red ACTIVE; human review is queued with M2. Doorway/elevation cases remain M2e route checks. |
| M2b healing economy | Accepted for first playable | Human report: the new M2 additions are working great. Three charges, 40% max-HP healing, 0.80/0.08/0.52-second phases, and loss of a charge on windup interruption proceed into M2c; final M2 exit review may still retune proposed values. |
| Crouch / low-cover concealment | New M2b.1 review | C / D-pad Down, 40% movement, low-cover LOS break, safe headroom behavior, and controller parity require the five-step retest above before M2 exit. |

Green pursuit and recovery re-aim rapidly (540°/s); orange windup permits only slow limited turning (45°/s); only the red active strike is direction-committed (0°/s). The 540°/s value intentionally defeats perpetual circle-strafing but may feel abrupt; compare it with a possible 360°/s retune during the combined review rather than changing the committed red window.

## Current tuning ownership

- Player movement/combat/viewmodel: `game/data/tuning/player_default.tres`
- Shambler awareness, turning, navigation, and attack: `game/data/enemies/shambler.tres`

Locked player defaults remain **3.2 m/s walk**, **70° FOV**, and **0.0022 mouse sensitivity**.

## Current gray-box limitations

- The sword and shield are functional gray-box meshes, not final art or effects.
- Search navigation uses a deterministic arena waypoint helper, not the production world navigation solution. Searching and returning do not restore enemy HP; only an explicit encounter reset does.
- There is no attack or block audio yet.
- The first-person viewmodel uses an always-visible material to prevent wall clipping; judge attack timing/range from the actual hit feedback as well as the placeholder mesh.
