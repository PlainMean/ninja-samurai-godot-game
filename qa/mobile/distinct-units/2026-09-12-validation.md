# Distinct unit QA — 2026-09-12

Clean baseline: `9b6b1b707f11792559e5cd5f39cd29b61ac9b836`.
Completed in three bounded passes. Every pass passed targeted checks and
`bash game/tests/verify.sh` before the next pass began. No existing test removed,
weakened, skipped or isolated. Existing parse-error detection is unchanged.

| Gate | Actual result |
| --- | --- |
| Pass 1 full verify | 19,840 checks; 0 failures |
| Pass 2 targeted + full verify | 20,226 checks; 0 failures each |
| Pass 3 targeted + full verify | 20,286 checks; 0 failures each |
| Aseprite API generator | 12 editable sets, 48 distinct attack poses |
| Aseprite native verifier | 12 reopened sources, 48 source/export matches, attack tags and 100ms timing |
| Independent binary verifier | 60 SHA-256 hashes; 48 compressed-cel/PNG pixel matches; dimensions, alpha, palette and metadata passed |
| Silhouette comparison | 66 unit pairs; every ready pair differs by >100 alpha pixels; no shared frame masks |
| Reproduction | All 12 PNG sheets byte-identical after fresh Aseprite generation into build/unit-repro |
| Prior art preservation | All 91 baseline tracked art/source/assets files byte-identical |
| Exported legacy campaign | 8 encounters, 19 effective attacks, 11 replies; clear |
| Exported area campaign | 12 unique selected unit resources; 4 bosses; loot/training and full clear |
| Export dependency check | All 12 encounters, units, SpriteFrames, imported atlases present; sources/tests excluded |
| Web artifact | 237 pack entries; PCK 195,756 bytes, below unchanged 1 MiB cap |
| Complete bundle | 38,687,548 raw bytes / 9,454,707 gzip bytes |
| git diff --check | Passed |
| Local commit | Blocked by read-only .git/index.lock, exit 128 |

The added 446 Godot assertions cover 60 source/runtime hashes, exact twelve-node
IDs/names/roles/area elements and boss flags, unchanged HP/intents, imported frame
pixels/timing/atlas bounds, support poses, every region's 390×844 map bounds,
normal scene selection, nearest filtering, preserved ninja, boss scale and
map/HUD/intro/loot markers, a complete unit campaign and legacy reset.
The existing 72-build campaign matrix and full elemental/weapon tests still run.

## Roster and authored differences

| Region | Unit (ID) | Role / silhouette |
| --- | --- | --- |
| Fire | Cinder Rival (`cinder_rival`) | Slim fire duelist, tied hair, saber |
| Fire | Ash Monk (`ash_monk`) | Bald staff monk, beads, bell sleeves |
| Fire | **Ash Shogun** (`ash_shogun`) | BOSS, heavy horned helm, tassets, cleaver |
| Water | Gate Guard (`gate_guard`) | Plumed conical helm, spear, tabard |
| Water | Twin-cut Retainer (`twin_cut_retainer`) | Dual blades, split coat |
| Water | **Moonlit Master** (`moonlit_master`) | BOSS, circular halo, robe, fan |
| Earth | Earth Sentinel (`earth_sentinel`) | Kite shield, compact helmet |
| Earth | Iron Vanguard (`iron_vanguard`) | Square plate armor, two-handed hammer |
| Earth | **Mountain Regent** (`mountain_regent`) | BOSS, jagged crown, massive shoulders, slab axe |
| Wind | Gale Assassin (`gale_assassin`) | Masked crouch, trailing scarf, sickle |
| Wind | Coast Ronin (`coast_ronin`) | Wide straw hat, ragged poncho, low sword |
| Wind | **Tempest Sovereign** (`tempest_sovereign`) | BOSS, wing mantle, crown, forked glaive |

All use 48×48 native cells, four 100ms attack frames, dedicated palettes;
2.5× guard / 3× boss scale. Idle, guard, hurt and defeat reuse attack poses;
there are no claims of new combat AI or separately authored support sequences.

## Visual and environmental evidence

Inspected all twelve exported sprite strips using the image viewer; confirmed
recognizable differing silhouettes/weapons, transparency, and frame movement.
These are asset inspections, not rendered game screenshots. Native 390×844
`native_units_smoke.gd` was attempted but X11 was unavailable and Wayland could
not connect. Xvfb also failed to bind its sockets. **Zero game screenshots** were
captured; logs are `native-smoke.txt` and `xvfb.txt`. The native capture script
passed Godot's check-only gate and remains ready for a parent display.

Aseprite's default config directory was read-only; repository-local
XDG_CONFIG_HOME resolved it. One early Godot invocation without local data
settings crashed when opening its user log; using all three repository-local
XDG directories resolved it. An initial new-test typed-array assignment error
was fixed and the entire suite rerun. Final logs have no SCRIPT ERROR/Parse Error;
Godot editor/export emits existing sandbox socket-listener errors, without
preventing import/export. They are retained, not suppressed.

Browser HTTP/WebGL execution, mobile Safari/Chrome, physical iOS/Android touch,
safe areas, lifecycle, visual overlap and performance remain unverified. Headless
layout assertions do not replace rendered/device acceptance.

Local artifact: `build/web/index.html` plus its complete sibling bundle.
No push or deployment. See `commit-attempt.txt`; all changes remain unstaged for
the parent workspace. Plan: `.hermes/plans/2026-09-12_210613-distinct-units.md`.
