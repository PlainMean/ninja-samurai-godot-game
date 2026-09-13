#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
export XDG_CONFIG_HOME="$PWD/build/local/config"
mkdir -p build/sword-reproduction
ASEPRITE_BIN="${ASEPRITE_BIN:-$HOME/.local/bin/aseprite}"
"$ASEPRITE_BIN" -b --script-param out="$PWD/build/sword-reproduction" --script art_sources/weapons/generate.lua
"$ASEPRITE_BIN" -b --script-param root="$PWD" --script-param out="$PWD/build/sword-reproduction" --script art_sources/weapons/derive_player.lua
"$ASEPRITE_BIN" -b --script-param src="$PWD/build/sword-reproduction" --script art_sources/weapons/verify.lua
for name in water fire earth wind player_attack player_support; do
 cmp "art_sources/weapons/${name}_sheet.png" "build/sword-reproduction/${name}_sheet.png"
 cmp "art_sources/weapons/${name}.json" "build/sword-reproduction/${name}.json"
done
python3 game/tests/check_sword_assets.py
python3 game/tests/check_player_sword_bodies.py
printf 'PASS six PNG sheets and six JSON documents reproduced byte-for-byte with Aseprite\n'
