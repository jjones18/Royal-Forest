# Royal Forest

A first-person dungeon crawler prototype inspired by FromSoftware's *King's Field*
(1994): slow deliberate first-person exploration, sprite enemies in 3D space,
atmosphere over exposition.

**Status:** M2c is complete. The gray-box now has an interactable living-tree checkpoint with physical LOS cover, full renewable-resource refill, ordinary-enemy reset, death/respawn, versioned schema-v1 save/load, atomic replacement, rolling-backup recovery, and visible success/failure feedback. M2d attributes, inventory/equipment, settings persistence, and map foundation remain open before authored M2e route production.

Green pursuit and recovery re-aim rapidly (540°/s); orange windup permits only slow limited turning (45°/s); only the red active strike is direction-committed (0°/s).

## The plan

We are building one GDD-traceable first playable before expanding to the full game:

- [x] Deterministic movement, melee, stamina, dodge, guard, enemy, death, and restart foundations
- [x] Visible gray-box sword/shield and combat feedback
- [x] Fair committed enemy strikes and bounded LOS search behavior
- [x] Human M1 verdict: proceed to M2 with bounded turning follow-up queued for combined review
- [x] Mana owner and one free-aim Spectral Bolt (M2a): 100 max mana, 25 cost, 2.0 s delay, 2.5 mana/s; 30 damage, 16 m/s, 24 m range, 0.16 m radius
- [x] Healing vessel model and committed interruption behavior (M2b): 3 charges, 40% max-HP healing, 0.80/0.08/0.52-second phases
- [x] Crouch stance and low-cover LOS concealment (M2b.1): C / D-pad Down, 40% movement, headroom-safe stand/dodge
- [x] Living-tree checkpoint, death/respawn, schema-v1 persistence, and ordinary-enemy reset (M2c)
- [ ] Attributes, inventory/equipment, settings persistence, and map foundation (M2d)
- [ ] Authored Root-Crown → Crowned Hunt → Hound-King → first Crown Seal route
- [ ] 20–30 minute v0.1 first-playable package

Rule: we do not add content until the combat loop feels good.

## Design documents

- [`docs/GAME_DESIGN_DOCUMENT.md`](docs/GAME_DESIGN_DOCUMENT.md) — accepted design,
  implementation requirements, unresolved decisions, and decision log
- [`design-notes.md`](design-notes.md) — dated inbox for unfiltered ideas

## Roles

- **Josh** — engine, code, AI-assisted implementation
- **Friend** — game-feel director: playtests every build, tunes pacing,
  writes enemy/item notes, sketches levels on paper

## Running it

Godot 4.4 lives at `~/.local/opt/godot`.

```sh
# Open the project in the editor
~/.local/opt/godot --editor --path /mnt/storage/Git/royal-forest &

# Or run the game directly
~/.local/opt/godot --path /mnt/storage/Git/royal-forest
```

Controls: **WASD** move · **mouse** look · **left mouse** attack · **Q** Spectral Bolt · **F** healing vessel · **C** toggle crouch · **E** use living tree · **Space** dodge · **right mouse (hold)** guard · **R** reset/respawn · **Esc** release cursor · **F9** start/stop a diagnostic recording · **F10** visibly mark the issue moment. Controller casting uses **right shoulder**; healing uses **D-pad Up**; crouch uses **D-pad Down**; living-tree interaction uses **X / Square**; reset/respawn uses **Y / Triangle**.

Run the complete automated gate with `./tools/verify.sh`. See [`playtest/m1/README.md`](playtest/m1/README.md) for the current 2–5 minute human retest.
