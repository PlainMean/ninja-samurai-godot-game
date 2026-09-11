# Eight Seals QA — 2026-09-12

Starting commit: `21e178f`, clean working tree. Completed two bounded passes;
maximum was five. Plan: `.hermes/plans/2026-09-12-eight-seals.md`.
No push, deployment, backend, audio dependency or external messaging.

## Exact content delivered

| Level / Resource ID | Guardian | HP | Affinity / weakness | Reply cycle | Backdrop |
| --- | --- | ---: | --- | --- | --- |
| 1 gate_guard | Gate Warden | 3 | WATER / WIND | WATER | gate |
| 2 fire_rival | Cinder Rival | 4 | FIRE / WATER | FIRE, FIRE, WIND | courtyard |
| 3 earth_sentinel | Cairn Sentinel | 5 | EARTH / FIRE | EARTH, WATER | gate |
| 4 wind_assassin | Gale Assassin | 3 | WIND / EARTH | WIND, FIRE | courtyard |
| 5 courtyard_retainer | Twin-cut Retainer | 4 | WATER / WIND | WATER, WIND | courtyard |
| 6 ember_monk | Ash Monk | 4 | FIRE / WATER | EARTH, FIRE | dojo |
| 7 mixed_elite | Fourfold Ronin | 5 | EARTH / FIRE | WIND, WATER, FIRE, EARTH | courtyard |
| 8 dojo_master | Moonlit Master | 5 | WATER / WIND | WATER, FIRE, EARTH, WIND | dojo |

Five new encounter Resources; three extended. Eight combat identities share the
preserved samurai art. Techniques have authored names in each Resource; fixed
stance and rotating attack elements are distinct concepts, both shown on screen.
Seven shrine choices retain exact original healing/capacity rules. Eight seals,
route statuses and final archive are deterministic. No new controls or scenes:
eight retained scenes are duel, arena, fighter, hud, run_modal, route, shrine,
reveal. Only hud.tscn placeholder text changed; existing scripts coordinate them.

Four new effect sets: water, fire, earth, wind. Each has one editable `.aseprite`,
JSON, canonical PNG, runtime PNG and SpriteFrames resource: **20 pinned files,
16 distinct 48×48 frames, four 192×48 strips, 100ms/frame**. Sources and generator
are isolated in `art_sources/elements/`; runtime copies in
`game/assets/{sprites,frames}/elements/`. Water #328ee6, fire #ef493c, earth
#a47746, wind #ffffff dominate each frame. All new raster pixels were authored
through Aseprite 1.3.18.3-dev Sprite/Image APIs. Source strips were opened and
visually inspected: blue curled wave, red flame, brown chunks, white air arcs.
These are asset inspections, not screenshots of the game.

## Actual gates

- Clean baseline `verify.sh`: **3,677 checks, zero failures**, full export/pack
  success; `baseline-verification.txt`.
- Pass 1 targeted suite: **13,776 checks, zero failures**;
  `pass-1-targeted.txt`. Initial import succeeded (editor debugger socket warning
  from restricted environment retained in the log).
- Final pass 2 suite: **13,944 checks, zero failures**;
  `pass-2-verification-complete.txt`, `pass-2-targeted-final.txt`.
- Full `game/tests/verify.sh`: **exit 0**, pinned engine, preservation/asset
  checks, imports, script check, tests, ordinary main-scene smoke, Web export,
  exported main-scene smoke, actual exported-pack eight-encounter full clear,
  and bundle dependency/size checks all pass.
- Exported clear: **19 effective attacks, 11 varied enemy replies, 8 seals**;
  effect resources loaded and player impact sprites asserted inside the pack.
- Web pack: **123 entries / 111,796 bytes** (below the retained 1 MiB limit).
  Bundle: **38,602,182 raw bytes / 9,426,210 locally gzip-compressed bytes**.
  Single-threaded relative paths; no service worker. These are local file sizes,
  not browser transfer/performance measurements.
- All **69 pre-existing tracked art/archive/runtime files** compared directly
  to HEAD and remain byte-identical; original hash manifests unchanged. Existing
  preservation checks plus new independent Aseprite compressed-cel/PNG pixel
  equality, dimensions, nonempty/unique frames, binary alpha, dominant colors,
  JSON timing and 20 hashes pass. Python only reads pixels.
- `git diff --check`: exit 0, `diff-check.txt` (empty success output).
- Native 390×844 capture attempted: X11 unavailable, Wayland cannot connect.
  Xvfb fallback also failed. `native-visual.txt`, `native-xvfb.txt` retain errors.
  **No game screenshot captured; no native visual acceptance.**
- Current deployed baseline: web tool rejected URL; curl DNS failed, retained in
  `deployed-baseline.txt`. Historical QA's 6889955 deployment is not proof of the
  current live version. No equivalence/deployment claim.

Coverage retains the original literal 16-pairing matrix plus NONE and exact
three-WATER timing tests using verbatim test-only Resource fixtures. Obsolete
three-level run expectations were migrated to literal eight-level totals while
retaining behavioral assertions. Expanded checks cover exact order/HP/affinity/
weakness, eight-turn cycle repetition, forecasts and typed actual impacts,
all enemy/player effects and their color metadata, every lethal suppression,
all 128 shrine combinations, all eight defeat/retry positions, route locks,
one-time rewards/handoffs, results/reset/full clear, six scaled touch clears,
120 retries, existing lifecycle/geometry, UI font widths, and pack dependencies.
No skip/todo/only markers or weakened behavioral assertions were introduced.

## Failures discovered and corrected in pass 2

The first full gate passed the test runner but failed normal scene startup:
const-preloaded encounter Resources could instantiate before their scripts
compiled. Moving encounter loading to typed runtime initialization fixed normal
main-scene startup. Intent selection lives in CombatModel; specs remain data.
The intermediate unsuccessful load-order attempts are preserved as
`scene-load-fix*.txt`; successful normal startup is `scene-load-fix-4.txt`.
The next export smoke rejected four omitted effect SpriteFrames. The explicit
export allowlist now includes all five new encounters and all four effect
resources. Both failed wrapper attempts remain in `pass-2-verification.txt`
and `pass-2-verification-final.txt`; neither is reported as passing. The final
wrapper detects script failures even if Godot exits zero, unchanged.

## Stop and artifact

Stopped after pass 2 at the first remaining quality boundary: native/browser/
physical-device visual acceptance is unavailable. No further features/passes
started. WebGL/touch, iOS/Android safe areas, real lifecycle, readability, mobile
frame times/memory and network delivery remain unverified. Headless assertions
and source-strip inspection do not replace those checks.

Runnable local artifact: `build/web/index.html` plus all sibling bundle files.
README, architecture/pipeline guide, CREDITS and STOP_REASON updated. Local commit
result is recorded in STOP_REASON; no push or deploy was attempted.

Commit attempt: `git add` failed with exit 128 because `.git/index.lock` cannot
be created on the read-only filesystem. `git commit` therefore did not execute.
No local commit exists for this change; all verified work remains uncommitted.
Exact error: `commit-attempt.txt`. No escalation/push/deploy attempted.
