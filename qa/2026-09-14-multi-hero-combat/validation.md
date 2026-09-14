# Multi-hero combat QA — 2026-09-14

Started from clean HEAD `ce55a48` in the parent workspace. Completed in four
bounded passes. No push or deployment. No subagents were used; independent
verification is a separate exported-pack driver, recursive dependency verifier,
read-only baseline comparison and the existing independent asset decoders.
The requested Astra/medium model setting is controlled by the session environment;
no claim is made that a model switch was performed. Honcho access was unavailable
under the approval policy; repository facts were used.

## Implemented and preserved

- Main Hero / Kira selector, explicit living target selection, WATER Tide Arc,
  optional auto Support Strike/Ward Pulse, fallen fallback and persistent choices.
- Three resource-defined skills: Flame Dash, Stone Guard, Windstep. Exact formulas,
  ordered guard/evade, two intervening-action cooldowns and independent shrine
  development are documented in the READMEs.
- Typed EnemyState party model, slot-ordered replies, whole-party victory,
  per-slot sprites/cards/HP/role/intent, selected-target forecasts, typed events
  and complete serialization/replay assertions.
- Five configured party nodes (zero-based): 1 Ash Monk/Gale Assassin;
  4 Twin-cut Retainer/Cinder Rival; 7 Iron Vanguard/Gate Guard;
  10 Coast Ronin/Ash Monk/Earth Sentinel; 11 Tempest Sovereign/Iron Vanguard.
  Original leader HP 8/16; each minion 3 HP. Seven area nodes remain single.
- Twelve distinct UnitSpecs/four bosses, six weapons/four sword visuals,
  four-area branch map, seeded normal damage, elemental cycle, first-boss Kira
  recruitment, shrine development, portrait and single-threaded Web retained.
- No new raster art. Separate baseline comparison confirms **200 tracked
  art/source/frame/UI files** byte-identical to ce55a48. All **74 original test
  directory files** retained. The only edited old test assertions' surrounding
  behavior is two area-campaign time advances extended for extra replies;
  assertions themselves are retained. No skip/todo/only or parse suppression.

## Gates and exact observed counts

| Pass | Targeted combat checks | Full suite checks | Failures at passing gate |
| --- | ---: | ---: | ---: |
| 1: pure model and abilities | 51 | 20,852 | 0 |
| 2: party campaign and controls | 157 | 20,988 | 0 |
| 3: broad rules/replay/export verification | 2,066 | 22,897 | 0 |
| 4: final portrait/input review and documentation | 2,175 | 23,006 | 0 |

Each pass finished with targeted checks and `game/tests/verify.sh`. Full-suite
counts include targeted suites; do not add them as unique assertions. Final gate
also separately ran **225 sword** and **96 companion** checks, both zero failures.
The existing campaign matrix covers six starting pairs × four swords × three
seeds = **72 full campaign runs**, including opposite traversal order.

The separate exported-pack driver passed **1,051 assertions** across **three
full campaigns**, **15 party clears**, **39 Tide Arcs**, **81 skill uses**. The
original exported smoke also passed its exact legacy clear (**8 encounters,
19 attacks, 11 replies**) and an additional 12-node/four-boss normal-attack clear,
recruitment, loot/shrine/map flow and all six equipped sword selections.

New checks cover all sword/Kira-development/affinity/seed combinations, actual
versus independently computed skill results, 1–3 enemies, ward/guard depletion,
evade/fatigue, lethal suppression, dead target rejection/fallback, actor and target
locking, cooldowns, persistence/reset, complete typed replay equality and all
original single-area resources as executable solo regressions.

Headless scene checks use 390×844 and 390×780: touch bounds, non-overlapping
controls/log/hint/attacks, modal exclusivity, actual Godot font widths for every
party card, full enemy-frame bounds/separation, per-unit SpriteFrames, selected
HP and disabled fallen cards. Raw InputEventScreenTouch commits exactly one
Kira action even on repeated down events. This is structural verification,
not visual or physical-device acceptance.

Failures repaired within their gates: typed-array initialization and self-script
retention; legacy single-foe log/effect compatibility; compact 780 breakpoint and
log/hint/companion geometry; nested test fixture exposed by stricter validation.
Additional review fixed selected-target max HP, bounded group lunges, persistent
last-action results and clock eligibility for new touch controls.

## Assets, pack and budgets

Aseprite reopened/reproduced the four sword sheets and two derived player sheets:
**six PNG and six JSON documents byte-for-byte**, in
`build/multi-combat-reproduction`. Existing native/independent source, moonlit,
journey, element, hero, unit, sword and derived-body checks pass. Sword verifier
reports **163 prior art hashes**, 20 sword file hashes, 16 distinct frames;
derived-body verifier reports 10 file hashes. All original art remains unchanged.

Final Web artifact: `build/web/index.html` and siblings.
PCK: **262,668 bytes**, **301 entries**, SHA256 `0adbd7561a62f3c3bd6971e28ca90d5cb6bda0e58a5e4efaa8051074190befd7`.
Bundle: **38,756,436 raw bytes / 9,492,654 gzip bytes**. Unchanged PCK budget
1 MiB; bundle gates 40 MiB raw / 10 MiB gzip. Dependency checker verifies
**14 expansion roots / 74 recursive dependencies**, including party/skill specs,
scenes, scripts, SpriteFrames and every referenced imported atlas. Tests and
editable art sources remain excluded; thread support remains false.

## Native attempts and environmental limits

The supplied X11 display failed before rendering; Wayland fallback also failed.
A second `xvfb-run` attempt could not establish listening sockets and the engine
again failed before rendering. **Zero native game captures** were produced.
Logs: `native-x11.log`, `native-xvfb.log`, `xvfb-server.log`.
`native_multi_combat_smoke.gd` is parse-gated and ready to capture six frames
covering 390×844 main/Kira/impact/skills and 390×780 combat/skills on a working
display. No browser, touch-device, WebGL performance or safe-area acceptance is
claimed. Editor/export logs contain sandbox socket-listener errors; no script,
parse, failed-load or test errors were ignored by the passing gates.

`git diff --check` passed. `git add -A` was attempted and failed with read-only
`.git/index.lock`; commit is unavailable in this sandbox. Changes remain local
and uncommitted on **ce55a48** in the requested parent workspace. No push/deploy.

## Evidence

Passing repaired gate logs: `pass1-targeted.log` / `pass1-verify.log` through
`pass4-targeted.log` / `pass4-verify.log`. These retain the passing reruns; they
are not an archive of every failed intermediate attempt. Asset reproduction:
`aseprite-reproduction.log`. Independent byte comparison: `preservation.log`.
Commit attempt: `commit-attempt.log`. Exact changed/new files: [files.md](files.md).
