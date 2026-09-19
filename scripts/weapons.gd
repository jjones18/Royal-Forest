class_name Weapons
extends RefCounted
## Weapon catalog + weighted roll for chest drops.
## chance values are relative weights (sum need not be 1.0).

const CATALOG := {
	"bow": {
		"ranged": true,
		"damage": 25,
		"chance": 0.40,
		"pickup_text": "A hunter's bow and a quiver of arrows. (Hold LMB to draw, release to loose)",
	},
	"sword": {
		"ranged": false,
		"damage": 34,
		"reach": 3.5,          # sphere center + radius (the old melee tuning)
		"cooldown": 0.75,
		"swing_time": 0.45,
		"arc_cos": 0.35,       # ~70 degree half-cone
		"chance": 0.25,
		"pickup_text": "An old blade, still keen. (Left-click to swing)",
	},
	"spear": {
		"ranged": false,
		"damage": 22,
		"reach": 4.6,          # longest reach — poke from safety
		"cooldown": 0.9,
		"swing_time": 0.5,
		"arc_cos": 0.80,       # narrow thrust cone
		"chance": 0.20,
		"pickup_text": "A long spear. Keep them at arm's length. (Left-click to thrust)",
	},
	"axe": {
		"ranged": false,
		"damage": 55,
		"reach": 2.9,          # short but savage
		"cooldown": 1.15,
		"swing_time": 0.65,
		"arc_cos": 0.10,       # wide sweeping arc
		"chance": 0.15,
		"pickup_text": "A woodcutter's axe. Heavy, but it bites deep. (Left-click to swing)",
	},
}


static func roll() -> String:
	var total := 0.0
	for id in CATALOG:
		total += CATALOG[id]["chance"]
	var pick := randf() * total
	for id in CATALOG:
		pick -= CATALOG[id]["chance"]
		if pick <= 0.0:
			return id
	return "bow"
