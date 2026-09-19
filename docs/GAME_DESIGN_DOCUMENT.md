# Royal Forest — Game Design Document

> **Status:** Living design specification
> **Revision:** 0.2 — creator decisions and recommended production defaults
> **Last updated:** 2026-09-17
> **Engine target:** Godot 4.4 or a later compatible Godot 4.x release
> **Primary purpose:** Define the game precisely enough that a human or AI implementation team can build it without inventing major design decisions.

## 1. How to use this document

This is the authoritative product and gameplay specification for **Royal Forest**. It describes the intended finished game. It is not a record of every idea and it is not limited to the current prototype.

- `design-notes.md` is the inbox for unfiltered ideas.
- This document contains accepted decisions, explicitly labeled proposals, and open questions.
- The running game is evidence of the current implementation, not automatically the final design.
- When this document and the implementation disagree, resolve the disagreement deliberately; do not silently redefine the design around the code.
- A future implementation agent must not invent an answer for a **TBD** owner decision. It may implement **PROPOSED** defaults when needed, but should keep tuning data-driven and record any deviation.

### 1.1 Decision labels

| Label | Meaning |
|---|---|
| **LOCKED** | Approved. Change only after an explicit design review. |
| **TARGET** | Current intended design. Build and test it, but tuning may change. |
| **PROTOTYPE** | Describes the current build; not yet approved as final. |
| **PROPOSED** | Inferred production default. Safe to prototype without another questionnaire; validate through playtesting before locking. |
| **TBD** | No decision has been made. Do not guess. |
| **OUT OF SCOPE** | Deliberately excluded from the stated release. |

### 1.2 Design hierarchy

When two goals conflict, use this priority order unless a later section explicitly overrides it:

1. The core player fantasy and design pillars
2. Readable, deliberate combat
3. Exploration tension and atmosphere
4. Fairness and player comprehension
5. Content quantity
6. Visual complexity

### 1.3 Decision workflow

To keep design work finite, distinguish **owner decisions** from **implementation defaults**:

- Ask the creators only about decisions that substantially define the fantasy, story, world structure, signature mechanics, tone, scope, or irreversible tradeoffs.
- Infer routine details from the pillars and record them as **PROPOSED** or **TARGET**, with a short rationale.
- Prefer a coherent recommended default over a question about every tuning value, menu behavior, formula, or content count.
- Group the remaining owner decisions into short workshops. Do not recursively turn every answer into another question unless the answer exposes a genuine contradiction or major branch.
- Validate inferred details through prototypes and playtests; tune numbers from evidence instead of questionnaires.

---

## 2. High concept

### 2.1 One-sentence pitch

**TARGET:** *Royal Forest* is a slow, atmospheric first-person dungeon crawler in which the player searches an interconnected and hostile forest realm for their missing brother, who disappeared while seeking a mythical healing goblet for their sick mother.

### 2.2 Genre

- **LOCKED:** First-person dungeon crawler
- **LOCKED:** Single-player
- **TARGET:** Action RPG with deliberate real-time melee combat
- **TARGET:** Exploration-led structure
- **TARGET:** Compact character-building: four bounded attributes, authored equipment sidegrades, three combat spells, and limited route choice within a mostly controlled critical path

### 2.3 Player fantasy

**TARGET:**

> “I am a determined but vulnerable seeker entering the Royal Forest to find my missing brother, and I survive by reading dangerous spaces, controlling distance, and deciding when to block, dodge, fight, or retreat.”

The brothers were close despite living far apart. The missing brother entered the forest seeking a legendary goblet whose water is said to heal any disease or wound, hoping to cure their sick mother. The player is not initially a legendary warrior. This family bond should keep the search emotionally understandable even when the world's larger history remains mysterious.

### 2.4 Target audience

- Players who enjoy slow exploration, oppressive atmosphere, spatial discovery, and learning enemy behavior
- Players comfortable with limited guidance and environmental storytelling
- **TARGET:** Demanding but fair at the default settings, with an optional assist mode that does not change story access or endings
- **TARGET:** No prior classic dungeon-crawler knowledge required; controls and world rules are taught through play rather than genre assumptions

### 2.5 Target platforms and input

- **TARGET:** Windows and Linux desktop
- **TARGET:** Keyboard/mouse and controller support at launch
- **PROPOSED:** Steam Deck verification target, not a separate feature set
- **OUT OF SCOPE:** Consoles, mobile, multiplayer, and VR

### 2.6 Product scope

- **LOCKED:** Intended product is a short, complete commercial game
- **LOCKED:** Target first-completion playtime is 4–6 hours
- **PROPOSED:** Initial commercial positioning in the small-premium-indie range; set the exact price after the vertical slice and market comparison
- **TARGET:** One nexus, four major regions, four regional guardian encounters, six core ordinary-enemy families with limited variants, three weapon families, three combat spells, and three endings

### 2.7 Primary appeal

- **LOCKED:** Exploration and atmosphere are the experience's highest creative priority.
- Combat must sustain tension and make exploration dangerous, but combat complexity is subordinate to the quality of the world, its spaces, and the feeling of uncovering it.
- Story should reward exploration rather than repeatedly stop it.
- Progression should expand meaningful options without turning the game into an optimization-first build simulator.

---

## 3. Design pillars

These pillars should be concrete enough to reject features that do not belong.

### 3.1 Deliberate vulnerability — TARGET

Movement and combat have commitment. The player survives by observing, positioning, and choosing when to act, not by chaining high-speed actions. The player may become more capable, but the world should retain danger.

**Supports:** readable windups, meaningful attack recovery, dangerous corners, scarce recovery, strong hit feedback.
**Conflicts with:** rapid dodge spam, frictionless animation canceling, large enemy crowds, effortless healing.

### 3.2 Exploration under tension — TARGET

Moving into an unknown place should be the main source of suspense. Layout, sound, light, resource state, locked routes, and enemy placement should make each threshold matter.

**Supports:** interconnected spaces, landmarks, shortcuts, optional danger, authored encounters, limited knowledge.
**Conflicts with:** constant objective markers, disposable procedural rooms, excessive fast travel, cluttered maps.

### 3.3 Atmosphere over exposition — LOCKED

The world is communicated primarily through architecture, item placement, enemy behavior, environmental changes, and restrained text. Direct explanation is used sparingly.

**Supports:** visual motifs, short item descriptions, environmental consequences, sound cues.
**Conflicts with:** long compulsory dialogue, frequent cutscenes, tutorial pop-ups, lore dumps.

### 3.4 A legible world with hidden depth — PROPOSED

The player should usually understand what happened in the moment while remaining uncertain about the world's larger meaning. Mechanical opacity is not the same as mystery.

**Supports:** consistent interaction rules and readable attacks; ambiguous history and motives.
**Conflicts with:** unexplained damage, arbitrary locks, invisible rules, plot explanations for every mystery.

### 3.5 Hand-authored density — PROPOSED

A smaller world with purposeful rooms, loops, secrets, and encounter composition is preferred over a larger repetitive world.

---

## 4. Experience goals

### 4.1 Intended emotional arc

**TARGET:** The game becomes very dark, but a genuinely hopeful ending can be earned rather than guaranteed.

Proposed pattern:

1. **Unease:** the player is weak, underinformed, and newly exposed to the world.
2. **Cautious competence:** landmarks, enemy tells, and tools become understandable.
3. **Dread and fascination:** deeper regions reveal greater danger and stranger history.
4. **Earned mastery:** the player navigates and fights with confidence but is not invulnerable.
5. **Consequential discovery:** the ending reframes the player's journey or final choice.

### 4.2 Pacing target

- Exploration is the default state.
- Combat is dangerous punctuation, not continuous crowd-clearing.
- Safe or quiet spaces should exist so tension can recover.
- Major discoveries should alter the player's options, understanding, or route.
- **PROPOSED pacing budget:** Roughly 50–60% exploration/navigation, 20–30% combat, 10% environmental puzzles, and 10% reading/echoes/ending scenes. These are pacing guides, not telemetry quotas.

### 4.3 What the game should not feel like

- **TARGET:** Not a movement shooter
- **TARGET:** Not a loot shower
- **TARGET:** Not a horde combat game
- **TARGET:** Not a quest-marker checklist
- **TARGET:** Not a direct imitation whose identity depends entirely on recognizing *King's Field*
- **OUT OF SCOPE:** Procedural generation, open-world streaming, crafting, durability, randomized loot, rarity tiers, vendors, faction reputation, companion AI, full NPC schedules, stealth, climbing, swimming, and branching dialogue trees

---

## 5. Core gameplay

### 5.1 Core loop

**TARGET:**

1. Enter or return to a hostile area.
2. Observe the space and identify routes, threats, landmarks, and interactables.
3. Commit health, healing-vessel charges, stamina, mana, or time to advance.
4. Fight, evade, unlock, or outmaneuver an obstacle.
5. Discover an item, route, shortcut, character, or piece of world context.
6. Decide whether to press deeper or return to safety.
7. Convert discoveries into lasting progress, then repeat with changed options.

**TARGET:** Health and limited vessel charges are the long-horizon expedition resources. Stamina governs immediate combat commitment; slowly regenerating mana limits spell bursts without requiring routine consumable farming.

### 5.2 Moment-to-moment verbs

| Verb | Status | Intended use |
|---|---|---|
| Walk / strafe | LOCKED | Primary traversal and combat positioning |
| Look | LOCKED | First-person aiming and observation |
| Interact | LOCKED | Doors, containers, mechanisms, NPCs, readable objects |
| Light attack | TARGET | Primary committed melee action |
| Take/use item | TARGET | Pickups, inventory, and contextual use |
| Equip weapon/item | TARGET | Change combat or exploration capability |
| Guard | TARGET | Requires a shield; consumes stamina while held and on impact |
| Dodge / sidestep | TARGET | Universal committed evade with brief invulnerability and stamina cost |
| Crouch | TARGET | Toggle stance to lower eye/collision height and hide behind smaller cover; concealment only, not a broad stealth system |
| Heavy attack | OUT OF SCOPE initially | Add only if light-attack combat is already proven and a weapon needs it |
| Cast magic | TARGET | Free-aim combat spells fueled by slowly regenerating mana |
| Sprint | OUT OF SCOPE | No combat sprinting; authored scale is built around walking |
| Jump | OUT OF SCOPE | No platforming or jump-gated navigation |
| Broad stealth system | OUT OF SCOPE | Crouch provides stance-owned LOS concealment only; no meter, sound AI, sneak attack, or detection multiplier |

### 5.3 Controls — current prototype baseline

| Action | Keyboard/mouse | Status |
|---|---|---|
| Move | WASD | PROTOTYPE |
| Look | Mouse | PROTOTYPE |
| Attack | Left mouse | PROTOTYPE |
| Crouch | C / D-pad Down | TARGET (M2b.1 implemented) |
| Interact | E | PROTOTYPE |
| Release cursor | Escape | PROTOTYPE |
| Restart after death/win | R | PROTOTYPE |

**TARGET:** All gameplay and menu actions are remappable. Controller uses left stick to move, right stick to look, right trigger to attack, left trigger to block, face buttons for dodge/interact/use, and shoulder/D-pad inputs for equipment or spell selection. Exact bindings must be shown in-game and may be changed by the player.

---

## 6. Camera and movement

### 6.1 Camera

- **LOCKED:** First-person perspective
- **LOCKED:** 70-degree field of view is approved for the current feel target
- **LOCKED:** Mouse sensitivity `0.0022` is approved for the current prototype
- **TARGET:** Camera behavior should feel grounded and avoid exaggerated motion
- **PROTOTYPE:** Subtle vertical head bob of approximately 0.035 m while walking
- **PROPOSED:** FOV range 65–85° with 70° default; head bob offers off/25/50/100%; camera shake defaults low and can be disabled

### 6.2 Movement

- **LOCKED:** Walk speed is 3.2 m/s
- **PROTOTYPE:** Acceleration is 10 m/s²
- **PROTOTYPE:** Player collision body is approximately 1.8 m high and 0.8 m wide
- **TARGET (M2b.1 implemented):** Toggle crouch lowers eye height from 1.62 m to 0.95 m and capsule height from 1.8 m to 1.10 m at a clamped 4.0 m/s; feet remain grounded, movement is 40%, and standing/dodging fails closed without headroom; an accepted dodge owns standing stance for its full commitment and ignores crouch toggles
- **TARGET:** Crouching can break enemy LOS behind authored low cover, but adds no visibility meter, sound AI, sneak attacks, detection modifiers, stamina drain, or persistence
- **TARGET:** Movement is slow enough that entering attack range is consequential
- **TARGET:** Strafing supports spacing but should not trivialize all melee enemies
- **PROPOSED:** 2.9 m/s strafe, 2.5 m/s backpedal, 10 m/s² acceleration, no sprint, no encumbrance, and limited but not locked turning during attacks
- **PROPOSED:** Universal dodge travels roughly 2.4 m over 0.34 s, grants about 0.20 s of invulnerability, costs 30 stamina, and has roughly 0.75 s total recovery. Tune from playtests; never permit recovery-free chaining.

### 6.3 Movement acceptance criteria

- The player can predict where they will stop.
- Small collision seams do not snag ordinary movement.
- Enemies cannot be defeated reliably by circling at no cost.
- Camera motion can be reduced or disabled if it causes discomfort.
- The player's physical scale remains consistent across doors, props, and enemies.

---

## 7. Combat system

### 7.1 Combat goals

- **TARGET:** Combat is readable, close, and committed.
- **TARGET:** The player wins by recognizing tells and controlling distance.
- **TARGET:** Taking damage should usually feel attributable to a visible mistake.
- **TARGET:** Hit confirmation should combine animation, sound, enemy reaction, and appropriate effects.
- **TARGET:** Spacing and positioning are the primary defensive layer, supported by limited blocking and dodging.

### 7.2 Current melee prototype

These values document the running prototype and are not locked unless separately marked.

| Parameter | Current value | Status |
|---|---:|---|
| Attack damage | 34 | PROTOTYPE |
| Reach center | 2.4 m | PROTOTYPE |
| Sweep radius | 1.1 m | PROTOTYPE |
| Acceptance cone | Approximately 140° total | PROTOTYPE |
| Swing animation | 0.45 s | PROTOTYPE |
| Attack cooldown | 0.75 s | PROTOTYPE |
| Damage frame | 35% into swing | PROTOTYPE |
| Player maximum HP | 100 | PROTOTYPE |
| Damage invulnerability | 0.4 s | PROTOTYPE |

The current sword is obtained from an interactable chest. Attacking before obtaining it displays an “empty hands” message.

### 7.3 Production combat rules

- **TARGET:** Dodging is a universal player ability. Its limited range, recovery, or resource cost must preserve spacing as the primary defense.
- **TARGET:** Blocking requires an equipped shield. Shields can differ in protection, stability, cost, or other tradeoffs.
- **LOCKED:** One stamina bar governs attacks, dodges, and shield blocks.
- **LOCKED:** There is no combat sprinting.
- **TARGET:** Endurance improves stamina capacity or recovery, subject to bounded scaling.
- **PROPOSED:** Base stamina is 100. Light attacks cost 25, dodge costs 30, and blocking drains 10 per second plus 8–15 on impact. Recovery begins after 0.35 s without spending and restores the base bar in approximately 2.75 s.
- **PROPOSED:** Ordinary hits interrupt unarmored enemies but not bosses or armored windups. Guard break occurs when an impact exhausts stamina; no separate poise statistic is shown.
- **TARGET:** First-person free aim; no lock-on.
- **TARGET:** One primary light-attack chain per weapon. Do not add directional combos or a separate heavy-attack system until the vertical slice proves the need.
- **TARGET:** Attacks may hit multiple enemies visibly inside the forward arc, but never through solid walls or behind the player.
- **LOCKED:** Shield blocks reduce damage by 80%, allow the remaining 20% as chip damage, slow movement to 40%, and can be broken by clearly telegraphed heavy enemy attacks. Perfect parries are out of scope.
- **LOCKED:** Green pursuit and recovery re-aim rapidly (540°/s); orange windup permits only slow limited turning (45°/s); only the red active strike is direction-committed (0°/s).
- **OUT OF SCOPE:** Weapon durability, critical-hit RNG, backstabs, headshots, friendly fire, enemy-on-enemy damage, and a broad elemental/status-resistance matrix
- **TARGET:** Insight enables rituals or magic as well as revealing hidden truths/routes.
- **OUT OF SCOPE:** Conventional bows/firearms and a separate ranged-weapon progression system

### 7.4 Combat readability rules — PROPOSED

1. A damaging enemy action must have a perceivable tell appropriate to its danger.
2. Telegraph speed may vary, but the animation language should remain consistent for that enemy.
3. Active hit timing should match the visible strike.
4. Enemy recovery creates an intentional punish window.
5. Off-screen danger should be rare and signaled through sound or staging.
6. Hitboxes should favor the visible form rather than demand pixel-perfect aim.
7. Effects must not obscure the next important enemy action.

### 7.5 Combat tuning procedure

For each weapon/enemy pairing, record:

- Hits required to kill at expected progression
- Enemy hits required to kill the player
- Safe punish opportunities per enemy attack
- Time to kill when played correctly
- Time and distance needed to disengage
- Whether circle-strafing, doorway abuse, or elevation defeats the behavior
- Subjective ratings for weight, clarity, fairness, and tension

No content expansion should compensate for an unproven core combat loop.

### 7.6 Magic direction — TARGET

Player magic is a compact set of conventional combat spells rather than a large spell catalog. Insight governs access or effectiveness. Spells consume mana, which regenerates slowly enough that repeated casting remains a tactical choice rather than replacing weapons. Exploration rituals and hidden-route interactions may exist, but they should not replace the clear combat-spell foundation.

**PROPOSED:** Three authored combat spells plus one exploration ritual:

1. A straight spectral projectile for safe single-target pressure.
2. A short-range thorn or force burst for creating space.
3. A brief defensive ward that reduces one incoming hit without replacing shields.
4. An Insight-gated reveal ritual for spectral traces, inscriptions, and hidden routes.

Base mana is 100. Combat spells cost 25–45 mana. Regeneration begins about 2 seconds after casting or taking damage and restores 2–3 mana per second. Two spell slots and one focus slot avoid a full spell-tree interface. Spells are found at authored locations; Insight gates access and potency rather than hidden enemy resistance math.

---

## 8. Health, recovery, death, and failure

### 8.1 Health

- **PROTOTYPE:** Player has 100 HP.
- **PROTOTYPE:** Health is shown as a numeric label and bar.
- **TARGET:** 100 base HP, no passive health regeneration, no injury subsystem, and no general-purpose armor-resistance spreadsheet. Equipment may provide one clearly stated defensive trait.

### 8.2 Recovery

**TARGET:** The player's normal field healing comes from a small refillable vessel restored at living trees. Drinking is a slow, committed action that can be interrupted by damage and cannot be canceled after its healing window begins.

**PROPOSED defaults:**

- Begin with three uses; permit one or two authored capacity upgrades.
- Restore 40% of maximum health so Vitality does not devalue healing.
- Use a provisional 0.80-second windup, 0.08-second active healing window, and 0.52-second recovery (1.40 seconds total).
- Spend the charge when the committed action starts. Damage during windup cancels the pending heal and the charge remains lost; once the healing window begins, the applied heal cannot be canceled.
- Refill all uses when resting at a living tree; resting also resets ordinary enemies.
- The vessel does not regenerate between trees and is not replenished by routine enemy drops.
- Rare single-use restorative items may exist, but they must not become the expected healing economy.
- Final use time, heal percentage, capacity, and interruption frame are playtest values.

### 8.3 Death

- **PROTOTYPE:** Death currently shows a death panel and allows an immediate full scene restart.
- **TARGET:** Death returns the player to their last activated checkpoint.
- **TARGET:** Ordinary enemies reset on death.
- **LOCKED:** Death does not create a dropped-resource recovery run.
- **TARGET:** Lasting progression, unique items, opened shortcuts, and major world-state changes remain recorded.
- **TARGET:** Living trees act as checkpoints. Resting or interacting with one records progress and restores health.
- **PROPOSED:** Respawn with full HP, stamina, mana, and vessel charges. Ordinary enemies reset; bosses, unique items, opened shortcuts, major mechanisms, discoveries, map progress, and ending flags persist.
- **TARGET:** Living trees are activated by interaction and can be revisited voluntarily. Resting restores all renewable resources, saves, allocates attribute points, and resets ordinary enemies. Place them about 10–20 minutes apart and immediately before each regional guardian.
- **PROPOSED:** The living trees survive because their roots sit outside or beneath the ancient protection's spiritual binding; this makes them both safe anchors and conduits for released memory.

### 8.4 Failure philosophy

**PROPOSED:** Failure should teach a route, rule, or enemy behavior. Repetition should be short enough to encourage another attempt and costly enough that survival matters.

---

## 9. Character development and progression

### 9.1 Progression model

**TARGET:** Hybrid progression combining modest numerical stats with found equipment and exploration tools.

- Statistics should improve capability without overwhelming player skill or equipment identity.
- Important equipment and tools should be found through exploration, not generated as disposable loot.
- Exploration rewards should include new options and access, not only larger numbers.
- **TARGET:** Major discoveries grant attribute points. Players allocate those points at living-tree checkpoints.
- This makes character growth a reward for exploration rather than repeated enemy farming.
- **PROPOSED:** Award one point for a curated mix of first region entries, regional guardians, major shortcuts, hidden shrines, brother-trail revelations, and release steps. Target 10–12 total points in a normal thorough run.
- **PROPOSED:** Allow free full respec at living trees outside combat. A short game should not permanently punish an early uninformed allocation.

### 9.2 Candidate attributes

**TARGET:** The player allocates points among four attributes:

| Attribute | Intended domain | Exact effects |
|---|---|---|
| **Vitality** | Maximum health | +12 HP per point through 5, then +6; proposed cap 10 |
| **Endurance** | Maximum stamina and recovery | +8 stamina per point through 5, then +4; proposed cap 10 |
| **Might** | Physical weapon effectiveness | +8% damage per point through 5, then +4%; proposed cap 10 |
| **Insight** | Revealing hidden truths/routes and enabling rituals or magic | Content thresholds at 3, 5, 7, and 9; proposed cap 10 |

Each attribute must create an observable gameplay tradeoff and have a clear cap or diminishing-return rule. Avoid secondary statistics unless they materially support equipment or combat decisions.

**PROPOSED:** Start each attribute at 1. Equipment may recommend an attribute but must never become unusable because the player lacks a hard stat requirement. Every Insight threshold must produce an observable spell, route, ritual, echo, or interpretation—not an invisible percentage bonus.

### 9.3 Equipment — PROPOSED production scope

- One equipped weapon
- One offhand slot shared by a shield or spell focus
- Two equipped spell slots
- One exploration-tool slot
- One dedicated healing-vessel input
- No armor inventory, weight, encumbrance, durability, rarity tiers, random rolls, or duplicate equipment
- Three weapon families maximum: balanced sword, slower high-impact axe, and longer-reaching narrow-arc spear
- Two shields maximum: a light shield with lower protection and recovery cost, and a heavy shield with stronger protection and slower movement
- Equipment is discovered as authored sidegrades. Do not build a weapon-upgrade tree for the first release.

### 9.4 Economy

**OUT OF SCOPE:** Currency, vendors, buying/selling, random enemy loot, and farmable upgrade materials. Progress comes from discoveries, equipment finds, route access, and attribute points; death therefore has no currency-loss rule.

---

## 10. Inventory and items

### 10.1 Inventory goals

- Items should support exploration, combat choices, or world understanding.
- Important items should be recognizable in-world and in menus.
- Item descriptions should be concise and written in the world's voice.
- **TARGET:** No carrying-capacity or weight limit. Inventory pressure does not serve the exploration-first design strongly enough to justify its friction.

### 10.2 Item classes

| Class | Status | Examples / purpose |
|---|---|---|
| Weapons | TARGET | Primary combat behavior |
| Armor | OUT OF SCOPE | Avoid a separate armor/stat-comparison layer |
| Consumables | TARGET | Small authored set of cures or temporary utility; no farming economy |
| Key items | TARGET | Route and quest progression |
| Tools | TARGET | Map, reveal ritual, region mechanisms, and release-rite components |
| Spells / catalysts | TARGET | Three combat spells, one focus slot, and Insight-gated acquisition |
| Lore objects | TARGET | Optional environmental context |
| Currency / materials | OUT OF SCOPE | No general economy or crafting system |

### 10.3 Current prototype items

- **Sword:** found in a chest; enables melee attack
- **Rusted key:** collected by contact; opens the locked door to the shrine/exit area

These items establish the prototype loop but are not automatically the opening of the final game.

---

## 11. World structure and level design

### 11.1 World model

- **TARGET:** Hand-authored spaces
- **TARGET:** Distinct landmarks and spatially understandable layouts
- **TARGET:** Locked routes, loops, and shortcuts should turn knowledge into progress
- **LOCKED:** One interconnected world
- **LOCKED:** A central forest nexus connects four distinct major regions.
- **TARGET:** Regions loop back into the nexus and into themselves through unlockable shortcuts, allowing the player's mental map to improve throughout the 4–6 hour journey.
- **TARGET:** Living checkpoint trees should function as memorable landmarks and safe-route anchors within that world.
- **LOCKED:** There is no minimap.
- **TARGET:** A hand-drawn map fills through exploration. It communicates region shape, landmarks, living trees, and major connections without revealing undiscovered secrets.
- **TARGET:** Fast travel between activated living trees unlocks late in the game, after the player has learned the world's main routes.
- **PROPOSED:** Permit harmless alternate order and optional early discoveries, but gate the final two regions behind two regional seals and gate the final descent behind all four. Do not support bypasses that break ending-state logic.

### 11.2 Level-design grammar — PROPOSED

Each substantial region should include:

- A readable entrance and an initial statement of the region's identity
- One or more landmarks visible or audible from multiple positions
- At least one route that loops back or becomes a shortcut
- Optional risk with a meaningful reward
- A change in elevation, visibility, sound, or geometry that alters tension
- Encounters built around the space rather than dropped into neutral rooms
- Environmental evidence of what happened there
- A clear transition or threshold into the next major state

### 11.3 Navigation rules — PROPOSED

- Use architecture, light, sound, color, and silhouettes before UI markers.
- Required routes may be obscure, but they must be inferable.
- Important locked doors should be memorable and easy to revisit.
- Similar corridors need distinguishing landmarks.
- Secrets may be hard to find but should not rely on arbitrary wall-hugging everywhere.
- Enemy placement can teach direction, danger, or ownership of a space.

### 11.4 Current prototype layout

The prototype has three connected spaces:

1. **Spawn room:** contains the weapon chest.
2. **Central hall:** contains three shamblers and the rusted key.
3. **Shrine/exit room:** locked behind the key door and guarded by a faster crawler.

Crossing the final trigger produces the current win state. This is a test course, not a final level specification.

### 11.5 Regions and critical path

The following names and content are **PROPOSED production defaults**. They may be renamed without changing their structural jobs.

#### Central nexus — The Root-Crown

A compact forest basin centered on a colossal living tree growing through the old ceremonial court. It contains the opening checkpoint, first brother note/echo, four sealed roads, recurring orientation landmark, late fast-travel access, and the final descent beneath the roots. Each resolved region visibly weakens a seal and releases more spectral light into the nexus.

#### Region 1 — The Crowned Hunt

- **Identity:** Northern royal hunting terraces, ruined gatehouses, faded banners, elevated forest paths, and roots consuming symbols of privilege.
- **Purpose:** Teach patrol observation, spacing, elevation, and shield use.
- **Critical finds:** Shield, first Crown Seal, and evidence that the kingdom isolated itself from the plague.
- **Guardian:** The Hound-King, a spectral royal hunting beast or crowned keeper with two readable phases.
- **Release step:** Restore the names of hunters and servants erased from the royal memorial.

#### Region 2 — The Drowned Reliquary

- **Identity:** Eastern aqueducts, flooded chapels, cisterns, tarnished gold, and preserved objects that should have decayed.
- **Purpose:** Teach environmental sound, constrained sight lines, water-route controls, and the first combat spell.
- **Critical finds:** Spectral projectile/reveal ritual, second Crown Seal, and proof that the protection altered the goblet accidentally.
- **Guardian:** The Reliquary Warden, a waterlogged guardian using delayed melee and small area-denial zones.
- **Release step:** Return a stolen funerary vessel so named spirits can choose release.

#### Region 3 — The Plague Warrens

- **Identity:** Western quarantine housing, collapsed infirmaries, burial tunnels, sealed doors, bone, and sickly yellow-green remnants.
- **Purpose:** Test healing-vessel management, mixed enemy groups, route memory, and understanding of the kingdom's human cost.
- **Critical finds:** Third Crown Seal, names-of-the-dead record, and the clearest evidence that the spirits retain memory and agency.
- **Guardian:** The Quarantine Saint, a former healer using readable barriers and limited area denial rather than a horde phase.
- **Release step:** Reunite the record of the dead with the unmarked burial chamber.

#### Region 4 — The Rootbound Archive

- **Identity:** Southern underground archive, ritual machinery, dark violet roots, white-gold inscriptions, and the oldest sealed chambers.
- **Purpose:** Combine navigation, Insight thresholds, rituals, magic, and learned combat skills.
- **Critical finds:** Fourth Crown Seal, complete release rite, final brother encounter, and the mechanism beneath the Root-Crown.
- **Guardian:** The Keeper of the Seal, a former royal archivist or collective guardian with two phases and no new subsystem.
- **Release step:** Disable the final compulsory binding so the spirits can make a free collective choice.

#### Critical-path gating

The opening directs the player toward the Crowned Hunt, but the first two regions may be completed in either order. Two seals unlock the Plague Warrens and Rootbound Archive routes; all four seals unlock the nexus descent. Fast travel between activated living trees unlocks after the third regional seal so the late cleanup path is convenient without weakening early spatial learning.

Each region targets 4–6 substantial spaces, two living trees, one major shortcut, one optional secret, and roughly 30–45 minutes on the critical route. Total world budget is approximately 28–36 authored rooms or outdoor spaces.

---

## 12. Encounters and enemies

### 12.1 Enemy design principles

- Each enemy should test a recognizable player skill.
- Silhouette, movement, audio, and telegraph should communicate behavior.
- Variants should change decisions, not only increase numbers.
- Groups should create intentional combinations with escape space and readable pressure.
- Enemies should appear to belong to their location and the world's history.

### 12.2 Current prototype enemy framework

The current state machine is:

`Idle → Chase → Windup → Strike → Recover → Chase`, with a separate dead state.

Enemies activate within a distance threshold, move directly toward the player, telegraph by recoiling, attack if the player remains close enough, and become punishable during recovery. They flash red and receive positional knockback when hit.

### 12.3 Prototype enemies

| Enemy | Role | HP | Speed | Damage | Tell | Recovery | Status |
|---|---|---:|---:|---:|---:|---:|---|
| Shambler | Slow basic pursuer | 60 | 1.5 m/s | 15 | 0.6 s | 0.9 s | PROTOTYPE |
| Crawler | Fast low-health pressure enemy | 35 | 2.6 m/s | 10 | 0.3 s | 0.5 s | PROTOTYPE |

### 12.4 Enemy specification template

Every approved enemy requires:

- Name and one-sentence fantasy
- Region/ecology/faction
- Silhouette and scale
- Primary player skill tested
- Detection and pursuit rules
- Complete move list with tells, active windows, recovery, damage, range, and cooldown
- Defensive reactions and stagger rules
- Navigation and leash behavior
- Group role and dangerous combinations
- Drops/rewards
- Audio cues
- Animation/sprite requirements
- Edge cases and exploit checks

### 12.5 Production enemy roster — PROPOSED

1. **Shambler:** slow basic pursuer; teaches spacing and punish timing.
2. **Crawler:** fast low-health pressure; teaches retreat and early reaction.
3. **Royal Hound:** patrolling lunge attacker; teaches sight lines and lateral evasion.
4. **Thorncaster:** ranged root or spectral projectile user; teaches cover and approach timing.
5. **Drowned Warden:** shielded or delayed melee defender; teaches angle creation and guard pressure.
6. **Plague Mourner:** area-denial/support enemy; teaches target priority without becoming a summoner horde.

The Rootbound Archive may use one late elite variant built from an existing family. Variants change one decision—timing, defense, speed, or group role—not only HP. Target 30–36 authored combat encounters. Ordinary encounters use 1–2 enemies early and 2–3 later; four-enemy groups are exceptional and must provide escape space.

### 12.6 Regional guardians

Use four guardian-scale encounters, one per region, with a living tree immediately before each. Each represents a failed function of the kingdom and grants a Crown Seal. Guardians obey ordinary spacing, stamina, tell, and punish rules; each has at most two phases and one region-specific mechanic. A competent first clear should take roughly 60–120 seconds. The final descent is a ritual/narrative climax, not a fifth combat boss.

---

## 13. Interaction, puzzles, and quests

### 13.1 Interaction

- **PROTOTYPE:** Center-screen ray interaction with a 2.6 m range
- **PROTOTYPE:** Context hint formatted as `[E] action`
- **TARGET:** Interactable state should be visually and mechanically understandable
- **TARGET:** One context-sensitive interact button handles world interactions. Inventory items use an explicit menu action only when context cannot communicate the target safely.

### 13.2 Locks and keys

- **TARGET:** Locks should create route memory, anticipation, or choice—not only errands.
- **TARGET:** Keys and ritual tools are permanent unless their one-time surrender is a visible narrative act.
- **PROPOSED:** Prefer named keys, water/root mechanisms, seal states, and Insight-revealed knowledge gates. Do not use mandatory stat checks.
- **PROPOSED:** Optional locks may have alternate Insight or route solutions; critical gates use explicit authored prerequisites.

### 13.3 Puzzles

**PROPOSED:** Use 3–5 authored environmental puzzles across the game, based on observation, symbols, water routing, light, or memorial order. Avoid inventory-combination puzzles. Every solution must have visible or audible evidence nearby and provide feedback after each correct step.

### 13.4 NPCs and quests

**TARGET:** No quest hub, branching dialogue tree, NPC schedule, or conventional quest checklist. The brother and trapped spirits are the recurring narrative presences. A lightweight journal records notes, spectral echoes, learned truths, and release steps without marking the next objective on the world.

---

## 14. Narrative and worldbuilding

### 14.1 Premise

**TARGET:** Two close brothers live far apart while their mother suffers from a grave illness. One brother follows old stories into the Royal Forest seeking a lost goblet said to heal any disease or wound with a single sip. When he does not return, the protagonist enters the forest to find him. The protagonist's immediate objective is rescue; the goblet is initially important because it may save both the missing brother's purpose and their mother.

**PROPOSED:** The missing brother remained near their mother while the protagonist lived elsewhere for work or obligation. He entered the forest several weeks before the game after finding a fragment of a royal pilgrimage record. A final letter and a missed promised return lead the protagonist to the forest. Names, exact occupations, and family ages belong to the narrative-writing pass and do not block implementation.

The search should leave a recent, traceable trail. The player finds written and audio clues left by or connected to the brother, building a picture of his route and condition. The brothers do not meet directly until late in the game.

**TARGET:** The goblet's healing power is genuine, but using it has a serious cost or condition. The player should be able to discover enough evidence to understand that cost before the decisive use.

**LOCKED:** The goblet heals only after the willing sacrifice of a person's life.

**PROPOSED:** Consent cannot be inferred or coerced. The release rite restores the trapped spirits' names and agency, then presents a clear collective choice. Only their affirmative response enables the goblet's final healing.

### 14.2 Setting framework — PROPOSED

- “Royal Forest” is the surviving outside-world name for the sealed forest and the ruined kingdom inside it.
- The monarchy and living civilization are gone; only trapped spirits, transformed guardians, root-bound creatures, and ritual machinery remain.
- Royal roads, hunting grounds, reliquaries, quarantine districts, archives, and root chambers explain the built spaces within and beneath the forest.
- The recurring visual language combines crowns, cups, roots, sealed circles, names scratched into stone, faded royal red, pale spectral blue, and living green.
- The protagonist initially wants only to find the brother and bring the goblet home. Exploration reveals that using it responsibly requires freeing the spirits rather than exploiting another life.

### 14.2.1 Origin of the curse — TARGET

An ancient civilization enacted a great protection to seal its kingdom away from a plague killing the outside world. The protection prevented the kingdom's people from dying of the plague, but it trapped the civilization's spirits and became or produced the forest's curse. Its effects changed the goblet unintentionally, introducing the requirement for a willing life before the goblet can heal.

**TARGET:** Resolving the curse means releasing the trapped spirits and allowing the old kingdom to die rather than preserving it indefinitely.

**PROPOSED:** The outside plague ended generations ago, but the isolated kingdom never learned this. Its protection bound every protected life to the kingdom's root network so no infected body could complete death. Over generations, bodies failed while minds remained tethered as spirits. The goblet was inside that network; its healing changed from freely restoring life to moving life force from a consenting source. Restoring names and disabling one binding mechanism in each region returns agency to the spirits; the final rite lets them choose collective release.

### 14.3 Narrative delivery — TARGET

Use a layered approach:

- **Required layer:** the player understands their immediate objective and major consequences.
- **Discoverable layer:** exploration and item context explain places, factions, and events.
- **Interpretive layer:** deeper history and motives remain open to evidence-based interpretation.

The brother's trail is presented through written notes and short voiced spectral echoes. Other dialogue remains sparse. Environmental evidence and concise item descriptions carry supporting history; the game does not rely on long cinematic scenes or fully voiced conversations.

**PROPOSED content budget:** Approximately 12 brother notes, six spectral echoes, and three optional environmental traces. Provide a brother-related discovery every 20–30 minutes. Notes should take under 30 seconds to read; echoes should last 10–25 seconds. Every critical fact appears in at least two forms, such as a note plus environmental evidence.

### 14.4 Tone

- **LOCKED:** Very dark, but with a genuinely hopeful ending that must be earned
- **TARGET:** Somber, lonely, uncanny, and restrained
- **TARGET:** Beauty should coexist with decay and danger
- **PROPOSED:** Psychological and spectral horror are welcome; graphic gore, dismemberment, torture imagery, and joke-driven tonal breaks are out of scope. Brief humane warmth comes through the brothers' relationship and memories rather than comic relief.

### 14.5 Endings

**TARGET:** At least one ending offers genuine hope, but the player must earn it through discovery, choices, or preparation rather than receive it automatically.

**LOCKED:** The hopeful outcome must accomplish all three central goals: rescue the brother, heal the mother, and resolve the forest's curse.

**TARGET:** In the hopeful ending, the trapped spirits willingly surrender their remaining existence together. Their release ends the curse and empowers one final healing from the goblet. The brother survives, carries or helps carry the goblet home, and the mother's illness can be healed.

The spirits' consent and the player's work to make their collective release possible must be established through discoveries and actions, not introduced only in the final scene.

**LOCKED:** The game targets three endings:

1. **Failure / dark ending:** everyone dies—the mother and both sons—and the trapped spirits are not meaningfully freed.
2. **Partial ending:** the crisis is only partly resolved and at least one family member dies. The exact survivor/death combinations and curse outcome depend on final prerequisites and choices.
3. **Secret fully hopeful ending:** both brothers and their mother live. The trapped spirits willingly provide the sacrifice required by the goblet as they are released, ending the curse and empowering the final healing.

**PROPOSED ending state:** Use explicit flags, not a morality score: brother found, goblet recovered, goblet cost understood, release truth understood, four regional release steps, and final rite completed.

- **Secret hopeful:** brother and goblet recovered; cost and release understood; all four release steps completed; final rite performed.
- **Partial:** the player reaches the finale with enough understanding to avoid total failure but lacks one or more release steps. The brother may live while the mother remains unhealed, or a family member may willingly die to activate the goblet.
- **Dark:** the player reaches the finale without understanding the cost or enabling a meaningful release. The attempted use consumes lives, both sons and the mother die, and the spirits remain trapped.

The finale must state through action and imagery why the achieved outcome occurred. Missing requirements should be foreshadowed rather than revealed as arbitrary ending math.

---

## 15. Art direction

### 15.1 Current visual direction

- **LOCKED:** Sprite enemies billboarded in a 3D world are part of the project's design DNA.
- **LOCKED:** Final identity combines PS1-style low-poly 3D spaces, pixel-art billboard creatures, and modern readable lighting.
- **TARGET:** Low-resolution texture work with nearest-neighbor character
- **TARGET:** Dark spaces, fog, warm torchlight, and readable silhouettes
- **TARGET:** Geometry and materials evoke the limitations and strong shapes of early 3D games without reproducing their control problems, low visibility, or unstable image quality.

### 15.2 Production art standards — PROPOSED

- Render cleanly at 1280×720 and scale to common desktop resolutions; test 1280×800 and 1920×1080.
- Use 128×128 or 256×256 environment textures where practical, nearest-neighbor filtered, with consistent texel density.
- Author ordinary enemies as four-direction billboard sprites; reserve eight directions for a guardian only if the fight cannot read otherwise.
- Ordinary-enemy animation minimum: idle, locomotion, alert, attack, hurt, and death. Guardians add a second attack, reposition/defense, and phase transition.
- Use one modular architecture kit, one dominant material family, and one accent family per region.
- UI uses high-contrast light text on dark translucent panels, restrained royal ornament, clear icons, and a legible font rather than simulated low-resolution text.
- No graphic gore or dismemberment. Body horror is conveyed through silhouette, posture, roots, water damage, and spectral distortion.

#### Region palettes

- **Root-Crown:** deep green, warm amber, pale spectral blue
- **Crowned Hunt:** moss green, faded royal red, cold moonlight
- **Drowned Reliquary:** blue-black water, tarnished gold, cyan spectral light
- **Plague Warrens:** brown-black stone, desaturated bone, sickly yellow-green accents
- **Rootbound Archive:** dark violet, root red, restrained white-gold ritual light

### 15.3 Visual readability rules — PROPOSED

- Gameplay-critical silhouettes must survive fog and low light.
- Interactables need consistent cues without glowing indiscriminately.
- Enemy attack frames must read against common backgrounds.
- Lighting should create tension without hiding required navigation information.
- Pixel-art assets must use consistent filtering and pixel density.

---

## 16. Audio direction

### 16.1 Audio goals

- Sound should reveal unseen space, danger, and material.
- Silence and sparse ambience are tools, not missing content.
- Enemy tells need distinctive cues where visuals alone are insufficient.
- Impacts must reinforce timing and weapon weight.

### 16.2 Production direction — PROPOSED

- Prioritize positional ambience and enemy tells over a large soundtrack.
- Use one ambient bed per region and altered nexus ambience as seals are released.
- Music is sparse: an exploration theme, layered guardian cue system, and final-ritual theme rather than a unique full track for every encounter.
- Combat begins with short stings or added layers; ordinary fights do not require continuous combat music.
- Voice only short brother echoes and essential spirit responses. The protagonist has restrained exertion/hurt sounds but no frequent voiced commentary.
- Provide separate master/music/effects/voice sliders, a reduced-dynamic-range mode, subtitles with speaker labels, and captions for important off-screen enemy or world cues.

### 16.3 Minimum audio event categories

Footsteps by material; weapon windup/swing/impact; enemy alert/attack/hurt/death; player hurt/death; doors/locks/mechanisms; item pickup/use; fire and environmental loops; region ambience; UI confirmation/error; discovery and boss cues.

---

## 17. User interface and user experience

### 17.1 HUD philosophy

**TARGET:** Show what the player needs to make immediate decisions while preserving the world's visual focus.

### 17.2 Current prototype HUD

- HP bar and numeric HP
- Center interaction hint
- Temporary message line
- Damage vignette
- Death screen
- Win screen

### 17.3 Required screens — TARGET

Main menu; continue/new game/profile selection; pause; settings and controls; inventory/equipment; attributes; hand-drawn map; journal for notes/echoes/truths; item inspection; save/profile management; credits; and ending flow.

**PROPOSED HUD:** HP remains visible; stamina appears while active and fades after 1–2 seconds; mana appears after magic is acquired; equipped weapon/offhand/spells and vessel charges use a compact cluster; interaction prompts and short messages remain contextual. Do not add a compass, quest markers, persistent enemy health bars, or a scrolling combat log.

### 17.4 Feedback requirements — PROPOSED

- Every input should provide an understandable response when accepted, blocked, or unavailable.
- Pickups identify what was acquired and where it went.
- Locked interactions distinguish missing requirements from unusable objects.
- Damage communicates source and amount strongly enough to learn from it.
- Menus pause gameplay consistently outside transitions and ending sequences.

---

## 18. Accessibility and settings

Accessibility is part of the design, not a final polish task.

### 18.1 Required settings — TARGET

- Remappable keyboard/mouse and controller inputs
- Mouse and stick sensitivity
- Invert Y
- FOV adjustment within tested bounds
- Head-bob reduction/disable
- Camera-shake reduction/disable
- Separate master/music/effects/voice volume
- Subtitle and caption options if dialogue or important off-screen cues exist
- Brightness/gamma calibration that does not erase intended darkness
- Fullscreen/windowed/borderless and resolution options

### 18.2 Production accessibility defaults — PROPOSED

- UI scale range 80–150% and at least two text sizes
- Hold/toggle alternatives for block and other held actions
- Color-independent shapes, animation, and sound for critical feedback
- Mild controller aim friction for spells, never camera snapping or hidden melee lock-on
- Input buffering for attack/dodge near recovery completion, tuned to preserve commitment
- Optional assist mode: 15% more maximum HP, 25% stronger vessel healing, 20% lower enemy damage, and slightly longer enemy tells; no content or ending lockout
- Brightness calibration preserves intended blacks while keeping required routes, enemies, and prompts readable

---

## 19. Save, load, and persistence

**TARGET:** Living trees are diegetic checkpoints and the primary durable-save locations.

**PROPOSED save model:**

- Three player profiles, each with a current checkpoint save and one rolling backup
- Autosave when resting at a living tree, defeating a guardian, completing a release step, acquiring a unique item, or changing an ending flag
- Visible save indicator; atomic temporary-file replacement to reduce corruption risk
- Optional single-use suspend save on quit outside combat, restoring exact player position/resources and then deleting itself after successful load
- No manual save-anywhere, saving during active combat, New Game Plus, or promised cross-version migration for the first release

### 19.1 Minimum persistence inventory

Persist attributes, equipment, inventory, unique pickups, activated trees, opened shortcuts, major mechanisms, defeated guardians, release steps, brother clues, discovered map areas, ending flags, settings, and playtime. Ordinary enemy deaths and transient combat state do not persist across rest/death. The checkpoint save stores the tree ID rather than an arbitrary scene path; the suspend save additionally stores exact player transform and renewable resources.

---

## 20. Technical and implementation constraints

### 20.1 Technology

- **LOCKED for current project:** Godot 4.x
- **TARGET:** GDScript unless a measured need justifies another language
- **TARGET:** Desktop-first renderer compatible with Windows and Linux
- **TARGET:** GL Compatibility renderer unless the vertical slice demonstrates a visual requirement it cannot satisfy
- **PROPOSED:** Minimum target comparable to a four-core desktop CPU, 8 GB RAM, and a Vulkan/OpenGL-capable integrated or entry-level discrete GPU from roughly 2018 onward

### 20.2 Implementation principles for AI-assisted development

1. Treat approved rules as data where practical: items, enemies, encounters, dialogue, and progression should not require unrelated code edits.
2. Separate simulation/state from presentation so combat can be tested without final assets.
3. Use stable IDs for persistent content; do not save scene paths as the only identity.
4. Keep tunable gameplay values centralized and named.
5. Add automated tests or headless validation for deterministic rules and content references.
6. Preserve explicit state transitions for enemies, interactions, quests, and game flow.
7. Avoid building unresolved systems “just in case.”
8. Every implemented feature needs acceptance criteria derived from this document.
9. Record intentional deviations from the GDD instead of silently diverging.
10. Placeholder content must be labeled and replaceable without redesigning systems.

### 20.3 Performance targets — PROPOSED

- 60 FPS target at 1920×1080 on recommended desktop hardware; stable 30 FPS minimum on supported low-end hardware
- Verify 1280×800 Steam Deck-class performance if Deck remains a launch target
- Initial load under 10 seconds and region transitions under 5 seconds from SSD; ordinary save completion under 0.5 seconds
- Maximum four ordinary enemies actively pressuring the player, six simulated nearby, and one guardian encounter at a time
- Limit shadow-casting dynamic lights by room/visibility cell; prefer static or unshadowed supporting light where possible
- Common enemy sprites at 256 px-class resolution or below and consistent pixel density; particle effects must not hide active attack tells

### 20.4 Existing validation commands

```sh
~/.local/opt/godot --headless --import .
timeout 12 ~/.local/opt/godot --headless .
```

The repository also contains a smoke-test scene and script under `tools/`.

### 20.5 Recommended runtime architecture

Do not continue expanding the current `GameState` with unrelated booleans. Split responsibilities behind stable interfaces:

- **PlayerStats:** HP, stamina, mana, attributes, derived values, damage, and recovery
- **Inventory:** stable item IDs, equipment slots, vessel charges, spells, and key items
- **WorldState:** activated trees, shortcuts, mechanisms, guardian defeats, pickups, map discovery, and region seals
- **NarrativeState:** notes, echoes, learned truths, release steps, brother state, and ending evaluation
- **SaveManager:** versioned serialization, atomic writes, backups, profiles, checkpoint saves, and suspend saves
- **Content resources:** Godot `.tres` resources or equivalent typed data for weapons, spells, enemies, items, regions, encounters, and checkpoints

Every persistent object needs a stable authored ID. Presentation nodes call simulation/state APIs rather than owning save-critical truth. Headless tests must cover stamina spending/recovery, damage/invulnerability, attribute formulas, healing interruption, inventory persistence, save/load round trips, and every ending-prerequisite combination.

Before creating complex final rooms, replace distance-only enemy detection and direct pursuit with line-of-sight checks, leash rules, and navigation that handles authored obstacles. Keep the procedural prototype layout for combat experiments; construct production regions as authored scenes or data-driven room assemblies.

---

## 21. Content specification format

Before broad production, define machine-readable schemas or consistent resources for the following.

### 21.1 Weapon record

- Stable ID and display name
- Description and lore text
- Weapon class
- Requirements
- Base damage and damage types
- Complete action timings
- Range/hit shape
- Stamina/resource costs
- Stagger/knockback
- Upgrade path, or explicit `none` for authored sidegrades
- Equip model, viewmodel, icon, audio, effects
- Acquisition and drop rules

### 21.2 Enemy record

Use the full template in section 12.4, with numeric move data and content references.

### 21.3 Item record

- Stable ID, name, class, stack limit, optional value, and description
- Use/equip behavior
- Persistence rules
- World model/icon/audio
- Acquisition and removal conditions

### 21.4 Region record

- Stable ID and display name
- Connections and gates
- Checkpoints and shortcuts
- Encounter list
- Key items and critical path
- Optional content and secrets
- NPC/quest states
- Art, lighting, weather, and audio identity
- Entry/exit/loading behavior

---

## 22. Production plan and gates

### 22.1 Current vertical-slice sequence

1. **Movement room** — implemented; feel values approved
2. **Combat versus a dummy/enemy** — implemented in prototype form
3. **Damage, death, and restart** — implemented in prototype form
4. **Dungeon route with key and locked door** — implemented as a three-room test course
5. **Atmosphere pass** — initial fog, lighting, sprites, and animated torches implemented
6. **Real playtest verdict** — recorded 2026-09-18: proceed to M2 systems work; green-recovery turning feel remains one bounded follow-up for combined M2 review

### 22.2 Recorded M1 gate and next review

The 2026-09-18 playtest verdict permits M2 systems work. The following areas were accepted or assigned bounded follow-up work in `playtest/m1/README.md`; the green-recovery turning feel and route-dependent rhythm/exploit checks remain queued for the combined M2 review:

- Movement speed and acceleration
- Camera behavior
- Attack weight, range, arc, timing, and recovery
- Enemy tell, strike, and punish timing
- Damage, knockback, and death feedback
- The basic rhythm of exploration into combat

### 22.3 Definition of vertical-slice success — PROPOSED

A new player can complete a 10–20 minute authored route containing exploration, a weapon discovery, at least two meaningfully different encounters, a locked-route payoff, death/retry, and a final discovery. They can explain why they took damage, identify at least one enemy tell, navigate without a quest marker, and report that proceeding into the unknown feels tense rather than merely slow.

### 22.4 Full-production gates — PROPOSED

1. **Pre-production complete:** GDD revision accepted; movement/combat playtest passes; data and save architecture agreed; scope caps recorded; one region blockout proves scale.
2. **First playable:** Stamina, dodge, shield, one weapon, one spell, one living tree, death/respawn, one complete enemy, map discovery, and durable save/load work together in a gray-box route.
3. **Vertical slice:** One polished 20–30 minute Root-Crown/Crowned Hunt route demonstrates final art target, ambience, brother clue, shortcut, release step, guardian, accessibility basics, and performance target.
4. **Alpha / systems complete:** All player systems, all six enemy families, four guardians in blockout, all region routes, all ending flags, and full save flow are implemented. No new core systems after this gate.
5. **Content complete:** All rooms, encounters, notes, echoes, items, spells, art, audio, endings, and credits exist. Remaining work is fixes, tuning, optimization, and accessibility.
6. **Beta:** Full game is completable on Windows/Linux with keyboard/mouse and controller; all endings verified; save corruption/recovery tested; external playtests produce no progression blockers.
7. **Release candidate:** Performance budgets pass on minimum/recommended hardware; clean-install/export/store builds pass; legal/credits/settings are final; no known critical or high-severity defects.
8. **Launch:** Signed/tagged release artifact matches the approved candidate; storefront materials and support path are live; post-launch fixes do not expand scope.

---

## 23. Remaining work, not another questionnaire

The GDD now contains enough direction to design the vertical slice and production architecture. Do not reopen broad discovery interviews before prototyping. Remaining work falls into three bounded categories.

### 23.1 Validate through play

- Final attack, dodge, shield, stamina, mana, healing, and enemy timing values
- Whether three weapon families and three spells each create a distinct useful choice
- Living-tree spacing and whether 10–20 minute retry routes feel fair
- Region length, encounter density, navigation clarity, and the map's reveal cadence
- Assist-mode values and controller aim friction

### 23.2 Complete through authored content passes

- Character names, exact ages/occupations, and the final letter's wording
- Final region/guardian/item/spell names
- Exact notes, echoes, item descriptions, memorial text, and ending scenes
- Guardian move lists and each room's encounter composition
- Final music style, sound palette, texture palette, iconography, and typography assets

These are writing/art tasks inside the defined framework, not prerequisites for system implementation.

### 23.3 Commercial decisions after the vertical slice

- Exact price and storefronts
- Minimum/recommended hardware published to customers
- Age rating/content descriptors
- Launch date, localization scope, achievements, and Steam Deck support level

No additional region, enemy family, major system, ending, or content category should be added unless it replaces an existing scope item or a playtest demonstrates that the core experience cannot work without it.

---

## 24. Decision log

| Date | Decision | Status | Rationale / evidence |
|---|---|---|---|
| 2026-09-18 | Use three vessel charges, 40% max-HP healing, and provisional 0.80/0.08/0.52-second phases; spend an accepted use immediately, so damage before the heal frame interrupts healing and loses the charge | TARGET / PROPOSED | Makes the drinking commitment and interruption cost explicit while retaining exact timings as playtest values |
| 2026-09-18 | Accept the M2b healing economy for first-playable playtesting: the new healing additions work great, including 0.80/0.08/0.52 timing and loss of a charge when windup is interrupted | ACCEPTED FOR FIRST PLAYABLE / PROVISIONAL UNTIL M2 EXIT | Human playtest acceptance unblocks M2c while preserving the final M2 exit tuning review |
| 2026-09-18 | Add crouch to v0.1 as a standalone stance/LOS mechanic using physical C and D-pad Down; retain broad stealth as out of scope | TARGET | Lets the player hide behind smaller authored cover without adding a stealth subsystem |
| 2026-08-23 | Walk speed is 3.2 m/s | LOCKED | Approved after movement prototype review |
| 2026-08-23 | Current mouse sensitivity and 70° FOV | LOCKED | Approved after movement prototype review |
| 2026-08-23 | Use sprite enemies in a 3D world | LOCKED | Core visual/design DNA |
| 2026-08-23 | Atmosphere over exposition | LOCKED | Core project direction |
| 2026-08-23 | Validate the combat loop before adding broad content | LOCKED | Scope control for the first game |
| 2026-09-17 | Establish this GDD as the authoritative accepted-design document | TARGET | Intended to support detailed collaboration and future AI implementation |
| 2026-09-17 | Build a short, complete commercial game | LOCKED | Keeps the first project finishable while targeting a real release |
| 2026-09-17 | The protagonist enters the forest to find their missing brother, who sought a lost treasure | TARGET | Establishes an immediate personal objective; character and treasure details remain open |
| 2026-09-17 | Prioritize exploration and atmosphere above other feature areas | LOCKED | Defines where limited production effort should create exceptional quality |
| 2026-09-17 | Base defense on spacing with limited blocking and dodging | TARGET | Preserves deliberate vulnerability while allowing more than one defensive response |
| 2026-09-17 | Build one interconnected world | LOCKED | Supports spatial learning, route memory, shortcuts, and discovery |
| 2026-09-17 | Use modest stats plus found equipment and exploration tools | TARGET | Supports character growth without making optimization the primary appeal |
| 2026-09-17 | Return the player to a checkpoint and reset ordinary enemies on death, without dropped-resource recovery | TARGET | Creates consequence and route mastery without adding a corpse-run economy |
| 2026-09-17 | Make the game very dark but allow an earnable genuinely hopeful ending | LOCKED | Protects the intended tone while making player effort capable of meaningful good |
| 2026-09-17 | The missing brother sought a mythical goblet to cure the brothers' sick mother | TARGET | Connects the treasure hunt to a close family bond and urgent humane motive |
| 2026-09-17 | Reveal a recent trail through written/audio clues and delay the direct reunion until late | TARGET | Makes the search structure support exploration while preserving uncertainty and anticipation |
| 2026-09-17 | The goblet truly heals, but using it has a serious discoverable cost or condition | TARGET | Preserves the legend's value while creating the central moral and exploratory problem |
| 2026-09-17 | Require the hopeful ending to rescue the brother, heal the mother, and resolve the forest's curse | LOCKED | Makes hope a complete resolution rather than a single-object success |
| 2026-09-17 | Use Vitality, Endurance, Might, and Insight as player-allocated attributes | TARGET | Provides compact, legible build choice with room for physical and occult play styles |
| 2026-09-17 | Use living trees as checkpoints that record progress and restore health | TARGET | Makes persistence part of the forest's fiction and gives routes memorable anchors |
| 2026-09-17 | Require a willing sacrifice before the goblet can heal | LOCKED | Makes the genuine miracle costly and central to the ending problem |
| 2026-09-17 | An ancient civilization's protection from the dying outside world caused the forest's curse and unintentionally altered the goblet | TARGET | Connects the world's condition, its history, and the central artifact |
| 2026-09-17 | Use Insight to reveal hidden truths/routes and enable rituals or magic | TARGET | Makes knowledge an exploration mechanic as well as a build choice |
| 2026-09-17 | Grant attribute points for major discoveries and allocate them at living trees | TARGET | Rewards exploration directly and avoids grind-based leveling |
| 2026-09-17 | Make dodging universal and require a shield to block | TARGET | Keeps a baseline defensive response while making stronger defense an equipment choice |
| 2026-09-17 | The goblet requires the willing sacrifice of a life | LOCKED | Gives the healing miracle a direct, irreversible moral cost |
| 2026-09-17 | A plague killed the outside world; the kingdom's protection prevented plague death but trapped its people's spirits | TARGET | Defines the protection's original purpose and the curse's human consequence |
| 2026-09-17 | Resolve the curse by releasing the trapped spirits and allowing the old kingdom to die | TARGET | Frames preservation without release as the wrong outcome |
| 2026-09-17 | Use a compact set of conventional combat spells | TARGET | Keeps magic legible and achievable within the short game's scope |
| 2026-09-17 | Award discovery points through a curated mix of regions, bosses, secrets, and quest resolutions | TARGET | Rewards multiple forms of meaningful exploration without requiring exhaustive completion |
| 2026-09-17 | Target a 4–6 hour first completion | LOCKED | Keeps the commercial first game complete, replayable, and achievable |
| 2026-09-17 | Let the trapped spirits willingly surrender their remaining existence to break the curse and empower one final healing | TARGET | Reconciles all three hopeful-ending goals without sacrificing either brother |
| 2026-09-17 | Build a central forest nexus connecting four major regions | LOCKED | Gives the short game strong spatial identity, route choice, and recurring landmarks |
| 2026-09-17 | Use one stamina bar for attacks, dodges, and shield blocks, with no combat sprinting | LOCKED | Makes every committed combat action share one legible constraint |
| 2026-09-17 | Fuel combat spells with slowly regenerating mana | TARGET | Supports repeatable magic while preventing unrestricted spell replacement of melee combat |
| 2026-09-17 | Use PS1-style low-poly spaces, pixel-art billboard creatures, and modern readable lighting | LOCKED | Establishes a cohesive achievable visual identity without inheriting avoidable retro usability problems |
| 2026-09-17 | Use no minimap, an exploration-filled hand-drawn map, and late fast travel between living trees | TARGET | Preserves spatial learning while reducing late-game backtracking |
| 2026-09-17 | Heal through a small refillable vessel restored at living trees with a slow committed use | TARGET | Creates a clear press-forward resource without consumable farming |
| 2026-09-17 | Present the brother's trail through notes and short voiced spectral echoes, with sparse dialogue elsewhere | TARGET | Gives the search an emotional voice while keeping production and exposition restrained |
| 2026-09-17 | Target dark, partial, and secret fully hopeful endings | LOCKED | Makes complete hope an exploration-earned outcome while preserving meaningful failure and compromise |
| 2026-09-18 | Keep 80% shield reduction with the remaining 20% as chip damage | LOCKED | Human M1 playtest accepted chip damage as appropriate pressure; stamina impact and guard-break feedback remain part of the block response |
| 2026-09-18 | Green pursuit and recovery re-aim rapidly (540°/s); orange windup permits only slow limited turning (45°/s); only the red active strike is direction-committed (0°/s). | LOCKED | Preserves readable dodge counterplay during the committed strike without allowing free perpetual circle-strafing between attacks |
| 2026-09-18 | Proceed from the accepted M1 combat slice into M2 systems work; complete registry, persistence, inventory, world/narrative state, and settings foundations in M2a–M2d before authored route production | LOCKED | The playable-slice-first sequence produced faster human feedback while retaining hard architecture gates before persistent route content depends on those systems |

---

## 25. Design workshop record

### Workshop 1 — foundation (2026-09-17)

1. **Finished-game ambition:** A short, complete commercial game.
2. **Player identity:** The player enters the Royal Forest looking for their missing brother, who came searching for a lost treasure.
3. **Central appeal:** Exploration and atmosphere.
4. **Combat defense:** Spacing supported by limited blocking and dodging.
5. **World structure:** One interconnected world.

### Workshop 2 — progression and stakes

1. **Progression:** A hybrid of modest stats plus found equipment and exploration tools.
2. **Death:** Return to the last checkpoint; ordinary enemies reset; no dropped-resource recovery.
3. **Tone boundary:** Very dark, with a genuinely hopeful ending that must be earned.
4. **Brother:** The brothers were close but lived far apart. He risked entering the forest to find a cure for their sick mother.
5. **Treasure:** A goblet from myth and legend, said to heal any disease or wound with one sip.

### Workshop 3 — story and progression anchors

1. **Brother's trail:** Recent written/audio clues, with no direct meeting until late in the game.
2. **Goblet truth:** Its healing is genuine, but using it has a serious cost or condition.
3. **Hopeful ending:** Rescue the brother, heal the mother, and resolve the forest's curse.
4. **Stats:** Vitality, Endurance, Might, and Insight; the player allocates points.
5. **Checkpoints:** Living trees that heal the player and record progress.

### Workshop 4 — curse and player systems

1. **Goblet cost:** It heals only after a willing sacrifice.
2. **Forest curse:** An ancient civilization protected its kingdom from the dying world outside. The resulting curse unintentionally altered the goblet and caused its downside.
3. **Insight:** It reveals hidden truths/routes and enables rituals or magic.
4. **Stat points:** Major discoveries grant points, which the player allocates at living trees.
5. **Blocking and dodging:** Dodging is universal; shields unlock blocking.

### Workshop 5 — curse resolution and production scope

1. **Sacrifice:** A willing person must give up their life.
2. **Ancient protection:** A plague was killing the outside world. The civilization's protection prevented the kingdom's people from dying of it, but trapped their spirits.
3. **Curse resolution:** Release the trapped spirits and allow the old kingdom to die.
4. **Magic:** A compact set of conventional combat spells.
5. **Discovery points:** A curated mix of region discoveries, bosses, secrets, and quest resolutions.

Further workshops should contain only high-impact owner decisions. Routine formulas, content counts, UX defaults, persistence details, and tuning values should be recommended from the established pillars and validated through implementation/playtesting rather than asked one by one.

### Workshop 6 — scope and core structure

1. **Playtime:** Target 4–6 hours for a first completion.
2. **Hopeful ending:** The trapped spirits willingly surrender their remaining existence, breaking the curse and empowering one final healing.
3. **World:** A central forest nexus connects four distinct major regions.
4. **Combat resource:** One stamina bar governs attacks, dodges, and shield blocks; no combat sprinting.
5. **Magic resource:** Mana regenerates slowly.

### Workshop 7 — presentation and player support

1. **Art identity:** PS1-style low-poly 3D, pixel-art billboard creatures, and modern readable lighting.
2. **Navigation:** No minimap; an exploration-filled hand-drawn map; late fast travel between living trees.
3. **Healing:** A small refillable vessel restored at living trees with a slow committed use.
4. **Narrative delivery:** Written notes plus short voiced spectral echoes; sparse dialogue elsewhere.
5. **Endings:** Three outcomes—failure/dark in which everyone dies, partial in which at least one family member dies, and a secret fully hopeful ending in which the family survives and the released spirits provide the goblet's sacrifice.
