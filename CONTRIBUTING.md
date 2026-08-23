# Contributing to Royal Forest

## The one rule

**All changes go through a Pull Request. Never push directly to `main`.**

GitHub enforces this: `main` is protected by a ruleset requiring one approving
review. Direct pushes will be rejected.

## Merging your own PR

Both collaborators are registered as bypass actors, so **an author may merge
their own PR** without waiting for the other person's review — on two
conditions:

1. The AI assistant has confirmed the PR has no merge conflicts first.
2. Gameplay changes still get play-tested by whoever is free before merging
   when practical.

The review requirement stays in place for when you want a real second pair of
eyes (risky refactors, big content drops) — just don't bypass then.

## Workflow

1. `git checkout main && git pull`
2. `git checkout -b <your-name>/<short-topic>` (e.g. `jjones/player-stamina`)
3. Commit small, with clear messages.
4. Push your branch: `git push -u origin <branch>`
5. Open a PR on GitHub describing what changed and how to test it.
6. The **other** person reviews, plays the build if it's gameplay, approves,
   then merge (squash preferred).

## Reviewing a gameplay change

Actually run it before approving:

```sh
~/.local/opt/godot --path /mnt/storage/Git/royal-forest
```

Feel beats correctness: if the movement/combat feels wrong, say so in the PR
even if the code is perfect.

## Before pushing

```sh
~/.local/opt/godot --headless --import .
timeout 12 ~/.local/opt/godot --headless .
```

Both must run clean (no script errors).
