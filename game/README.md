# Moonlit Dojo: Four Lands

The default UI now runs the area campaign described in [the root README](../README.md).
`RunModel.begin_area_run(seed)` loads twelve dedicated area EncounterSpec resources from
`data/encounters/areas/`. Each references a unique data-only UnitSpec in `data/units/`. `begin_run()` retains the original
legacy campaign; old tests explicitly select it. The historical details below
apply to that legacy mode.

RunModel owns the map frontier, node locks, inventory indices, equipped immutable
WeaponSpec, technique levels, rewards and RNG. Four areas form a ring; both guards
must be sealed before that area’s boss. Cleared bosses open neighboring areas.
The map may revisit any unlocked frontier; no movement cost or random encounters.
Each node’s sword is deterministic, so route order changes access to loot.

The Park–Miller stream uses state = (state × 16807) modulo 2147483647;
roll = state modulo 4 + 1. Seed defaults to 1, normalized into 1…2147483646.
Only player impacts advance it. Retry resets it. A matching-sword bonus is
1 + roll modulo 2; technique bonus is level − 1; directed advantage adds 1.
Thus a matching sword contributes 3…5 before technique/matchup, while a
nonmatching sword contributes 1…4. Forecasts consume no RNG and show nominal
inclusive ranges; guaranteed lethal requires the minimum to cover remaining HP.
CombatModel resolves damage and emits typed roll/weapon/level/matchup/total fields.
Views only issue commands and present state/events.

The four existing action targets retain 83×96 geometry with locked states and
level/range labels. A scrollable area panel uses 60-pixel targets for swords,
all six starting pairs, regions, nodes, loot and technique upgrades. Clipped
scroll targets reject input. Inventory is reachable on every map and loot screen;
the equipped weapon remains visible during combat. Shrines fully heal and add
one technique point, bounded to level 3. Retry starts the whole campaign.

Run `res://tests/native_units_smoke.gd` for native 390×844 capture when a display
is available. Current [unit QA](../qa/mobile/distinct-units/2026-09-12-validation.md)
records actual attempts. FighterView selects the encounter unit's SpriteFrames for
attack and support poses, with nearest filtering. Units use 48×48 native cells,
2.5× guard / 3× boss scale; the player and legacy route retain their old frames.
Only attack has four newly authored poses; idle/guard/hurt/defeat deliberately
reuse those poses. This is visual unit variety, not new enemy combat mechanics.

The Aseprite-only pipeline and palette inventory are documented in
[`art_sources/units/ASSET_SPEC.md`](../art_sources/units/ASSET_SPEC.md).
`check_unit_assets.py` independently decompresses native cels and PNGs, checks
60 source/runtime hashes and rejects shared silhouettes. `test_units.gd` checks
all twelve identities, palettes via manifest hashes, roles, area/boss mappings,
SpriteFrames, view selection and a full clear. The exported-pack smoke repeats
selection through all twelve nodes; the explicit export roots include each area
resource and pull in its unit/atlas dependencies.

## Preserved eight-seal campaign


Start with 5 HP. Read the guardian’s affinity and weakness, then choose one of
four elements. Decisions have no timer. A surviving foe replies with the
technique shown in Intent. Your chosen attack never changes your affinity:
the player remains NONE, so enemy replies deal one damage in this route.

| Attack / Defender | FIRE | WATER | EARTH | WIND | NONE |
| --- | --- | --- | --- | --- | --- |
| FIRE | 1 | 1 | 2 | 1 | 1 |
| WATER | 2 | 1 | 1 | 1 | 1 |
| EARTH | 1 | 1 | 1 | 2 | 1 |
| WIND | 1 | 2 | 1 | 1 | 1 |

Only the four directed advantages are effective. All other matchups are neutral.
The pure model supports explicit player affinities for tests; no hidden
randomness, defense input, reaction window, backend or audio dependency exists.

| Resource / guardian | HP | Affinity → weakness | Repeating reply elements | Backdrop |
| --- | ---: | --- | --- | --- |
| gate_guard / Gate Warden | 3 | WATER → WIND | WATER | gate |
| fire_rival / Cinder Rival | 4 | FIRE → WATER | FIRE, FIRE, WIND | courtyard |
| earth_sentinel / Cairn Sentinel | 5 | EARTH → FIRE | EARTH, WATER | gate |
| wind_assassin / Gale Assassin | 3 | WIND → EARTH | WIND, FIRE | courtyard |
| courtyard_retainer / Twin-cut Retainer | 4 | WATER → WIND | WATER, WIND | courtyard |
| ember_monk / Ash Monk | 4 | FIRE → WATER | EARTH, FIRE | dojo |
| mixed_elite / Fourfold Ronin | 5 | EARTH → FIRE | WIND, WATER, FIRE, EARTH | courtyard |
| dojo_master / Moonlit Master | 5 | WATER → WIND | WATER, FIRE, EARTH, WIND | dojo |

Each cycle starts at its first technique on encounter entry. The foe’s stance
(affinity/weakness) stays fixed even when its attack element changes. Every
technique has a displayed name. Enemy identities use the preserved samurai
animations; these are eight combat roles, not eight new character sprites.

Health carries across fights. Seven shrines offer Mend (+2 HP capped at maximum)
or capacity (+1 maximum and +1 current HP). The first capacity gift is Long
Breath; subsequent gifts are Iron Resolve. All seven capacity gifts stack to
12 maximum HP. Full-health Mend is disabled. Exact HP previews and next-guardian
health remain visible. All 128 gift combinations clear with weakness attacks:
19 attacks, 11 enemy replies. Neutral-only play can lose at level three.

Eight seals unlock the archive. Route text marks every node; existing route art
shows three regions (levels 1–3, 4–6, 7–8). All eight seal icons appear in the
header. Retry/New run resets HP, capacity, records, seals, gifts and technique
position; there are no checkpoints. Return to title discards the run.

## Setup and verification

Pinned Godot **4.5.1 Standard**, exact build `4.5.1.stable.official.f62fdbde1`,
Compatibility renderer, 390×844 portrait with existing compact 780-high layout.
HTML5 export uses matching `4.5.1.stable/web_nothreads_release.zip`, relative
paths and no threads, service worker or cross-origin isolation requirement.

```bash
game/tests/verify.sh
export XDG_DATA_HOME="$PWD/build/local/data"
export XDG_CACHE_HOME="$PWD/build/local/cache"
export XDG_CONFIG_HOME="$PWD/build/local/config"
~/.local/bin/godot --path game
```

The wrapper runs preservation/independent asset checks, import, deterministic
model/scene/touch/layout tests, scene smoke, Web export, actual exported-pack
full-run clear, dependency/size checks, and copies credits/notices to `build/web/`.
It rejects script/parse failures even if Godot exits zero. Override GODOT_BIN or
GODOT_TEMPLATE_DIR if needed. Tests and art sources are excluded from the pack.

## Model and presentation

`EncounterSpec` Resources contain identity, HP, affinity, intro, backdrop/banner,
and ordered attack element/name arrays. `CombatModel` alone applies HP damage
and emits typed `CombatEvent` impacts. `RunModel` owns carried health, rewards,
route locking and one-time terminal handoff. Views never write combat HP.
`Element` provides the exact matrix, weakness and effect/color mapping.

Each attack lasts 600ms with impact at 300ms; the six original fighter frames
remain unchanged. ENEMY_TURN announces for 350ms. Lethal player attacks suppress
the enemy reply. The coordinator hands off the terminal result after 400ms.
Forecasts and intent read the same declared cycle as actual damage. A turn only
advances after enemy recovery. Both actual and forecast damage clamp to available
health where appropriate; event logs retain nominal damage.

Stopped animation playback samples authored frame durations. Pooled effects
consume the event’s element: blue WATER `328ee6`, red FIRE `ef493c`, brown EARTH
`a47746`, white WIND `ffffff`. Effects land on the defending fighter and never
deal damage. Frame sheets include accents but their stated primary color
occupies more than half of each frame’s opaque pixels.

The shared monotonic clock prevents queued/held/multifinger attacks. Gaps over
250ms pause without unseen damage. Pause preserves impact latches, HP and elapsed
time. Decorative clocks freeze; resume requires a fresh input. Four action
buttons remain 83×96; pause remains 60×60. Route/shrine/reveal use the existing
scene/control geometry. No additional action button or scene was introduced.

## Aseprite pipeline

Existing original, six Moonlit and three journey asset sets stay byte-identical.
New effects live only in `art_sources/elements/` and matching runtime
`game/assets/sprites/elements/` / `game/assets/frames/elements/` directories.
Each of water/fire/earth/wind has an editable `.aseprite`, JSON timing, a
192×48 PNG strip, and a SpriteFrames Resource (four 48×48 frames at 100ms).
All new raster pixels were authored using Aseprite 1.3.18.3-dev Sprite/Image APIs.

```bash
~/.local/bin/aseprite --batch --script-param out="$PWD/build/effect-repro" --script art_sources/elements/generate.lua
python3 game/tests/check_element_assets.py
```

Python only reads/verifies art: SHA256, PNG CRC/decoding, native Aseprite header
and compressed cel decoding, exact source/runtime pixel agreement, dimensions,
frame uniqueness/nonempty alpha, dominant colors, metadata and timing.
`element_asset_manifest.json` pins 20 source/metadata/runtime/frame files.
Runtime tests verify lossless imports, frame regions and duration, effect
selection for both actors and cleanup on reset. No alternate raster authoring
tool was used. Original reactive PatternSpec/StrikeSpec stay unused/excluded.

## Local artifact and visual QA

Serve the entire `build/web/` bundle over HTTP, never `file://`. No push or
Pages deployment was performed. The live deployed baseline could not be inspected
because web access failed and curl could not resolve the hostname.

With display access, run after the XDG setup:

```bash
~/.local/bin/godot --path game --script res://tests/native_visual_smoke.gd
```

The script captures a complete 390×844 run including every first player/enemy
impact into `qa/mobile/eight-seals/`. Native X11/Wayland and Xvfb attempts failed
before rendering here; no game screenshots or visual acceptance are claimed.
The four source strips were inspected directly. Browser WebGL, touch, safe areas,
physical iOS/Android lifecycle, readability and performance remain unverified.
See [dated QA](../qa/mobile/eight-seals/2026-09-12-validation.md) and
[stop reason](../STOP_REASON.md). Prior results remain in historical QA folders.
