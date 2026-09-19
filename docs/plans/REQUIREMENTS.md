# Royal Forest v0.1 Requirements Matrix

**Baseline:** GDD revision 0.2 (`docs/GAME_DESIGN_DOCUMENT.md`)

**Release slice:** **Royal Forest v0.1 First Playable** — Root-Crown → Crowned Hunt → Hound-King → first Crown Seal

**Purpose:** durable, testable traceability for the rebuild. The GDD remains authoritative for the finished game; this matrix narrows it to v0.1 without redefining it.

## Status policy

| Label | Meaning in this matrix |
|---|---|
| **LOCKED** | Approved design. Change only through explicit design review. |
| **TARGET** | Required outcome for v0.1; implementation and tuning may change while preserving the outcome. |
| **PROPOSED** | Safe data-driven default from the GDD; implement for evaluation, not as a final lock. |
| **PROTOTYPE** | Evidence from the current build only; it is not an acceptance criterion. |
| **TBD** | Owner decision is required. Do not invent or silently lock an answer. |
| **OUT OF SCOPE** | Deliberately excluded from v0.1; architecture must not depend on it. |

A row with mixed labels preserves the status of each clause explicitly. Numeric defaults remain **PROPOSED** unless the row names them **LOCKED**.

## Milestones

| Milestone | Outcome | Exit gate |
|---|---|---|
| **M0 — Executable foundation** | Clean Godot 4.x boot skeleton, replacement input boundary, typed tuning/enemy Resources with stable IDs, explicit player-state ownership, and a dependency-free test runner. | Headless import/startup, unit suite, combat smoke, locked-default checks, and initial ID validation pass. No replacement gameplay system depends on prototype globals. Full cross-system registry, persistence, inventory, world/narrative state, and settings storage are completed incrementally in M2a–M2d before authored route production. |
| **M1 — Combat-feel proof** | Gray-box first-person movement plus attack/dodge/shield stamina loop, damage/death, one complete ordinary enemy, controller baseline, and readable feedback. | Automated checks pass **and a human playtest explicitly accepts each area or assigns bounded follow-up work with an owner. The 2026-09-18 verdict permits M2 systems work while the green-recovery turning change remains queued for combined human review before M2 exit.** |
| **M2 — v0.1 First Playable** | A coherent 20–30 minute Root-Crown → Crowned Hunt → Hound-King route ending in the first persistent Crown Seal, integrating one spell, vessel healing, living-tree save/respawn, attributes/respec, inventory/equipment, map foundation, accessibility basics, controller completion, and a playtest package. | Fresh-profile route completion, process-restart save round trip, death/retry, visual probes, keyboard/mouse and controller checks, and external first-playable playtest all pass with no progression blocker. |

## Traceability matrix

Acceptance criteria are intentionally short and observable. Detailed execution and planned paths live in `docs/plans/REBUILD_PLAN.md`.

Green pursuit and recovery re-aim rapidly (540°/s); orange windup permits only slow limited turning (45°/s); only the red active strike is direction-committed (0°/s).

### Product, movement, and input

| ID | Status | Requirement | Milestone | Acceptance criteria | GDD source |
|---|---|---|---|---|---|
| RF01-PROD-001 | LOCKED | Single-player, first-person dungeon crawler; exploration-led, deliberate real-time melee. | M2 | Exactly one local player completes the route in first person; spacing, observation, and committed actions are required. | §§2.2, 5.1, 6.1 |
| RF01-PROD-002 | TARGET | Deliver Root-Crown → Crowned Hunt → Hound-King → first Crown Seal as one coherent first playable. | M2 | A fresh profile can reach and defeat the guardian, receive the seal once, and return/reload without losing it. | §§11.4–11.5, 12.6, 22.3–22.4 |
| RF01-MOVE-001 | LOCKED | Default forward walk is **3.2 m/s**, default FOV is **70°**, and default mouse sensitivity is **0.0022**. | M1 | Centralized defaults are runtime-observable and exact; tests reject accidental drift. | §§6.1–6.2 |
| RF01-MOVE-002 | PROPOSED | Default strafe 2.9 m/s, backpedal 2.5 m/s, acceleration 10 m/s²; no encumbrance. | M1 | Values are data-driven; stopping is predictable and circle-strafing does not trivialize the test enemy. | §6.2 |
| RF01-MOVE-003 | TARGET | Grounded camera with reducible/disableable motion and collision that does not snag ordinary seams. | M1 | Human test accepts scale, stopping, camera comfort, and seam traversal; head-bob can be disabled. | §§6.1–6.3, 18.1–18.2 |
| RF01-MOVE-004 | TARGET | v0.1 includes toggle crouch as a stance/LOS mechanic, not a broad stealth system: 1.62/0.95 m eye heights, 1.8/1.10 m capsule heights, 4.0 m/s deterministic transition, and 40% movement. | M2b.1 complete | Physical C and D-pad Down toggle crouch; camera/capsule keep feet grounded; low cover hides only the crouched LOS target; standing and dodge fail closed without headroom; attack/cast/heal/guard remain available; no stamina cost or persistence. | §§5.2–5.3, 6.2–6.3 |
| RF01-IN-001 | TARGET | Abstract every gameplay/menu action for keyboard/mouse and controller; show device-appropriate prompts. | M2 | The full route and menus are completable with either input class; active-device prompts update and no gameplay code reads hardware events directly. | §§5.3, 18.1 |
| RF01-IN-002 | TARGET | Context interaction handles checkpoints, pickups, doors, readables, and route mechanisms. | M2 | One action selects the intended nearby target and gives distinct success, missing-requirement, and unavailable feedback. | §§5.2, 13.1, 17.4 |

### Combat, magic, health, and enemies

| ID | Status | Requirement | Milestone | Acceptance criteria | GDD source |
|---|---|---|---|---|---|
| RF01-CMB-001 | LOCKED | One stamina bar governs attacks, universal dodge, and shield guard; there is no combat sprint. | M1 | All three actions spend one resource and fail with feedback when insufficient; sprint does not exist. | §7.3 |
| RF01-CMB-002 | TARGET | Player actions use an explicit delta-driven state machine with committed windup/active/recovery windows. | M1 | Deterministic frame-step tests cover legal transitions, blocked transitions, damage windows, buffering boundary, and recovery; no timer-only hidden truth controls actions. | §§7.1–7.4, 20.2, 20.5 |
| RF01-CMB-003 | PROPOSED | Base stamina 100; attack 25; dodge 30; recovery delay 0.35 s; full base recovery about 2.75 s. | M1 | Tests verify spend, zero-boundary rejection, delay, recovery, and exhaustion; all values live in Resources. | §7.3 |
| RF01-CMB-004 | TARGET | One free-aim light-attack chain; forward-arc multi-hit is allowed but cannot hit through walls or behind the player. | M1 | Collision tests cover one/multiple targets, rear exclusion, and world occlusion; there is no lock-on or directional combo subsystem. | §7.3 |
| RF01-CMB-005 | PROPOSED | Dodge travels about 2.4 m over 0.34 s, grants about 0.20 s invulnerability, costs 30, and has about 0.75 s total recovery. | M1 | Frame-step tests verify distance, invulnerability, cost, and non-chainable recovery; tuning remains data-driven. | §6.2 |
| RF01-CMB-006 | TARGET / PROPOSED | Guard requires an equipped shield (**TARGET**); proposed baseline is 80% reduction, 40% movement, drain plus impact cost, and telegraphed guard break. | M1 | Guard is unavailable without shield; equip enables it; tests cover reduction, movement, stamina drain, exhaustion break, and dodge independence. | §7.3 |
| RF01-CMB-007 | TARGET | Combat feedback makes accepted/blocked actions and damage attribution readable without obscuring the next tell. | M1 | Human tester identifies the enemy tell and explains damage taken; hits combine synchronized visual, audio, and reaction cues. | §§7.1, 7.4, 17.4, 22.2–22.3 |
| RF01-MAG-001 | TARGET / PROPOSED | Include one free-aim combat spell using slowly regenerating mana; M2a implements 100 mana, 25 cost, 2.0 s delay, and 2.5/s recovery as proposed values. | M2a complete; persistence/equipment in M2d | Spectral Bolt is camera-forward with no lock-on; deterministic tests cover spend rejection, cast/damage delay reset, recovery, cast phases, and projectile collisions. Persistence/equipment remain later milestone work. | §7.6 |
| RF01-HP-001 | TARGET | Base HP 100, no passive health regeneration, no injury system, and no general resistance spreadsheet. | M1 | Damage persists until explicit healing/rest/respawn; excluded systems are absent. | §8.1 |
| RF01-HP-002 | TARGET / PROPOSED | Vessel healing is slow and committed: M2b implements three charges, 40% max-HP healing, and 0.80/0.08/0.52-second phases. Damage during windup cancels healing but the committed charge remains spent; after the heal frame, healing cannot be undone. Living-tree refill wiring remains M2c. | M2b complete; living-tree wiring in M2c | Tests cover start, interruption, exact heal frame, immediate commitment spend, post-heal non-cancelability, refill API, max-HP scaling, buffering revalidation, input/HUD integration, and large-delta single application. | §8.2 |
| RF01-EN-001 | TARGET | One complete ordinary enemy has detection/LOS, pursuit/navigation/leash, windup, active strike, recovery, reaction, and death states. | M1 | State tests reject damage outside active windows; gray-box obstacle, occlusion, and leash scenarios pass. | §§12.2, 12.4, 20.2, 20.5 |
| RF01-EN-002 | PROPOSED | Crowned Hunt uses Royal Hound emphasis with Shambler/Crawler support; variants change decisions, not only stats. | M2 | At least two meaningfully different encounters test spacing/patrol observation and lateral evasion without requiring another region’s reward. | §§11.4, 12.5 |
| RF01-BOSS-001 | TARGET / PROPOSED | Hound-King grants the first Crown Seal (**TARGET**); concept, move list, ≤2 phases, one regional mechanic, and 60–120 s competent clear are **PROPOSED**. | M2 | Pre-guardian living tree works; boss follows ordinary tell/punish rules; defeat awards one stable seal once and remains defeated after reload. | §§11.4, 12.6, 22.4 |

### Progression, equipment, world, and persistence

| ID | Status | Requirement | Milestone | Acceptance criteria | GDD source |
|---|---|---|---|---|---|
| RF01-PRG-001 | TARGET | Four allocated attributes: Vitality, Endurance, Might, Insight; allocation and free full respec occur at a living tree outside combat. | M2 | Allocation has visible bounded effects; respec preserves earned points and cannot occur in combat. | §§9.1–9.2 |
| RF01-PRG-002 | PROPOSED | Start attributes at 1, cap 10; Vitality +12/+6 HP, Endurance +8/+4 stamina, Might +8%/+4% damage across the point-5 boundary. Insight uses observable thresholds. | M2 | Unit tests cover points 1–10, the boundary, cap rejection, derived-stat rebuild, and at least one v0.1 Insight-visible hook. | §9.2 |
| RF01-PRG-003 | TARGET | Major discoveries, not ordinary farming, grant attribute points once by stable discovery ID. | M2 | Route contains an authored one-time award; enemy rewards contain none; save/load prevents duplicate award. | §9.1 |
| RF01-INV-001 | TARGET / PROPOSED | Inventory has no weight limit (**TARGET**); v0.1 supports one weapon, one shield-or-focus offhand, one spell, vessel, key/route items, and lore/map objects using proposed slot rules. | M2 | Typed items can be acquired, inspected, equipped/unequipped, used where valid, and round-trip without duplicates or slot violations. | §§9.3, 10.1–10.2 |
| RF01-WORLD-001 | LOCKED / PROPOSED | Finished world is one nexus plus four regions (**LOCKED**); v0.1 builds only the Root-Crown/Crowned Hunt proof route and first seal (**PROPOSED slice**). | M2 | Route has a readable nexus landmark, transition, loop/shortcut, optional risk/secret, locked-route payoff, and guardian approach. | §§11.1–11.5, 22.3–22.4 |
| RF01-WORLD-002 | TARGET | Hand-drawn exploration-filled map foundation; no minimap, compass, quest markers, or undiscovered-secret reveal. | M2 | Exploration reveals authored area/landmark/tree/connection IDs; discoveries persist; excluded navigation aids are absent. | §§11.1, 17.3 |
| RF01-TREE-001 | TARGET | Living trees activate by interaction; rest refills renewable resources/vessel, saves, allows attributes/respec, and resets ordinary enemies. | M2 | One transaction produces all effects with visible save feedback; ordinary enemies reset deterministically. | §§8.3, 19 |
| RF01-DEATH-001 | TARGET / LOCKED | Death returns to the last activated tree and resets ordinary enemies (**TARGET**); there is no dropped-resource/corpse run (**LOCKED**). | M2 | Death/retry restores checkpoint state, clears transient combat state, retains unique progression/shortcut/seal state, and loses no owned resource. | §§8.3, 19.1 |
| RF01-SAVE-001 | TARGET | Versioned save data persists implemented attributes, loadout, inventory, unique pickups, tree, shortcut, guardian/seal, discoveries, map, settings, and playtime using stable IDs. | M2 | Process-restart round trip preserves every field; unknown/malformed versions and unresolved IDs fail safely with controlled recovery. | §§19–19.1, 20.5 |
| RF01-SAVE-002 | PROPOSED | Saves use visible indication and atomic temporary-file replacement; one rolling backup is prepared even if multi-profile UI is deferred. | M2 | Interrupted-write test accepts either old or new valid data, never partial data; backup restores after corrupted primary. | §19 |

### UI, accessibility, quality, and architecture

| ID | Status | Requirement | Milestone | Acceptance criteria | GDD source |
|---|---|---|---|---|---|
| RF01-UI-001 | PROPOSED | Compact HUD communicates HP, contextual stamina, acquired mana, equipment/spell/vessel, prompts, pickups, blocked actions, save, death, and seal acquisition. | M2 | Every immediate resource and route-critical event is understandable with keyboard/mouse and controller; color is never the only signal. | §§17.3–17.4, 18.2 |
| RF01-UI-002 | TARGET | v0.1 menus cover new/continue, pause, settings/controls, inventory/equipment, attributes/respec, and map with valid back paths. | M2 | Each screen is reachable in the right state, pauses consistently, supports both input classes, and cannot strand focus. | §§17.3–17.4 |
| RF01-ACC-001 | TARGET | Accessibility basics: FOV and mouse/stick sensitivity, invert Y, head-bob off/reduced, low/default-off camera shake, brightness, subtitles/captions hooks, UI scale/text-size safe layouts, and hold/toggle guard. | M2 | Settings persist; extremes are visually checked for clipping/readability; disabled motion is absent; held-action modes are behaviorally equivalent. | §§6.1, 18.1–18.2 |
| RF01-ACC-002 | PROPOSED | Mild controller spell aim friction without snapping, hidden melee lock-on, or loss of free aim. | M2 | Controller playtest finds the spell usable; instrumentation/visual review confirms no snap or melee target state. | §18.2 |
| RF01-ARCH-001 | TARGET | Separate simulation/persistence from presentation; authoritative owners are PlayerStats, Inventory, WorldState, NarrativeState, and SaveManager. | M0, completed across M2c–M2d | M0 establishes PlayerStats and the no-`GameState` boundary; M2c adds WorldState, NarrativeState, SaveManager, and save schema v1; M2d adds Inventory. M2e populates route-facing narrative content but introduces no persistence owner. Headless tests cover each owner. | §§20.2, 20.5 |
| RF01-ARCH-002 | TARGET | Weapons, spells, enemies/moves, items, regions, encounters, and checkpoints use typed custom Godot `Resource` records with stable `StringName` IDs. | M0, completed across M2a–M2e | M0 proves the pattern with tuning/enemy records; M2a–M2e add each in-scope record and the complete registry/validator before authored route production. Validator rejects missing/duplicate IDs and unresolved references. | §§20.2, 20.5, 21 |
| RF01-TEST-001 | TARGET | Dependency-free custom test runner covers deterministic simulation; route smoke covers scene integration. GUT may be evaluated but is not assumed. | M0–M2 | Import, unit suite, content validation, route smoke, and bounded startup exit zero as their systems enter scope; tests incrementally add stamina/action/damage (M1), mana/healing (M2a–M2b), save (M2c), attributes/inventory (M2d), and seal award (M2e). | §§20.4–20.5, 22.2–22.4 |
| RF01-VIS-001 | TARGET | Visual verification uses a real framebuffer (native display or Xvfb), not headless rendering alone. | M1–M2 | Automated screenshot probe captures named checkpoints; human review records readable HUD, prompts, geometry, enemy tell/active frame, map/menu, and boss/seal presentation. | §§15, 17, 18, 22.2–22.4 |
| RF01-PKG-001 | TARGET | Produce a reproducible v0.1 playtest package with build identity, controls, known issues, route goal, feedback form, and save/log/screenshot collection instructions. | M2 | A clean Linux package launches and an uninvolved tester can complete/report the route; Windows packaging is deferred unless explicitly requested for this gate. | §§2.5, 22.3–22.4 |

## Stable-ID policy and namespaces

Persistent identity is authored data, never a node name, index, display label, or scene path. IDs are lowercase `StringName` values in `<namespace>.<slug>` form, immutable after use in a save. Renames require an explicit alias/migration entry. Validation fails on an empty ID, duplicate ID within a namespace, wrong namespace, or unresolved reference.

| Namespace | v0.1 use | Representative ID (illustrative, not a locked name) |
|---|---|---|
| `item` | weapon, shield/focus, spell, vessel, key, lore/map objects | `item.hunt_sword` |
| `enemy` | enemy and guardian definitions/variants | `enemy.royal_hound` |
| `enemy_move` | authored tell/active/recovery move records | `enemy_move.hound_lunge` |
| `encounter` | authored encounter placements/reset identity | `encounter.hunt_gate` |
| `region` | Root-Crown and Crowned Hunt | `region.root_crown` |
| `checkpoint` | living-tree activation and respawn | `checkpoint.hunt_guardian_tree` |
| `shortcut` | persistent opened route | `shortcut.hunt_return_gate` |
| `mechanism` | persistent lock/door/route mechanism | `mechanism.hunt_road_seal` |
| `guardian` | defeat and one-time reward source | `guardian.hound_king` |
| `seal` | Crown Seal inventory/world gate state | `seal.crowned_hunt` |
| `pickup` | one-time world pickup instance | `pickup.hunt_shield` |
| `map_area` | discovered area, landmark, tree, connection | `map_area.hunt_terraces` |
| `discovery` | one-time attribute-point award | `discovery.hunt_memorial` |
| `note`, `echo`, `truth` | journal/narrative facts when present | `note.brother_hunt_01` |
| `release_step` | future regional release state; schema reserved, content deferred | `release_step.crowned_hunt` |
| `ending_flag`, `puzzle` | future state; schema may reserve namespace only | `ending_flag.cost_understood` |

## Explicit v0.1 out-of-scope guardrails

These are not backlog invitations inside v0.1. Do not add schema fields, input actions, UI, content dependencies, or speculative abstractions for them unless the controller explicitly revises scope.

- Sprint, jump, climbing, swimming, encumbrance, armor inventory, and broad stealth systems beyond the scoped crouch LOS stance.
- Heavy attacks (unless explicitly approved after the M1 playtest), perfect parries, lock-on, backstabs, headshots, critical-hit RNG, broad elemental/resistance matrices, enemy-on-enemy damage.
- Conventional ranged weapons/firearms and a separate ranged progression tree.
- Crafting, durability, currency, vendors, rarity tiers, random rolls/loot, duplicate equipment, farmable upgrade materials, weapon upgrade trees.
- Procedural generation, open-world streaming, multiplayer, companion AI, factions, NPC schedules, branching dialogue, VR, mobile, and consoles.
- Remaining three regions/seals/guardians, fast travel, final descent, endings, full journal/echo campaign, all six enemy families, all three weapon/spell families, final art/audio/content budgets.
- Manual save-anywhere, active-combat save, suspend save, New Game Plus, promised cross-version migration, and full three-profile UI.
- Minimap, compass, quest markers/objective arrows, persistent ordinary-enemy health bars, and scrolling combat log.
- Automatic commits, pushes, branches, or PRs; those remain controller/user decisions.

## Blockers and non-blockers

### Current blockers

| ID | Blocks | Resolution |
|---|---|---|
| RF01-BLK-001 | Authored M2e route production, not M2 systems work | Complete typed Resources and registry/validation across M2a–M2d, then finish Inventory, WorldState, NarrativeState, SaveManager, and the versioned save contract before route content depends on them. |
| RF01-BLK-002 | M2 exit tuning approval, not M2 systems work | Human M1 verdict on 2026-09-18 permits M2 implementation. The green-recovery turning fix is bounded follow-up work owned by the implementer and remains queued for combined human review with M2. |
| RF01-BLK-003 | Final M1/M2 tuning lock, not initial implementation | Collect playtest evidence for proposed stamina, dodge, guard, mana, healing, enemy, aim-friction, and accessibility values. Keep them data-driven meanwhile. |
| RF01-BLK-004 | Final Hound-King art/audio and polish, not blockout/system work | Decide whether the guardian is a spectral royal hunting beast or crowned keeper and approve its concrete move list. |

### Confirmed non-blockers for v0.1

- Final character names, ages, occupations, letter wording, final region/item/spell names, and polished narrative prose.
- The hopeful/dark/partial ending logic inconsistencies; they block M4 ending writing, not v0.1 state architecture.
- Full-world room allocation, consumable/key/tool counts, final audio event counts, nexus kit sharing, commercial price/storefront/date/localization/achievements, and published hardware requirements.
- Proposed numeric defaults: they can be implemented as Resources and tested now, then tuned at the named human gates.
- Final assets: gray-box geometry and legally usable placeholders are acceptable until visual direction is deliberately approved.

## Open creative decisions

| Decision | Needed by | Constraint / safe interim action |
|---|---|---|
| Hound-King form: spectral beast vs crowned keeper | Before final guardian sprite/audio commission in M2 | Use a mechanics-only blockout with stable `guardian`/`enemy_move` IDs; do not let presentation choice alter combat architecture. |
| Hound-King exact move list and Crowned Hunt region-specific mechanic | Before M2 encounter lock | At most two phases and one region mechanic; every damaging move needs tell/active/recovery data. |
| v0.1 spell acquisition placement | Before M2 route content | Spectral Bolt is the implemented free-aim M2a spell; choose an authored pickup location without making it required for Crowned Hunt completion if broader region order remains flexible. |
| v0.1 Insight-visible hook | Before attribute UI acceptance | Must be observable content, not an invisible percentage; keep full threshold set deferred. |
| Crowned Hunt release-step representation in the slice | Before polished route review | May be a clearly marked preview/state hook; it must not claim the finished narrative act is locked. |
| Root-Crown art kit: dedicated or shared | Before final-art screenshot gate | Gray-box and neutral materials are safe; record the decision before commissioning environment production. |
| Exact route room count | Before M2 blockout lock | Target a 20–30 minute v0.1 route without silently expanding toward the full 30–45 minute production-region budget. |
| Accessibility-basics cutoff for v0.1 | At M2 planning review | The RF01-ACC-001 list is the baseline; full remapping, assist mode, complete caption production, and platform matrices remain post-v0.1 unless explicitly pulled in. |

## Reconciliation notes

- Audit milestone references for the finished game were remapped to the narrower v0.1 **M0/M1/M2** sequence; requirement status and GDD source did not change.
- The first-playable and vertical-slice gates overlap. v0.1 intentionally targets one polished 20–30 minute route while remaining much smaller than the finished Crowned Hunt region.
- Crowned Hunt normally teaches shield use while the Drowned Reliquary supplies a first spell. v0.1 includes both shield and one spell to prove systems, but neither becomes a hidden prerequisite for the other first-region route in later production.
- Current prototype controls, combat numbers, room layout, enemies, and win/restart behavior remain **PROTOTYPE** evidence. Reuse requires an explicit fit decision; implementation does not gain authority by already existing.
