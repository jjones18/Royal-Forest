#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${GODOT:-}" ]]; then
	GODOT="$GODOT"
elif [[ -x "$HOME/.local/opt/godot" ]]; then
	GODOT="$HOME/.local/opt/godot"
elif command -v godot4 >/dev/null 2>&1; then
	GODOT="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
	GODOT="$(command -v godot)"
else
	printf 'FAIL: set GODOT or install a godot4/godot executable\n' >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/royal-forest-negative-gates.XXXXXX")"
MUTANT="$TMP_ROOT/project"

cleanup() {
	rm -rf -- "$TMP_ROOT"
}
trap cleanup EXIT INT TERM

mkdir -p "$MUTANT"
tar -C "$PROJECT" \
	--exclude='./.git' \
	--exclude='./.godot' \
	--exclude='./artifacts' \
	-cf - . | tar -C "$MUTANT" -xf -

CONTROLLER="$MUTANT/game/enemies/enemy_controller.gd"
STATE_MACHINE="$MUTANT/game/enemies/enemy_state_machine.gd"
DEFINITION="$MUTANT/game/data/enemies/shambler.tres"
SPELL_DEFINITION="$MUTANT/game/data/spells/spectral_bolt.tres"
SPELL_PROJECTILE="$MUTANT/game/combat/spell_projectile.gd"
PLAYER_ACTION_MACHINE="$MUTANT/game/player/action/player_action_machine.gd"
HEALING_VESSEL="$MUTANT/game/player/healing_vessel.gd"
PLAYER_CONTROLLER="$MUTANT/game/player/player_controller.gd"
PLAYER_STANCE="$MUTANT/game/player/player_stance.gd"
VISUAL_SET_CHECKER="$MUTANT/tools/check_visual_capture_set.py"

"$GODOT" --headless --path "$MUTANT" --import >"$TMP_ROOT/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:' "$TMP_ROOT/import.log"; then
	printf 'FAIL: isolated negative-gate project import failed; see %s\n' "$TMP_ROOT/import.log" >&2
	exit 1
fi

run_negative_gate() {
	local label="$1" expected="$2" log_file="$3"
	set +e
	"$GODOT" --headless --path "$MUTANT" res://tests/test_runner.tscn >"$log_file" 2>&1
	local status=$?
	set -e
	if [[ $status -eq 0 ]]; then
		printf 'FAIL: %s did not reject the intentional defect\n' "$label" >&2
		exit 1
	fi
	if ! grep -Fq "$expected" "$log_file"; then
		printf 'FAIL: %s failed for the wrong reason; see %s\n' "$label" "$log_file" >&2
		exit 1
	fi
	printf 'PASS: %s rejected the intentional defect\n' "$label"
}

python3 - "$CONTROLLER" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "attack_indicator.mesh = StrikeGeometry.build_wedge_mesh(_strike_reach(), definition.attack_arc_degrees)"
new = "attack_indicator.mesh = StrikeGeometry.build_wedge_mesh(definition.attack_range, definition.attack_arc_degrees)"
if old not in text:
    raise SystemExit("indicator mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "indicator/hit geometry gate" "indicator must extend to the exact damaging reach" "$TMP_ROOT/geometry.log"
cp -- "$PROJECT/game/enemies/enemy_controller.gd" "$CONTROLLER"

python3 - "$DEFINITION" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "active_turn_speed_degrees = 0.0"
new = "active_turn_speed_degrees = 30.0"
if old not in text:
    raise SystemExit("active-turn mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "active-turn lock gate" "active_turn_speed_degrees must remain zero" "$TMP_ROOT/active-turn.log"
cp -- "$PROJECT/game/data/enemies/shambler.tres" "$DEFINITION"

python3 - "$STATE_MACHINE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\tif beyond_leash:\n\t\t_enter(Phase.RETURN)\n\t\treturn\n\t# RETURN is not deaf:"
new = "\tif phase == Phase.RETURN:\n\t\treturn\n\tif beyond_leash:\n\t\t_enter(Phase.RETURN)\n\t\treturn\n\t# RETURN is not deaf:"
if old not in text:
    raise SystemExit("return-awareness mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "return reacquisition gate" "RETURN must re-engage a visible target inside detection and leash range" "$TMP_ROOT/return-reacquisition.log"
cp -- "$PROJECT/game/enemies/enemy_state_machine.gd" "$STATE_MACHINE"

python3 - "$CONTROLLER" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\tvar arrival_tolerance := definition.home_arrival_tolerance if waypoint_is_destination else 0.01"
new = "\tvar arrival_tolerance := definition.home_arrival_tolerance"
if old not in text:
    raise SystemExit("detour-corner tolerance mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "detour-corner progress gate" "SEARCH must advance past a near intermediate corner instead of stalling" "$TMP_ROOT/detour-corner.log"
cp -- "$PROJECT/game/enemies/enemy_controller.gd" "$CONTROLLER"

python3 - "$CONTROLLER" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\t\tEnemyStateMachine.Phase.RECOVERY:\n\t\t\tvelocity = Vector3.ZERO\n\t\t\tif los:\n\t\t\t\tturn_toward_position(player.global_position, definition.pursuit_turn_speed_degrees, delta)\n"
if old not in text:
    raise SystemExit("recovery-turn mutation anchor missing")
path.write_text(text.replace(old, "", 1))
PY
run_negative_gate "green recovery re-aim gate" "green RECOVERY must rapidly catch a full-speed circle-strafe target" "$TMP_ROOT/recovery-reaim.log"
cp -- "$PROJECT/game/enemies/enemy_controller.gd" "$CONTROLLER"

python3 - "$SPELL_DEFINITION" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "mana_cost = 25.0"
new = "mana_cost = 0.0"
if old not in text:
    raise SystemExit("spell mana-cost mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "spectral-bolt mana cost gate" "Expected 25.0, got 0.0" "$TMP_ROOT/spell-cost.log"
cp -- "$PROJECT/game/data/spells/spectral_bolt.tres" "$SPELL_DEFINITION"

python3 - "$SPELL_PROJECTILE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "const COLLISION_MASK := 5"
new = "const COLLISION_MASK := 7"
if old not in text:
    raise SystemExit("projectile-mask mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "projectile caster-exclusion gate" "projectile mask must never include player layer" "$TMP_ROOT/projectile-mask.log"
cp -- "$PROJECT/game/combat/spell_projectile.gd" "$SPELL_PROJECTILE"

python3 - "$PLAYER_ACTION_MACHINE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\tif phase != Phase.FREE:\n"
new = "\tif phase != Phase.FREE and phase != Phase.DODGE:\n"
if old not in text:
    raise SystemExit("cast-commitment mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "cast-during-dodge gate" "cast must be blocked during DODGE commitment" "$TMP_ROOT/cast-dodge.log"
cp -- "$PROJECT/game/player/action/player_action_machine.gd" "$PLAYER_ACTION_MACHINE"

python3 - "$HEALING_VESSEL" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "const MAX_CHARGES := 3"
new = "const MAX_CHARGES := 0"
if old not in text:
    raise SystemExit("vessel max-charge mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "healing-vessel max-charge gate" "M2B_MAX_CHARGES_EXACT" "$TMP_ROOT/heal-max-charges.log"
cp -- "$PROJECT/game/player/healing_vessel.gd" "$HEALING_VESSEL"

python3 - "$PLAYER_ACTION_MACHINE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\t\t\theal_tick_available = false\n\t\t\t_enter(Phase.HEAL_WINDUP)"
new = "\t\t\theal_tick_available = true\n\t\t\t_enter(Phase.HEAL_WINDUP)"
if old not in text:
    raise SystemExit("early-heal mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "exact healing-frame gate" "M2B_EXACT_HEAL_FRAME" "$TMP_ROOT/heal-frame.log"
cp -- "$PROJECT/game/player/action/player_action_machine.gd" "$PLAYER_ACTION_MACHINE"

python3 - "$PLAYER_ACTION_MACHINE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\telif phase != Phase.GUARD and not guard_broken: _enter(Phase.HURT)"
new = "\telif phase not in [Phase.GUARD, Phase.HEAL_WINDUP] and not guard_broken: _enter(Phase.HURT)"
if old not in text:
    raise SystemExit("heal-interruption mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "healing interruption gate" "M2B_INTERRUPTION_ENTERS_HURT" "$TMP_ROOT/heal-interruption.log"
cp -- "$PROJECT/game/player/action/player_action_machine.gd" "$PLAYER_ACTION_MACHINE"

python3 - "$PLAYER_ACTION_MACHINE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\tif phase != Phase.FREE:\n"
new = "\tif phase != Phase.FREE and request_data.kind != PlayerActionRequest.Kind.HEAL:\n"
if old not in text:
    raise SystemExit("heal-commitment mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "healing commitment gate" "M2B_HEAL_COMMITMENT_BLOCKED" "$TMP_ROOT/heal-commitment.log"
cp -- "$PROJECT/game/player/action/player_action_machine.gd" "$PLAYER_ACTION_MACHINE"

python3 - "$PLAYER_STANCE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "const CROUCHED_EYE_HEIGHT := 0.95"
new = "const CROUCHED_EYE_HEIGHT := 1.62"
if old not in text:
    raise SystemExit("crouched-eye mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "crouched LOS target gate" "M2B1_CROUCH_BREAKS_LOS" "$TMP_ROOT/crouch-los.log"
cp -- "$PROJECT/game/player/player_stance.gd" "$PLAYER_STANCE"

python3 - "$PLAYER_STANCE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "const CROUCH_SPEED_MULTIPLIER := 0.40"
new = "const CROUCH_SPEED_MULTIPLIER := 1.0"
if old not in text:
    raise SystemExit("crouch-speed mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "exact crouch speed gate" "M2B1_CROUCH_SPEED_EXACT" "$TMP_ROOT/crouch-speed.log"
cp -- "$PROJECT/game/player/player_stance.gd" "$PLAYER_STANCE"

python3 - "$PLAYER_CONTROLLER" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\treturn get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()"
new = "\treturn true"
if old not in text:
    raise SystemExit("headroom-guard mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "standing headroom gate" "M2B1_STAND_REQUIRES_HEADROOM" "$TMP_ROOT/crouch-headroom.log"
cp -- "$PROJECT/game/player/player_controller.gd" "$PLAYER_CONTROLLER"

python3 - "$PLAYER_ACTION_MACHINE" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = "\t\t\t_buffered_move_direction = request_data.move_direction"
new = "\t\t\t_buffered_move_direction = Vector2.ZERO"
if old not in text:
    raise SystemExit("buffered-dodge direction mutation anchor missing")
path.write_text(text.replace(old, new, 1))
PY
run_negative_gate "buffered dodge direction gate" "M2B1_BUFFERED_DODGE_DIRECTION" "$TMP_ROOT/buffered-dodge-direction.log"
cp -- "$PROJECT/game/player/action/player_action_machine.gd" "$PLAYER_ACTION_MACHINE"

VISUAL_GATE_DIR="$TMP_ROOT/visual-set"
mkdir -p "$VISUAL_GATE_DIR"
printf 'expected' > "$VISUAL_GATE_DIR/expected.png"
printf 'stray' > "$VISUAL_GATE_DIR/unexpected-extra.png"
set +e
python3 "$VISUAL_SET_CHECKER" "$VISUAL_GATE_DIR" expected.png >"$TMP_ROOT/visual-set.log" 2>&1
visual_status=$?
set -e
if [[ $visual_status -eq 0 ]]; then
	printf 'FAIL: exact visual capture set gate did not reject the intentional stray file\n' >&2
	exit 1
fi
if ! grep -Fq 'M2B1_VISUAL_SET_EXACT' "$TMP_ROOT/visual-set.log"; then
	printf 'FAIL: exact visual capture set gate failed for the wrong reason; see %s\n' "$TMP_ROOT/visual-set.log" >&2
	exit 1
fi
printf 'PASS: exact visual capture set gate rejected the intentional stray file\n'

printf 'NEGATIVE GATES: PASS (17 gates: 16 gameplay mutants + 1 visual manifest defect); live source was never modified\n'
