# Royal Forest v0.1 First Playable — Rebuild Implementation Plan

> **Execution boundary:** The user has authorized implementation and installation of missing test packages. Commits, pushes, branches, PRs, publishing, and destructive cleanup still require a separate explicit request.

**Goal:** Build a clean, GDD-traceable first playable from Root-Crown through the Crowned Hunt and Hound-King to the first persistent Crown Seal.

**Architecture:** Rebuild around deterministic simulation services and typed custom Godot `Resource` content records identified by stable `StringName` IDs. A delta-driven player action state machine owns attack/dodge/guard/cast/heal commitment; presentation observes state instead of owning save-critical truth. A versioned save boundary serializes explicit state-owner snapshots and validates all IDs before applying data.

**Tech stack:** Godot 4.4-compatible Godot 4.x, GDScript, GL Compatibility renderer, dependency-free in-repo test runner, route smoke scene, Linux Xvfb screenshot probe. GUT is an optional evaluated dependency only; it is not assumed installed and is not required for v0.1.

**Requirements authority:** `docs/GAME_DESIGN_DOCUMENT.md` and `docs/plans/REQUIREMENTS.md`.

---

## 1. Scope and non-negotiables

v0.1 ends when a fresh player can travel Root-Crown → Crowned Hunt, learn the combat loop, use a living tree, equip a weapon/shield/spell, allocate or respec attributes, discover the map, defeat Hound-King, receive the first Crown Seal, die/retry, and preserve durable state across a process restart.

Keep these **LOCKED** defaults exact:

- Forward walk speed: **3.2 m/s**
- Vertical field of view: **70 degrees**
- Mouse sensitivity: **0.0022**

All other GDD numeric defaults retain their **PROPOSED** status and must live in tunable Resources. Preserve the out-of-scope guardrails in `REQUIREMENTS.md`; do not broaden the slice while “preparing” architecture.

## 2. Preservation and migration policy

The current three-room prototype is evidence, not the target architecture.

1. **Do not delete prototype files during the rebuild.** Keep `scenes/main.tscn`, `scenes/hud.tscn`, `scripts/*.gd`, current assets, and `tools/smoke_test.*` runnable until the replacement route satisfies the M2 gate.
2. Build the replacement under new paths. Reuse a prototype behavior or asset only after recording which requirement it satisfies and removing hidden dependency on the `GameState` autoload.
3. Keep the current main scene until M2 integration is ready. Switching `run/main_scene` is a deliberate review task, not an early cleanup.
   Keep the prototype `GameState` autoload unchanged through M0 and the M1 gray-box build so the legacy smoke remains meaningful; replacement systems must not read or write it. Flip `run/main_scene` to the new playable root when M1 first becomes runnable. Keep the explicit legacy-scene smoke as a regression gate until prototype retirement is separately approved; it does not define behavior for the new main scene.
4. Do not mutate old prototype saves into the new format. v0.1 starts a new versioned save contract and fails safely on unsupported data.
5. Delete/rename/archive prototype files only in a later controller-approved cleanup after parity, route smoke, visual review, and recovery instructions are proven.
6. Godot scene/resource edits may generate or rewrite `.uid` files. Include each required `.uid` beside its source, never hand-copy a UID, inspect unexpected UID churn, and do not delete UID files merely to make a diff smaller.
7. `project.godot` is serialized configuration. Make narrowly scoped edits, let Godot produce valid syntax where practical, and inspect the complete diff for reordered/removed settings, input actions, autoloads, collision layers, renderer values, and `run/main_scene`.

## 3. Planned architecture and exact paths

Paths below are the intended contract. A task may adjust a filename only through plan review; avoid ad-hoc placement.

### 3.1 Runtime ownership

| Concern | Planned path | Responsibility |
|---|---|---|
| Composition root | `game/app/game_root.gd`, `game/app/game_root.tscn` | Construct services, route scene, menus, and transitions; no gameplay truth. |
| IDs/registry | `game/core/content_id.gd`, `game/core/content_registry.gd` | Namespace validation, duplicate/reference checks, typed lookups. |
| Signals/events | `game/core/game_events.gd` | Narrow runtime notifications; never substitute signals for authoritative state. |
| Player stats | `game/state/player_stats.gd` | Base/current resources, attributes, formulas, spend/heal/damage APIs. |
| Inventory | `game/state/inventory.gd` | Owned item IDs, typed slots, equip/use validation. |
| World state | `game/state/world_state.gd` | checkpoints, pickups, shortcut, map discovery, guardian and seal state. |
| Narrative state | `game/state/narrative_state.gd` | v0.1 note/echo/truth/discovery hooks; future-safe without ending logic. |
| Save service | `game/save/save_data.gd`, `game/save/save_manager.gd`, `game/save/save_migrations.gd` | Versioned DTO, validated snapshots, atomic write/backup/load/recovery. |
| Session orchestration | `game/app/game_session.gd` | New/continue, rest transaction, death/respawn, route reset, save triggers. |

These owners replace, rather than enlarge, `scripts/game_state.gd`. Presentation may request commands and subscribe to changes; it must not set persistent dictionaries directly.

### 3.2 Typed content Resources

Create custom `Resource` classes under `game/data/schema/`:

- `identified_resource.gd`
- `item_definition.gd`, `weapon_definition.gd`, `shield_definition.gd`, `spell_definition.gd`
- `enemy_definition.gd`, `enemy_move_definition.gd`
- `region_definition.gd`, `encounter_definition.gd`, `checkpoint_definition.gd`
- `player_tuning.gd`, `accessibility_defaults.gd`

Create authored `.tres` records under:

- `game/data/tuning/player_default.tres`
- `game/data/tuning/accessibility_default.tres`
- `game/data/items/`
- `game/data/enemies/`
- `game/data/encounters/`
- `game/data/world/`

Every persisted or cross-referenced identity is a stable lowercase `StringName` in `<namespace>.<slug>` form. Resource paths are locators, not identities. `content_registry.gd` loads and validates all records before a new game or save load proceeds.

### 3.3 Player and combat

| Concern | Planned path |
|---|---|
| Controller/camera/input adapter | `game/player/player_controller.gd`, `game/player/player_controller.tscn`, `game/player/player_camera.gd`, `game/input/input_router.gd` |
| Explicit action state machine | `game/player/action/player_action_machine.gd`, `game/player/action/player_action_state.gd`, `game/player/action/player_action_request.gd` |
| Hit/damage contracts | `game/combat/hit_query.gd`, `game/combat/damage_event.gd`, `game/combat/hurtbox.gd`, `game/combat/hitbox.gd` |
| Spell projectile | `game/combat/spell_projectile.gd`, `game/combat/spell_projectile.tscn` |
| Healing vessel | `game/player/healing_vessel.gd` |
| Enemy runtime | `game/enemies/enemy_controller.gd`, `game/enemies/enemy_controller.tscn`, `game/enemies/enemy_state_machine.gd` |
| Guardian runtime | `game/enemies/hound_king_controller.gd`, `game/enemies/hound_king.tscn` |

`player_action_machine.gd` is advanced by explicit `delta` through named phases such as `FREE`, `ATTACK_WINDUP`, `ATTACK_ACTIVE`, `ATTACK_RECOVERY`, `DODGE`, `GUARD`, `GUARD_BROKEN`, `CAST`, `HEAL_START`, `HEAL_COMMIT`, `HURT`, and `DEAD`. State records own elapsed time, cancel/interrupt policy, resource charge point, i-frame window, and buffered request. Scene animation and effects follow transitions; they do not decide them.

### 3.4 World, UI, settings, and route

- Route scenes: `game/world/root_crown.tscn`, `game/world/crowned_hunt.tscn`, `game/world/hound_king_arena.tscn`
- Reusable world actors: `game/world/actors/living_tree.gd/.tscn`, `persistent_pickup.gd/.tscn`, `shortcut.gd/.tscn`, `region_transition.gd/.tscn`
- Map model/presentation: `game/map/map_model.gd`, `game/ui/screens/map_screen.gd/.tscn`
- HUD: `game/ui/hud/game_hud.gd/.tscn`
- Screens: `game/ui/screens/main_menu.tscn`, `pause_menu.tscn`, `settings_screen.tscn`, `inventory_screen.tscn`, `attributes_screen.tscn`
- Shared focus/prompt logic: `game/ui/ui_focus_manager.gd`, `game/ui/input_prompt.gd`
- Settings: `game/settings/user_settings.gd`, `game/settings/settings_store.gd`
- Theme: `game/ui/theme/royal_forest_theme.tres`

The map stores discovered stable `map_area` IDs. It is not a minimap and does not inspect world nodes to reveal secrets. Menus use Godot focus neighbors and explicit back actions so keyboard/mouse and controller share one navigation graph.

### 3.5 Test and verification tooling

- Runner: `tests/test_runner.gd`, `tests/test_runner.tscn`
- Helpers/fakes: `tests/support/assertions.gd`, `tests/support/simulation_fixture.gd`, `tests/support/temp_save_store.gd`
- Unit suites: `tests/unit/test_content_registry.gd`, `test_player_stats.gd`, `test_player_action_machine.gd`, `test_inventory.gd`, `test_enemy_state_machine.gd`, `test_save_round_trip.gd`
- Integration: `tests/integration/test_checkpoint_respawn.gd`, `test_first_seal_route.gd`, `test_settings_persistence.gd`
- Route smoke: `tests/smoke/first_playable_smoke.gd`, `tests/smoke/first_playable_smoke.tscn`
- Screenshot probe: `tests/visual/screenshot_probe.gd`, `tests/visual/screenshot_probe.tscn`, `tools/run_visual_probe.sh`
- Content validator: `tools/validate_content.gd`
- Playtest materials: `playtest/v0.1/README.md`, `playtest/v0.1/FEEDBACK.md`, `playtest/v0.1/KNOWN_ISSUES.md`, `playtest/v0.1/BUILD_ID.txt`

The custom runner is dependency-free and returns nonzero on any failure. GUT may be evaluated in a separate decision record after M0; adoption is permitted only if it provides clear value, is pinned, works headlessly, and does not invalidate these commands.

## 4. Standard RED–GREEN–REFACTOR loop

Every code-producing work item follows this loop at reviewable-commit granularity:

1. Add the smallest failing test named for a requirement ID or acceptance boundary.
2. Run the narrow suite and verify it fails for the intended missing behavior, not a parse/setup error.
3. Implement the smallest production change.
4. Run the narrow suite and verify it passes.
5. Refactor while tests remain green.
6. Run the milestone command set, inspect warnings, then review scene/resource/project and `.uid` diffs.
7. Stop for controller review when a proposed commit boundary is reached. **Do not commit automatically.**

For presentation-only work, RED is a failing/absent screenshot checkpoint or route-smoke assertion plus a written visual expectation. Automated screenshots support, but never replace, human visual review.

## 5. Canonical commands

Use the repository-documented executable and absolute project path:

```sh
GODOT="$HOME/.local/opt/godot"
PROJECT="/mnt/storage/Git/royal-forest"
```

### Fast and milestone checks

```sh
# Import/parse resources. Godot can exit zero on parser errors, so inspect output.
"$GODOT" --headless --path "$PROJECT" --import 2>&1 | tee /tmp/royal-forest-import.log
if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:' /tmp/royal-forest-import.log; then exit 1; fi

# Dependency-free deterministic tests.
"$GODOT" --headless --path "$PROJECT" --script res://tests/test_runner.gd

# Stable-ID and content-reference validation.
"$GODOT" --headless --path "$PROJECT" --script res://tools/validate_content.gd

# New integrated route smoke.
"$GODOT" --headless --path "$PROJECT" res://tests/smoke/first_playable_smoke.tscn

# Preserve and run the legacy prototype smoke until retirement is approved.
"$GODOT" --headless --path "$PROJECT" res://tools/smoke_test.tscn

# Bounded startup catches fatal runtime errors/hangs.
timeout 12 "$GODOT" --headless --path "$PROJECT"
```

If Godot requires a main-loop scene rather than `--script` for the runner/validator in the installed version, use their planned `.tscn` entry point consistently and update this document in the same reviewed change.

### Rendered-frame visual probe

Godot headless logic mode is not sufficient evidence for visual output. Prefer Godot movie-maker mode, which renders real frames through the configured renderer:

```sh
mkdir -p /tmp/royal-forest-frames
"$GODOT" --path "$PROJECT" --write-movie /tmp/royal-forest-frames/frame.png \
  --quit-after 60 --resolution 1280x720
```

Inspect at least one settled mid-run frame. Use Xvfb as the fallback for menu focus/input checks that require a display server:

```sh
mkdir -p "$PROJECT/artifacts/visual"
xvfb-run -a -s "-screen 0 1280x720x24" \
  env LIBGL_ALWAYS_SOFTWARE=1 "$GODOT" --path "$PROJECT" \
  res://tests/visual/screenshot_probe.tscn -- \
  --output=res://artifacts/visual
```

`tests/visual/screenshot_probe.gd` must wait for rendered frames, visit deterministic named checkpoints, call `Viewport.get_texture().get_image()`, save PNGs, and exit nonzero if a required image is absent/blank or a checkpoint cannot be reached. Review the captures at 1280×720 and one UI-scale extreme. When a real desktop is available, also launch interactively; automated rendering proves capture, not subjective feel.

### Markdown and repository checks

```sh
python3 - <<'PY'
from pathlib import Path
for name in ("docs/plans/REQUIREMENTS.md", "docs/plans/REBUILD_PLAN.md"):
    text = Path(name).read_text(encoding="utf-8")
    assert text.endswith("\n"), name
    assert "\t" not in text, name
    fences = sum(line.startswith("```") for line in text.splitlines())
    assert fences % 2 == 0, name
print("markdown sanity: PASS")
PY
git diff --check -- docs/plans/REQUIREMENTS.md docs/plans/REBUILD_PLAN.md
```

## 6. M0 — Foundation

### M0 entry gate

- GDD revision 0.2 and `REQUIREMENTS.md` are the baseline.
- Prototype remains runnable and untouched except for future explicitly reviewed integration needs.
- The documented directory/ownership boundaries are the approved implementation baseline; old prototype saves are unsupported.

### M0.1 — Test spine and boot skeleton

**Objective:** Establish a new boot path and dependency-free tests without switching the shipped main scene.

**Create:**

- `game/app/game_root.gd`, `game/app/game_root.tscn`
- `tests/test_runner.gd`, `tests/test_runner.tscn`
- `tests/support/assertions.gd`, `tests/support/simulation_fixture.gd`

**Modify later and narrowly:** `project.godot` only to add reviewed input/autoload/config entries; do not change `run/main_scene` in this subphase.

**TDD/verification:** Start with a failing runner self-test, then a composition test that constructs a session with fake stores. Run import, the new unit runner, bounded startup, and legacy smoke. Inspect all generated `.uid` files.

**Proposed review boundary:** boot/test infrastructure only.

### M0.2 — Initial typed data and stable-ID pattern

**Completed scope:** `PlayerTuning` and `EnemyDefinition` are typed Resources; enemy IDs use the stable `enemy.<slug>` namespace; malformed IDs and invalid active-turn configuration are rejected by tests. Locked player defaults live in a Resource and are protected by exact tests.

**Deliberately deferred:** the cross-system `ContentRegistry`, complete validator, and item/spell/region/encounter/checkpoint schemas enter with their owning M2a–M2e systems. The complete registry/validator is a hard gate before M2e authored route production, not a claim of completed M0 work.

### M0.3 — Initial state owner and formulas

**Completed scope:** `PlayerStats` owns HP/stamina and their formulas; the replacement gameplay path does not read or write the prototype `GameState`; deterministic tests cover resource boundaries, damage/healing, and recovery.

**Deliberately deferred:** `WorldState`, `NarrativeState`, and `SaveManager` are M2c so every persistent owner exists in save schema v1; `Inventory` and attribute formulas are M2d. M2e populates route-facing narrative content but does not introduce a new persistence owner. Each owner must expose commands and copied snapshots, with presentation excluded from ownership.

### M0.4 — Persistence boundary rescheduled to M2c

Versioned save data was not implemented speculatively before persistent gameplay facts existed. M2c must create `game/save/save_data.gd`, `save_manager.gd`, `save_migrations.gd`, a temporary save store, and round-trip/corruption/atomic-replacement tests before any M2e route state depends on persistence.

### M0.5 — Input boundary completed; settings persistence rescheduled

**Completed scope:** gameplay consumes `InputCommand` through `InputRouter`; keyboard/mouse and controller bindings exist; production gameplay code does not directly branch on device-specific events.

**Deliberately deferred:** user settings, settings storage, accessibility defaults, device-prompt switching, and persistence tests enter during M2d/M2f, before the first-playable exit gate.

### M0 exit gate — recorded executable foundation

All are true for the scope actually used by M1:

- Import, custom test runner, bounded startup, new combat smoke, and legacy smoke pass.
- `PlayerStats` ownership is explicit and replacement systems do not write prototype `GameState` fields.
- Initial tuning/enemy Resources validate locked defaults and stable enemy IDs.
- Input is abstracted behind commands for keyboard/mouse and controller.
- `project.godot` and `.uid` diffs are reviewed; no prototype file is deleted.

The deferred registry, persistence, inventory, world/narrative state, and settings work remains mandatory in M2a–M2d and blocks M2e route production until verified.

## 7. M1 — Combat-feel proof

### M1 entry gate

The recorded executable M0 scope is accepted. Deferred registry/persistence/state foundations are explicitly assigned to M2a–M2d and must pass before M2e route production. Hound-King final creative decisions are not required. Proposed combat numbers remain tunable.

### M1.1 — First-person controller and camera

**Create:** `game/player/player_controller.gd/.tscn`, `game/player/player_camera.gd`, gray-box `tests/playgrounds/combat_playground.tscn`.

**Tests first:** forward/strafe/back directional speeds, acceleration/stopping, collision response, input disabled during menus/death, mouse/stick look scaling, pitch clamp, FOV default/range, invert Y, head-bob off.

**Manual verification:** scale, seam traversal, motion comfort, predictable stopping, controller deadzone. Capture neutral/moving screenshots in the visual probe.

### M1.2 — Delta-driven action machine and stamina

**Create:** action files under `game/player/action/` and `tests/unit/test_player_action_machine.gd`.

**Tests first:** each legal phase sequence; attack cost and active window; dodge cost/motion/i-frame/recovery; guard equipment requirement; continuous/impact drain; guard break; insufficient-resource rejection; hurt/death interruption; heal commitment; one buffered attack/dodge near recovery without canceling commitment; large/small delta boundary behavior.

**Implementation rule:** tests call deterministic `advance(delta)` with action requests. Avoid `SceneTreeTimer`, animation completion, wall-clock time, or `_process` as the sole authority. Presentation receives phase/progress events.

### M1.3 — Damage, hit queries, and feedback contract

**Create:** files under `game/combat/` and placeholder feedback under `game/presentation/combat_feedback.gd`.

**Tests first:** front hit, rear miss, wall occlusion, multi-target visible arc, invulnerability, guard reduction/break, no damage outside active frame, and source attribution.

**Manual/visual:** weapon arc reads correctly; accepted/blocked/exhausted states differ by more than color; hit effect does not hide the next action.

### M1.4 — Complete ordinary enemy

**Create:** `game/enemies/enemy_controller.gd/.tscn`, `enemy_state_machine.gd`, one `EnemyDefinition`, move Resources, and `tests/unit/test_enemy_state_machine.gd`.

**Tests first:** detection with LOS, no detection through wall, pursuit, leash return, obstacle navigation integration, windup/active/recovery, interrupt policy, hurt/death, and reset.

**Gray-box encounters:** one spacing/punish case and one lateral-evasion/patrol case. Reuse placeholder sprites only if their directional/readability limits are documented.

### M1.5 — HUD baseline, controller pass, and visual probe

**Create:** `game/ui/hud/game_hud.gd/.tscn`, `game/ui/input_prompt.gd`, `game/ui/ui_focus_manager.gd`, visual probe files, and `tools/run_visual_probe.sh`.

**Verify:** HP always legible; stamina appears around use and fades; prompts switch device; guard/attack/dodge rejection is understandable; controller completes playground; Xvfb captures neutral, low-stamina, hit, guard-break, enemy-tell, and death frames.

### M1 hard human playtest gate

Automated green status is necessary but insufficient. Provide a playable gray-box build and record an explicit verdict for:

1. movement speed/acceleration/stopping;
2. camera/FOV/sensitivity/motion comfort;
3. attack weight, range, arc, active timing, and recovery;
4. dodge distance/i-frames/recovery and shield usefulness;
5. enemy tell, strike, pursuit, and punish timing;
6. damage, knockback, exhaustion, and death feedback;
7. exploration-to-combat rhythm; and
8. circle-strafe, doorway, and elevation exploits.

**Pass:** each item is accepted or has bounded tuning work with an owner. Fundamental “not fun/not readable/not attributable” findings fail the gate. The controller recorded this pass on 2026-09-18; M2 systems work may proceed, while authored M2e route production remains gated on the M2a–M2d foundations.

### M1 exit gate — recorded 2026-09-18

- Executable M0 suite plus action, collision, enemy, combat smoke, and Xvfb probe pass.
- Keyboard/mouse and controller inputs complete the playground; the game-feel director accepted the baseline for continued systems work.
- Human verdict is **Proceed to M2 systems work** with green-recovery turning as bounded follow-up owned by the implementer and queued for combined M2 review.
- Low-stamina, connected-hit, death, guard, attack, and enemy-phase visual checkpoints are mandatory.
- No broad route content production or prototype deletion occurred.

## 8. M2 — Complete v0.1 first playable

### M2 entry gate

M1 hard human gate passes. Route blockout scope, spell choice, Insight hook, and Hound-King blockout concept are approved enough to implement without pretending final art/narrative decisions are locked.

### M2.0 — Architecture prerequisites and execution order

The playable scene already lives under `game/world/`; `EnemyDefinition` has a stable ID; and the HUD uses anchored, scale-safe containers. Before authored M2e route production, complete the remaining foundations in this order:

1. **M2a — complete:** spell schema/record and mana owner behavior; initial registry coverage for spells.
2. **M2b:** vessel model and committed interruption behavior.
3. **M2c:** `WorldState`, `NarrativeState`, checkpoint/death/respawn, versioned `SaveManager`, save schema v1, and atomic/backup recovery tests.
4. **M2d:** `Inventory`, attributes/respec, settings persistence, map state, complete in-scope registry/validator.
5. **M2e:** populate route-facing narrative content, then author Root-Crown/Crowned Hunt content; do not introduce a new persistence owner here.

Immutable tuning must be duplicated into per-session runtime state before settings can mutate it. Each foundation is test-first and receives its own local checkpoint commit; no M2e content may paper over a missing owner or persistence contract.

**M2a implemented scope:** `PlayerStats` now owns 100 max mana, starts full, delays recovery for 2.0 seconds after casts or damage, and restores 2.5 mana/second. The authored `spell.spectral-bolt` costs 25 mana and deals 30 damage through data-driven 0.28/0.08/0.44-second cast phases; its projectile travels at 16 m/s up to 24 m with a 0.16 m radius. `ContentRegistry` currently validates and indexes spells only; complete in-scope registry coverage remains M2d work. Focused tests cover mana boundaries, schema/registry rejection, cast commitments and buffering, camera-forward release, projectile enemy/world/range behavior, playground integration, and responsive mana HUD layout. M2b–M2e are not marked complete and no M2e route content was produced.

Green pursuit and recovery re-aim rapidly (540°/s); orange windup permits only slow limited turning (45°/s); only the red active strike is direction-committed (0°/s).

### M2.1 — Inventory, equipment, spell, and vessel

**Create:** production item/weapon/shield/spell Resources, `game/combat/spell_projectile.gd/.tscn`, `game/player/healing_vessel.gd`, inventory/equipment screen.

**Tests first:** pickup once, slot compatibility, equip/unequip, shield guard enablement, one spell mana cost/delay/recovery, free aim, controller aim friction without snap/lock-on, vessel interruption/commit/charge/refill, and snapshot round trip.

**Route proof:** player discovers at least one meaningful equipment item; spell and shield are useful but do not become hidden future route-order dependencies.

### M2.2 — Living tree, death/respawn, and save transaction

**Create:** living-tree actor, `game/app/game_session.gd`, checkpoint integration test.

**Tests first:** activate checkpoint ID, rest refill, vessel refill, save indication, enemy reset, allocation/respec permission, death at zero HP, clear transient action/aggro state, respawn transform, retain unique pickup/shortcut/map/seal, no dropped-resource spawn, and restart-process load.

**Transaction order:** validate checkpoint → leave combat → refill/reset renewable state → apply allocation/respec changes → snapshot owners → atomic save → display success. A failed save must report failure and retain the last valid file.

### M2.3 — Attributes, respec, map, and menus

**Create:** attributes and map model/screens, main/pause/settings screens, shared theme/focus logic.

**Tests first:** one-time discovery award, formula effects, respec conservation/out-of-combat restriction, map reveal by stable ID, no secret pre-reveal, settings persistence, pause policy, focus traversal, valid back path.

**Visual checks:** minimum/maximum planned UI scale, text size, FOV bounds, brightness reference, color-independent selected/disabled state, no clipping at 1280×720. Full remapping and assist mode remain deferred unless pulled in explicitly.

### M2.4 — Root-Crown and Crowned Hunt route blockout

**Create:** three route scenes, Region/Encounter/Checkpoint Resources, persistent pickup/shortcut/transition actors.

**Required beats:**

1. Root-Crown living tree, map introduction, brother clue, nexus landmark, and Crowned Hunt road.
2. Readable region entrance and patrol observation.
3. Equipment/weapon discovery and two meaningfully different encounters.
4. A lock/shortcut payoff and optional risk/secret.
5. A one-time attribute discovery and observable Insight hook.
6. Pre-guardian living tree.
7. Hound-King arena and post-defeat first Crown Seal feedback.
8. Return/reload proof showing shortcut/map/tree/guardian/seal persistence.

**Constraints:** target 20–30 minutes for the v0.1 route. Do not expand silently to the full 30–45 minute production region. No minimap, compass, quest marker, or objective arrow.

### M2.5 — Hound-King and first Crown Seal

**Create:** guardian scene/controller, Guardian/EnemyMove/Seal Resources, and `tests/integration/test_first_seal_route.gd`.

**Tests first:** valid pre-fight checkpoint, state reset on death, ordinary tell/active/recovery contract, guard/dodge/spell interactions, defeat once, award seal once, guardian remains defeated, seal survives process restart, and world feedback reads seal state.

**Human tuning:** check 60–120 second competent first-clear proposal, camera/space safety, tell recognition, effect readability, and no mandatory dependence on spell or shield that would violate future route-order flexibility.

### M2.6 — Accessibility/controller completion and presentation pass

**Implement/verify:** sensitivity controls, invert Y, tested FOV range with locked default, head-bob off/reduced, low/default-off shake, brightness reference, settings persistence, hold/toggle guard, subtitle/caption hooks, UI scale/text-size safe layouts, device prompts, and full controller focus navigation.

**Visual probe checkpoints:** Root-Crown spawn, tree active/save indicator, equipment menu, attribute/respec screen, map before/after discovery, Crowned Hunt landmark, each enemy tell/active frame, vessel use, death, guardian tell, seal acquisition, UI-scale extremes.

Every screenshot runs through Xvfb or a real display. Record reviewer verdicts; image creation alone is not a pass.

### M2.7 — Route smoke and playtest package

**Create:** first-playable smoke and all `playtest/v0.1/` files.

**Automated route smoke should drive stable debug/test hooks, not screen coordinates, and prove:** new profile, tree activation, required pickup/equip, encounter damage/death/reset, shortcut, discovery/map, guardian defeat, seal award, save, process-reload fixture, and persisted final state.

**Package contents:**

- exact build identity and Godot version;
- launch instructions and supported input methods;
- controls and accessibility settings;
- one-sentence route goal without solution markers;
- known issues and reset/save locations;
- feedback prompts matching M2 exit criteria;
- instructions for attaching save, log, and screenshots;
- clean Linux playtest build or reproducible launch bundle.

Do not publish, push, or create a PR automatically. Packaging and distribution location require controller approval.

### M2 exit gate — v0.1 First Playable

All items are mandatory:

- Full import, unit, validation, integration, new route smoke, legacy smoke, bounded startup, and Xvfb screenshot probe pass.
- Fresh-profile 20–30 minute route reaches the first Crown Seal without debug intervention.
- Death/retry works from the last tree; ordinary enemies reset; unique progression, shortcut, map, guardian, and seal state persist.
- Save/load survives a real process restart; corrupt-primary recovery is demonstrated.
- Keyboard/mouse and controller each complete the route and every required menu has valid focus/back behavior.
- Human visual review accepts route readability, HUD/prompts, enemy/guardian tells, map/menu layouts, settings extremes, and seal feedback.
- An uninvolved playtester can navigate without quest markers, identify at least one tell, explain damage taken, and describe unknown-space tension rather than mere slowness.
- No progression blocker, save corruption, or unresolved critical/high-severity defect remains.
- Controller decides whether to commit, open a PR, distribute the build, and/or begin post-v0.1 work.

## 9. Deferred post-v0.1 scope

Defer explicitly; do not partially wire these into v0.1:

- Drowned Reliquary, Plague Warrens, Rootbound Archive, remaining three guardians/seals/release steps, all-four-seal final descent, and fast travel.
- Full six-family enemy roster, three weapon families, two shields, three combat spells, reveal ritual, all encounters/puzzles/secrets, and production content budgets.
- Complete notes/echoes/journal, ending flags/truth table, three endings, final rite, final narrative text/voice.
- Full three-profile UI, optional suspend save, promised migration policy beyond controlled schema handling.
- Full remapping/conflict UI, assist mode, complete captions/subtitles/audio buses, platform-wide accessibility matrix.
- Final production art/audio, Windows export matrix, Steam Deck verification, full performance/load budgets, store builds, localization, achievements, legal/credits/release candidate work.
- Every system listed in the `REQUIREMENTS.md` out-of-scope guardrails.

## 10. Review checklist for each proposed change set

- Requirement IDs and GDD sections are named in tests/review notes.
- Tests failed for the intended reason before implementation and pass afterward.
- Simulation remains deterministic and presentation does not own persistence.
- New cross-reference/persistence fields use stable `StringName` IDs.
- Proposed values remain in Resources; locked 3.2 m/s, 70°, and 0.0022 are unchanged.
- New input works through named actions and is reachable by controller where in scope.
- Scene/resource references load headlessly; real-framebuffer screenshots cover visible changes.
- `project.godot` serialized changes are narrow and inspected.
- Required `.uid` files are included; unexplained UID churn is rejected.
- Prototype files remain present and legacy smoke remains runnable.
- No out-of-scope system or speculative abstraction was introduced.
- No commit, push, branch, or PR occurs without controller/user direction.
