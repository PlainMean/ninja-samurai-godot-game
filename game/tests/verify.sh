#!/usr/bin/env bash
# Run from any directory; all generated state stays inside this repository.
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot}"
GODOT_TEMPLATE_DIR="${GODOT_TEMPLATE_DIR:-$HOME/.local/share/godot/export_templates}"
export XDG_DATA_HOME="$PWD/build/local/data"
export XDG_CACHE_HOME="$PWD/build/local/cache"
export XDG_CONFIG_HOME="$PWD/build/local/config"
mkdir -p "$XDG_DATA_HOME/godot" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" build/web
if [[ ! -e "$XDG_DATA_HOME/godot/export_templates" ]]; then
    ln -s "$GODOT_TEMPLATE_DIR" "$XDG_DATA_HOME/godot/export_templates"
fi
run() {
    local log="$1"
    shift
    local result=0
    "$@" > "build/$log.log" 2>&1 || result=$?
    cat "build/$log.log"
    if [[ "$result" != 0 ]]; then return "$result"; fi
    # Godot can return 0 after script errors. Always detect those explicitly.
    if rg -q 'SCRIPT ERROR|Parse Error|Failed to load|FAIL:|[1-9][0-9]* failures' "build/$log.log"; then
        return 1
    fi
}
run version "$GODOT_BIN" --version
[[ "$(cat build/version.log)" == "4.5.1.stable.official.f62fdbde1" ]]
python3 game/tests/check_sword_assets.py
python3 game/tests/check_player_sword_bodies.py
python3 game/tests/check_source_assets.py
sha256sum -c game/tests/source_assets.sha256
python3 game/tests/check_journey_assets.py
python3 game/tests/check_element_assets.py
python3 game/tests/check_hero_assets.py
sha256sum -c game/tests/prior_hero_art.sha256
python3 game/tests/check_unit_assets.py
sha256sum -c game/tests/prior_unit_art.sha256
python3 game/tests/check_moonlit_assets.py
sha256sum -c game/tests/moonlit_assets.sha256
run import "$GODOT_BIN" --headless --path game --editor --import
run native-multi-script-check "$GODOT_BIN" --headless --path game --check-only --script res://tests/native_multi_combat_smoke.gd
run native-sword-script-check "$GODOT_BIN" --headless --path game --check-only --script res://tests/native_swords_smoke.gd
run native-script-check "$GODOT_BIN" --headless --path game --check-only --script res://tests/native_visual_smoke.gd
run native-unit-script-check "$GODOT_BIN" --headless --path game --check-only --script res://tests/native_units_smoke.gd
run native-companion-script-check "$GODOT_BIN" --headless --path game --check-only --script res://tests/native_companion_smoke.gd
run sword-tests "$GODOT_BIN" --headless --path game --script res://tests/sword_gate.gd
run multi-combat-tests "$GODOT_BIN" --headless --path game --script res://tests/multi_combat_gate.gd
run companion-tests "$GODOT_BIN" --headless --path game --script res://tests/companion_gate.gd
run native-area-script-check "$GODOT_BIN" --headless --path game --check-only --script res://tests/native_area_smoke.gd
run tests "$GODOT_BIN" --headless --path game --script res://tests/run_tests.gd
run smoke "$GODOT_BIN" --headless --path game --quit-after 120
run export "$GODOT_BIN" --headless --path game --export-release Web ../build/web/index.html
run export-smoke "$GODOT_BIN" --headless --path build/web --main-pack index.pck --quit-after 120
run export-run "$GODOT_BIN" --headless --path build/web --main-pack index.pck --script "$PWD/game/tests/export_pack_smoke.gd"
run export-multi-combat "$GODOT_BIN" --headless --path build/web --main-pack index.pck --script "$PWD/game/tests/export_multi_combat_smoke.gd"
cp CREDITS.md THIRD_PARTY_NOTICES.txt build/web/
python3 game/tests/check_web_export.py
printf 'Verification complete. Logs: build/*.log\n'
