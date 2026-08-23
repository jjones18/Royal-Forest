# Royal Forest

A first-person dungeon crawler prototype inspired by FromSoftware's *King's Field*
(1994): slow deliberate first-person exploration, sprite enemies in 3D space,
atmosphere over exposition.

**Status:** Week 1 — gray-box movement prototype.

## The plan

We are building ONE small playable thing first ("vertical slice"), not a whole game:

- [ ] Player movement + camera in a gray-box room *(this repo's current state)*
- [ ] Melee swing that hits something
- [ ] One enemy that approaches and hurts you
- [ ] Health / death / restart loop → **first "is this fun?" verdict**
- [ ] Dungeon layout: 4–5 rooms, key, locked door
- [ ] Second enemy type (ranged/keeper-distance)
- [ ] Atmosphere pass: lighting, fog, audio, sprite enemies

Rule: we do not add content until the combat loop feels good.

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

Controls: **WASD** move · **mouse** look · **Esc** release cursor · click to recapture.
