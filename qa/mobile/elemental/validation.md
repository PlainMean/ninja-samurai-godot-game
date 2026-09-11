# Elemental turn-based revision — 2026-09-11

Implementation and headless/export gates pass. The scripted native 390×844 smoke remains blocked by the display environment, but an independent desktop Godot launch and capture verified the initial 390×844 player-turn presentation: four elemental buttons, WATER enemy label, WIND weakness, health, seals, turn count, and modal text are visible without clipping. Full sequence screenshots, browser interaction, and physical-device acceptance remain incomplete.

## Rules and decisions

TITLE → INTRO → PLAYER_TURN → resolve PLAYER_ATTACK → ENEMY_TURN → resolve ENEMY_ATTACK → next PLAYER_TURN. Player turns have no deadline. Resolution disables all four attack buttons, consumes one impact per attack, and automatically advances the enemy. Lethal attacks finish their original animation, cancel the other side's turn, and hand off results once after 400 ms.

Rows attack columns. E2 = EFFECTIVE, 2 damage. N1 = NEUTRAL, 1 damage.

| Attacker / defender | FIRE | WATER | EARTH | WIND |
| --- | --- | --- | --- | --- |
| FIRE | N1 | N1 | E2 | N1 |
| WATER | E2 | N1 | N1 | N1 |
| EARTH | N1 | N1 | N1 | E2 |
| WIND | N1 | E2 | N1 | N1 |

Every other pairing, including NONE, is neutral. The existing player has no affinity, so each WATER reply deals 1. Selecting an attack does not change affinity. Explicit affinity is supported by the model and tested for all five values: WATER against FIRE deals 2, everything else 1.

Gate Warden / Twin-cut Retainer / Moonlit Master retain 3 / 4 / 5 HP, ordering, scenery, and seals. All three are WATER; the HUD and intros explicitly display WATER and Weakness: WIND, including the final boss. Four 83×96 buttons fit the original 350 px action row at 390×844. The compact layout remains supported.

Mend still restores 2 HP, clamped to maximum and disabled when full. Long Breath's obsolete +300 ms counter-window reward now grants +1 max HP and restores 1 HP. Iron Resolve grants +1 max HP and restores 1 HP; choosing both stacks to 7 max HP. Reward IDs and choice order remain. Damage is never modified by rewards.

## Actual results

Commands ran from the repository root. Godot commands use repository-local `build/local/{data,cache,config}` XDG directories as configured by `game/tests/verify.sh`.

| Check | Actual result |
| --- | --- |
| Baseline `game/tests/verify.sh` | Exit 0; 3,179 checks / 0 failures; preserved asset checks, import, headless smoke, Web export and exported three-encounter run passed |
| Final `game/tests/verify.sh` | Exit 0; **2,922 checks / 0 failures**; exact engine pin, both asset checkers/manifests, import, native capture script syntax check, full suite, 120-frame game smoke, HTML5 release export, 120-frame pack smoke, complete pack run, notices and Web dependency checker |
| `godot --headless --path game --script res://tests/model_gate.gd` | Exit 0; **1,100 checks / 0 failures** (subset of full suite) |
| Source asset checker / original manifest | Pass; all 18 hashes |
| Moonlit asset checker / manifest | Pass; six sets, 51 frames, all 34 hashes, native/runtime equality and pixel/metadata checks |
| Compare every tracked `art_sources/` and `game/assets/` file to HEAD bytes | Pass; **56 files byte-identical** |
| `git diff --exit-code` for assets, project settings, lifecycle, touch input, manifests and notices | Exit 0; unchanged |
| `git diff --check` | Exit 0 |
| `godot --path game --script res://tests/native_visual_smoke.gd` | Exit 1 before rendering: X11 display unavailable; Wayland connection failed |
| `Xvfb :99 -screen 0 390x844x24 -nolisten tcp` | Exit 1: cannot create listening sockets |
| Native visual capture script `--headless --check-only` | Exit 0; syntax only, not rendering evidence |

The changed check count reflects replacement of obsolete warning/block/dodge/counter cases with elemental cases. Assertions are not suppressed or weakened to accept errors; no skip/todo/only was added. Original imported-image/frame and low-level touch/mouse checks remain. Model coverage includes all 16 independent matrix expectations, each attack against each possible player affinity across all three encounters, exact pre/post impact boundaries, pause in every resolving phase, coarse/fine 30/60/120 Hz equivalence, indefinite choice, invalid input/time, terminal event uniqueness, overkill clamping, and bounded log.

Run coverage includes all four reward combinations, natural neutral-only losses on the master, no fourth encounter, reset and single reward/terminal handoff. Scene coverage includes six complete touch-only runs (1×/2×/3×, both reward paths), 120 loss/retry cycles, node/connection stability, original six-frame attacks, modal bounds, five portrait target sizes, boss element/weakness labels, log/result/turn text, stall/lifecycle pause, held input, second fingers, and a resolution-boundary tap that must not queue another turn.

Godot import/export log the pre-existing socket-listener environment errors but exit successfully. Tests, game smoke, exported smoke and exported run have no script failures. See [final verification](verification.txt), [baseline](baseline-verification.txt), [model gate](model-verification.txt), and [native failures](native-visual-attempts.txt).

## Artifact and preservation

Local entry: `build/web/index.html`; publishable directory: `build/web/`. Current pack: **81,060 bytes, 83 entries**. Complete bundle: **38,569,799 raw bytes / 9,412,826 local gzip bytes**. No network transfer or browser timing is inferred from these measurements.

Godot remains `4.5.1.stable.official.f62fdbde1` Standard with Compatibility and single-threaded Web export. The pack checker requires compiled Element/model/UI scripts, three encounter resources, six support atlases and both original attack atlases. It excludes legacy pattern/strike scripts, tests, tools, source art and JSON; HTML identifies the four elemental controls and threads remain disabled.

No art was created or edited. All original frame resources, source archives, PNGs, metadata, manifests and notices retain their bytes. No Aseprite generation, Python image creation, Pillow, ImageMagick, SVG or diffusion was used. Native screenshot capture uses Godot's rendered viewport only; it did not produce any PNGs because display initialization failed. No subagents were used. Runtime model identity/effort is not independently verifiable from workspace files.

Exact changed-file inventory: [files-changed.txt](files-changed.txt).

## Remaining QA and completion

Run `godot --path game --script res://tests/native_visual_smoke.gd` on a display-enabled host with the same XDG setup. It is designed to save 13 native 390×844 PNGs for title, intro, all three player-turn screens, player impact, enemy turn/impact, next player turn, pause, two reward modals and clear. Inspect text clipping, HUD/log spacing, touch labels, art placement and modal readability. The script passes syntax checking but native execution remains unverified.

Browser WebGL/Compatibility presentation, real browser touch, iOS Safari / Android Chrome, safe areas, browser lifecycle, MIME/HTTPS serving, physical target readability, performance, memory and cold/warm load measurements remain pending. Headless geometry and exported-pack execution are not substitutes for these checks. The previous version's historical deployment evidence does not validate this elemental revision.

After native visual validation and any necessary fixes, rerun the complete wrapper and whitespace check before committing locally. Do not push or deploy as part of this pass.
