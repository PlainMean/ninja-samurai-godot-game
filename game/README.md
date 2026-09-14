# Moonlit Dojo: Four Lands

The default UI now runs the area campaign described in [the root README](../README.md).
`RunModel.begin_area_run(seed)` loads twelve dedicated area EncounterSpec resources from
`data/encounters/areas/` and five party wrappers in `data/encounters/parties/`.
Each leader references a unique data-only UnitSpec in `data/units/`. `begin_run()` retains the original
legacy campaign; old tests explicitly select it. The historical details below
apply to that legacy mode.

RunModel owns the map frontier, node locks, inventory indices, equipped immutable
WeaponSpec, technique levels, rewards and RNG. Four areas form a ring; both guards
must be sealed before that area’s boss. Cleared bosses open neighboring areas.
The map may revisit any unlocked frontier; no movement cost or random encounters.
Each node’s sword is deterministic, so route order changes access to loot.

The Park–Miller stream uses state = (state × 16807) modulo 2147483647;
roll = state modulo 4 + 1. Seed defaults to 1, normalized into 1…2147483646.
Only normal main-hero sword impacts advance it. Retry resets it. A matching-sword bonus is
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
2.5× guard / 3× boss base scale; parties scale each enemy to a mobile-safe
57.6px frame width. The player and legacy route retain their old frames.
Only attack has four newly authored poses; idle/guard/hurt/defeat deliberately
reuse those poses. The multi-combat expansion reuses these assets for independently acting enemies.

The Aseprite-only pipeline and palette inventory are documented in
[`art_sources/units/ASSET_SPEC.md`](../art_sources/units/ASSET_SPEC.md).
`check_unit_assets.py` independently decompresses native cels and PNGs, checks
60 source/runtime hashes and rejects shared silhouettes. `test_units.gd` checks
all twelve identities, palettes via manifest hashes, roles, area/boss mappings,
SpriteFrames, view selection and a full clear. The exported-pack smoke repeats
selection through all twelve nodes; the explicit export roots include each area
resource and pull in its unit/atlas dependencies.

## Multi-hero and party combat — 2026-09-14

`CombatModel` remains the sole HP authority. `EnemyState` is a typed, data-only
runtime slot: EncounterSpec, HP, slot number and per-turn intent accessors.
An empty `EncounterSpec.party` is a single opponent. Nonempty party wrappers
contain 2–3 non-nested EncounterSpecs, referencing original leaders plus small
minion subresources. The exported array uses `Resource` to avoid Godot 4.5's
self-referential script retention; the model validates and converts it to typed
EncounterSpec/EnemyState arrays. No view mutates HP.

Configured zero-based nodes: **1, 4, 7, 10, 11**. Their parties, respectively,
are Ash Monk/Gale Assassin; Twin-cut Retainer/Cinder Rival; Iron Vanguard/Gate
Guard; Coast Ronin/Ash Monk/Earth Sentinel; Tempest Sovereign/Iron Vanguard.
Minions have 3 HP. Original leaders retain 8/16 HP, unique UnitSpecs and cycles.
All twelve original area files and eight legacy files remain unchanged.

`select_actor`, `select_target`, `request_kira_attack`, `request_skill` and
`set_auto_companion` validate the player-turn boundary. Invalid/dead targets
are rejected. The default/fallback is the first living slot. Selection locks
at action commitment. Compatibility `spec`/`enemy_hp` aliases project the
selected target; `encounter_spec` retains the overall encounter wrapper.

One action has a 300ms impact within 600ms animation. At recovery, each living
enemy replies in ascending slot order: 350ms announcement + 600ms attack, with
impact at 300ms. A single-enemy round still takes 1.55s; each additional survivor
adds 0.95s. Player death stops remaining replies; full-party death wins without
replies. The turn number and cooldowns advance once after the entire reply phase.
Pause retains impact latches and never replays damage. New touch actions use
the same clock/eligibility sampling as normal attacks, so a resolution-time tap
cannot become a queued action.

Resources in `data/skills/` define all three skills. Let D be skill development
0–2 and A be the unchanged directed elemental advantage (0 or 1):

| Skill | Exact formula | Extra effect |
| --- | --- | --- |
| Flame Dash · FIRE | 5 + D + A damage to selected target | None |
| Stone Guard · EARTH | 0 damage | Guard pool 3 + D for this reply phase |
| Windstep · WIND | 3 + D + A damage to selected target | First living reply evaded |

Guard absorbs damage in slot order. Ward Pulse is then applied to the first
actual reply only; unused ward is not spread across the party. Evasion removes
that reply's damage and Kira fatigue entirely. Each skill requires two complete
intervening actions before reuse: cooldown is committed at 3, then decremented
at each completed round. Skill mastery upgrades the kit once per shrine, capped
at +2, without consuming the existing technique or Kira development choices.
No skill rolls RNG. Forecasts account for support, selected-target lethal,
remaining enemies, guard and evade without changing state.

Tide Arc is **3 + Kira development (0–2) + WATER advantage**. It ignores main
weapon, technique locks and RNG, and consumes the full action. Manual Kira turns
never trigger auto support. Kira loses one HP per actual reply (including blocked
ones), falls at zero, and automatically returns control to Main Hero. Actor/auto
preferences and progression are carried by RunModel; targets, guard, evade and
cooldowns are fresh per encounter. Title/retry clears all progression.

Typed events include kind, actor, element, damage, skill id, turn, selected
encounter slot, all party HP, player/Kira HP, guard, evade, cooldowns and seeded
roll/bonus fields. For player actions `target_slot` is the attacked enemy; for
reply events it identifies the replying encounter slot, also explicitly in
`source_slot`. `target_actor` distinguishes enemy, main and Kira recipients.
`values()` serializes all fields for deterministic replay comparisons.

`CombatControls` owns mobile target cards, 118×48 actor/skills controls, the
350×96 Tide Arc action and a separate Skills panel with 334×74 skill choices.
The modal disables underlying raw-touch controls. Arena has three persistent
enemy views; all assets are reused, preloaded/resource-referenced and nearest
filtered. Every enemy shows its own name, role, element, HP and next intent
on a target card. Hover tooltips carry full intent names. Kira keeps her poleblade;
Main Hero keeps the equipped sword overlay. No new raster art was authored.

Verification entry points: `multi_combat_gate.gd` (pure + scene),
`export_multi_combat_smoke.gd` (independent release-pack campaigns), and
`native_multi_combat_smoke.gd` (six real captures when a display is available).
`verify.sh` gates these alongside all existing suites, independent asset checks,
legacy/area pack clears and recursive dependency/budget checks. Budgets: PCK
1 MiB, Web bundle 40 MiB raw / 10 MiB gzip, single-threaded export unchanged.
Current observed results and display limitations: [dated QA](../qa/2026-09-14-multi-hero-combat/validation.md).

## Companion rules and resources

`data/heroes/kira.tres` is a data-only `HeroSpec`: Kira the Tideblade, WATER tide
warden, 6 HP, Support Strike, base attack range 1–2, SpriteFrames and the
`first_boss_victory` join condition. RunModel owns her joined/HP/ability/mastery
state and `first_boss_defeated`. A victorious boss terminal handoff seals the
node and enters RECRUIT exactly once, before loot, shrine, map or archive.
The 64px Continue button is required. Boss detection uses node slot, independent
of the selected region; Fire remains the shipped starting area. The legacy
route has one boss, its final Moonlit Master, so its exact 19 attacks/11 replies
remain unchanged and recruitment precedes its archive reveal.

CombatModel resolves the main hit first at the existing 300ms impact boundary.
If auto support is enabled, the main actor acted, the selected enemy survives
and Kira is alive, she acts once: Support Strike deals
`1 + mastery + WATER matchup` (1–2 / 2–3 / 3–4), or Ward Pulse blocks
`1 + mastery` damage from that turn’s reply. Mastery starts at zero and caps at
two, displayed as levels 1–3. Neither support nor forecasts consume RNG. Main
sword damage and the directed elemental cycle are unchanged. Either lethal hit
suppresses that enemy’s reply. Other living slots reply in ascending order,
each followed by one fatigue damage to Kira unless evaded. Fallen Kira stops acting; the
main player remains controllable. Typed events carry companion HP and support
or ward amounts. The intent/attack forecasts include support lethal and ward.

HP persists through handoff and loot; entering the shrine restores Kira to six,
including revival. Once per shrine, optionally choose Support Strike, Ward Pulse,
or an upgrade before taking the existing player technique choice. This extra
choice consumes no player technique reward; the existing sword/inventory flow
is preserved. Her choice/mastery persists across later nodes; retry/title clears
all ally state. HUD shows element, HP, ability level and ready/next-turn/fallen
availability; WATER FX reuse existing permitted assets. The separate arena
sprite and join portrait only project model state. Manual Tide Arc replaces
the main action when Kira is selected; it never stacks with auto support.

All new rasters were authored/exported by Aseprite Lua Sprite/Image APIs in
`art_sources/heroes/generate.lua`. The editable source, JSON and 192×48 strip
contain four distinct 48×48 poses, one `support` tag and 100ms timing. Nearest
filtering, lossless imports and no mipmaps preserve pixels. The manifest pins
six file hashes, four RGBA frame hashes and seven palette colors. The independent
read-only decoder checks compressed source cels against decoded PNGs, and 192
silhouette comparisons against all old enemy poses. `prior_hero_art.sha256`
protects all 110 prior tracked art/frame assets.

```bash
XDG_CONFIG_HOME="$PWD/build/local/config" ~/.local/bin/aseprite -b --script-param out="$PWD/build/hero-repro" --script art_sources/heroes/generate.lua
XDG_CONFIG_HOME="$PWD/build/local/config" ~/.local/bin/aseprite -b --script-param src="$PWD/art_sources/heroes" --script art_sources/heroes/verify.lua
python3 game/tests/check_hero_assets.py
XDG_DATA_HOME="$PWD/build/local/data" ~/.local/bin/godot --headless --path game --script res://tests/companion_gate.gd
bash game/tests/verify.sh
```

The explicit export roots include HeroSpec, Kira’s resource, SpriteFrames and
PNG. Pack checks verify import/texture entries and load/select her during a full
four-area clear, alongside the full legacy clear. Native capture entry point:
`res://tests/native_companion_smoke.gd`. This session’s X11 and Wayland attempt
failed before rendering; no game screenshots or browser/device acceptance are
claimed. See [companion QA](../qa/2026-09-13-companion/validation.md).

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
scene/control geometry. The legacy combat action controls retain their original geometry.

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

## Equipped sword presentation

`WeaponSpec.visual()` maps the six existing weapon resources through four
`WeaponVisualSpec` resources under `data/weapon_visuals`. No combat or ownership
rules live in these resources. `Duel._present_fighters()` projects the current
weapon on every refresh. `FighterView` attaches a nearest-filtered sword overlay
to the original hand/tip pose coordinates for attack, idle, guard, dodge, hurt
and defeat. Aseprite-derived body sheets hide old steel layers while retaining
all original body cels and animation timing. The original frame resources remain
available for enemy/legacy use. Kira retains her independent sprite and poleblade.

AreaPanel shows elemental icons for preview, equipped inventory/map and loot;
HUD follows the same weapon, including compact layout. New resources are in the
Web export allowlist. Run `res://tests/sword_gate.gd` for targeted selection and
equip checks; `verify.sh` also gates native-script parsing, independent sword/body
asset verification and exported-pack selection. All previous assertions remain.

Sources, palette and reproduction instructions: `art_sources/weapons/ASSET_SPEC.md`.
QA and the Aseprite contact sheet: `qa/2026-09-13-elemental-swords/`.
