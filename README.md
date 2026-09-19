# Royal Forest

A first-person dungeon crawler prototype inspired by FromSoftware's *King's Field*
(1994): slow deliberate first-person exploration, sprite enemies in 3D space,
atmosphere over exposition.

**Status:** M1 combat-feel checkpoint accepted for M2 systems work on 2026-09-18. The green-recovery turning fix remains queued for combined human review with M2; authored route production waits for the M2 state/persistence foundations.

## The plan

We are building one GDD-traceable first playable before expanding to the full game:

- [x] Deterministic movement, melee, stamina, dodge, guard, enemy, death, and restart foundations
- [x] Visible gray-box sword/shield and combat feedback
- [x] Fair committed enemy strikes and bounded LOS search behavior
- [x] Human M1 verdict: proceed to M2 with bounded turning follow-up queued for combined review
- [ ] Mana, one spell, healing vessel, checkpoints, persistence, attributes, inventory, and map foundation
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

Controls: **WASD** move · **mouse** look · **left mouse** attack · **Space** dodge · **right mouse (hold)** guard · **R** reset · **Esc** release cursor · **F9** start/stop a diagnostic recording · **F10** visibly mark the issue moment.

Run the complete automated gate with `./tools/verify.sh`. See [`playtest/m1/README.md`](playtest/m1/README.md) for the current 2–5 minute human retest.
