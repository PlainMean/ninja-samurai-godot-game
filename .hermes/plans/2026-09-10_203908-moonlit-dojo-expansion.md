# Moonlit Dojo: Three Seals — executable expansion plan

## Scope and execution contract

Evolve the current duel into a compact, three-encounter portrait game: **Moonlit Dojo: Three Seals**. A ninja challenges three samurai guarding a moonlit dojo, earning a seal at each victory and choosing a small technique between fights. Read the enemy's cue, Block or Dodge, then Strike during the earned opening. One successful run targets 60–100 seconds including introductions and choices; deliberately waiting can extend it indefinitely.

This document is the only deliverable of this planning turn. All implementation, asset authorship, validation commands, exports, evidence capture, and deployment below are future work. Do not interpret inspection of historical test reports as a fresh test pass. This plan supersedes the old plan's one-encounter/no-new-art scope but preserves its technical constraints and regression guarantees. Preserve the previous plan unchanged.

Use Godot **4.5.1 Standard**, build `4.5.1.stable.official.f62fdbde1`, GDScript, Compatibility renderer, matching `web_nothreads_release.zip`, single-threaded HTML5, logical **390×844** portrait, and GitHub Pages. Keep touch-only completion, real desktop mouse support, no input emulation, no audio dependency, no plugins, C#, GDExtensions, physics, networking, procedural maps, movement joystick, equipment inventory, or persistent save requirement. Three fixed encounters, three buttons, two intermission choices, one reusable arena. No random combat selection or difficulty scaling.

All paths below are relative to `/home/cmuxao/repos/ninja-samurai-godot-game`; `res://` means `game/`. Use these defaults without requesting design decisions. Implementation does not imply a commit, push, workflow dispatch, or public publication; prepare and validate the complete Pages artifact first and deploy only when the execution session authorizes publication.

## Inspected baseline

Read the root and game READMEs, prior plan `.hermes/plans/2026-09-10_192352-ninja-samurai-godot-mobile-game.md`, project/export configuration, scene, all five gameplay/input/lifecycle scripts, SpriteFrames usage in tests, test runner and verification scripts, asset manifest, both asset specifications, Lua generators/verifiers and reports, credits, web shell, workflow, and mobile validation record. Viewed both archived 768×128 sprite previews. No applicable repository `AGENTS.md` was found. Initial `git status --short` was empty.

The current scene is `game/scenes/duel.tscn`; `duel.gd` coordinates a pure `RefCounted` combat model. It currently has 3 HP per actor, 700 ms rest, 900 ms warning, 600 ms attacks with impact at 300 ms, and a 1,200 ms counter opening. Boundary-consuming simulation and stopped, model-driven AnimatedSprite2D playback already prevent duplicate hits and timing drift. Retain these properties when generalizing.

Both existing runtime sheets are 192×32 RGBA strips containing six right-facing 32×32 attack poses at 100 ms each. Source tag `attack` is forward, frames 1–6; runtime playback is nonlooping. Ninja has dark navy clothing, red scarf, and steel blade; samurai has indigo armor, gold kabuto crest, muted red sash, and katana. Both boot soles use row 29, rendered with offset `(-16,-30)` at 4×. Only samurai is flipped at runtime. The ninja slash includes alpha 210: never enforce binary alpha on the original ninja or rewrite it. Existing originals have no idle, block, dodge, hurt, or defeat tags.

Preserve byte identity of all 18 entries in `game/tests/asset_manifest.json` and `source_assets.sha256`, including both complete `art_sources/ninja/` and `art_sources/samurai/` archives and both runtime attack PNGs. Do not run their generators or verifiers in place: verifiers overwrite reports, and the samurai generator alone does not reproduce every advertised export. Original source paths in the old plan refer to a previous workspace and must not become runtime dependencies.

The historical record reports 309 checks, import, scene smoke, export and exported-pack smoke passes. It also reports that HTTP socket creation and Chromium launch were blocked and physical mobile coverage was unavailable. Browser acceptance is still pending. The old bundle was 38,516,354 raw bytes / 9,387,531 locally gzipped bytes, mostly engine Wasm. These are baselines, not current measurements. The existing resource-selective export previously omitted a preload-only script: explicit dependency coverage is a release gate.

## Player experience and progression

1. Title: “Moonlit Dojo” / “Three Seals”, three empty seal icons, text “Read the cue. Defend. Counter.” and **Begin run**.
2. Encounter introduction: enemy name, progress `1 / 3`, one concise rule, and **Fight**. No combat clock runs behind an introduction.
3. Fight: readable text/icon announces attack type and sequence position; tap one defense per warning, watch the full attack, then tap Strike in the opening. Health and completed seals remain visible.
4. After encounters one and two: complete lethal attack playback, show the defeated enemy, award exactly one seal, then show an intermission with two technique cards. Tapping one card applies it once and enters the next introduction; no separate confirmation tap.
5. After encounter three: show all three seals and **Dojo cleared**, remaining HP, counters landed, successful defenses, and **New run**. No letter grade or speed incentive.
6. At zero player HP: finish the lethal enemy attack, cancel any remaining combo strikes, play the defeat pose, then show **Run ended**, `Seals X / 3`, a contextual defense hint, and **Retry run**. Retry always returns to encounter-one introduction with fresh HP and no upgrades; there is no checkpoint retry.

Start with **5 / 5 player HP**. Health carries between encounters. All enemy hits deal 1; every valid ninja counter deals 1. No automatic healing. Counter count counts landed impacts, including lethal ones. Successful-defense count counts individual defended enemy impacts; damage count records actual lost HP. These counters reset per run. No storage access is needed; refresh returns to title.

Intermission one offers **Mend** (“Restore 2 HP”, clamped to max) or **Long Breath** (“Counter windows +300 ms for this run”). At full HP, Mend is disabled and reads “Health full”; Long Breath remains available. Intermission two offers **Mend** or **Iron Resolve** (“Max HP +1; restore 1 HP”). Iron Resolve sets max HP to 6 and increases current HP by 1, clamped to 6. Upgrades are offered only once at their specified stage and cannot stack through repeated taps. Neither changes attack animation speed or warning duration. Display current and projected HP on healing cards and the active technique name below the HUD.

## Encounters and exact combat specification

### Encounter configuration

| ID / title / backdrop | Enemy HP | Repeating attack pattern | Rest before each pattern | Base counter window | Introduction text |
| --- | ---: | --- | ---: | ---: | --- |
| `gate_guard` / Gate Warden / `gate` | 3 | `single_cut` | 700 ms | 1,200 ms | “Tap Block during CUT. Then Strike when OPEN.” |
| `courtyard_retainer` / Twin-cut Retainer / `courtyard` | 4 | `double_cut` | 650 ms | 1,100 ms | “Block both cuts. Release between taps. Counter after cut 2.” |
| `dojo_master` / Moonlit Master / `dojo` | 5 | `heavy_cut`, `single_cut`, `double_cut`, repeat | 600 ms | 1,000 ms | “Dodge HEAVY. Block CUT. Two cuts need two blocks.” |

One samurai is present at a time. Keep the original attack sheet for every enemy. Distinguish rank through name, backdrop, placed banner, and pattern icons rather than a runtime recolor or helmet overlay that drifts across old attack frames. Enemy variety is behavioral, not three newly invented fighter silhouettes.

`single_cut`: one normal warning, 900 ms for Gate Warden and 750 ms for Master, followed by the original 600 ms attack. `double_cut`: warning 1 for 850 ms (Retainer) or 750 ms (Master), attack 1 for 600 ms, then warning 2 for 700 ms (Retainer) or 650 ms (Master), then attack 2 for 600 ms. `heavy_cut`: warning for 1,050 ms and the same 600 ms attack; show a heavy icon and “HEAVY — DODGE”. No acceleration or clipping of original attack frames. The warning pose and UI carry the extra anticipation.

Each enemy attack impacts at exactly 300 ms, once. Every enemy attack must finish its full 600 ms before the next warning, opening, or terminal sequence. The master advances its pattern index after the current pattern's resolution, including missed defenses and expired openings; an accepted Strike advances it only after the player's 600 ms animation ends. Restarting a warning after pause must not advance the pattern.

### Defense and input rules

Keep three fixed buttons: **Block**, **Dodge**, **Strike**. In every TELEGRAPH both defense buttons are enabled until either is accepted; Strike is disabled. A fresh down selects one defense for that warning and locks both until the next warning. Correct choices: Block for normal cuts; Dodge for heavy cuts. Wrong choices are accepted but fail at impact, cost 1 HP, and cannot be corrected by another tap in the same warning. Show “Guard set” or “Dodge set” immediately; reveal success/failure at impact. All gameplay input outside valid phases is ignored and unbuffered. Holding never repeats. A disabled press continues to own its pointer until release, preserving the existing input contract.

For a double cut, reset the defense latch at warning 2. Require a new down after release, and display `CUT 1 / 2` then `CUT 2 / 2`. A counter opening is earned only if **every strike in the pattern** was defended correctly. Missing the first strike does not cancel the second unless HP reaches zero; a successful second defense still prevents its damage. Never offer an opening between the two strikes. Keep a pattern-wide `all_defended` flag that is not reset by a pause on warning 2.

After a fully defended pattern, enter COUNTER_WINDOW. Strike accepts once, starts the ninja's unchanged 600 ms attack and hits at 300 ms. Missing the opening costs no HP and proceeds to the next pattern. Final enemy HP reaching zero at ninja impact does not show intermission early. Input intervals remain half-open: `[0, duration)`. At an exact deadline advance the model first, then evaluate input against the resulting phase. Preserve the existing epsilon tolerance for floating-point boundary traversal.

### Model states, pause, and presentation timing

Run states: `TITLE`, `INTRO`, `FIGHT`, `INTERMISSION`, `CLEARED`, `FAILED`; `paused` is an orthogonal controller flag. Encounter model states: `READY`, `REST`, `TELEGRAPH`, `ENEMY_ATTACK`, `COUNTER_WINDOW`, `PLAYER_ATTACK`, `WON`, `LOST`. Keep the existing state names to reduce migration risk. Add strike and pattern indices rather than separate states for every enemy.

After the combat model reaches WON/LOST, a **400 ms terminal presentation delay** shows the new defeat animation before the run controller exposes intermission/results. The attack has already completed by then. Terminal handoff is latched, emits only once, and is canceled by reset. During this delay the combat model is frozen, no actions are enabled, and lifecycle pause freezes the delay. Final frame of defeat remains behind the modal.

Preserve focus/visibility/landscape pause and a live engine delta or monotonic gap **greater than 250 ms** causing pause without consuming reaction time. Resume always needs a tap. Clear all pointers and latched input on modal changes. Pausing a TELEGRAPH or pre-impact ENEMY_ATTACK restarts that strike at a full warning; retain earlier combo outcomes and pattern index. Pausing a resolved impact preserves its damage/defense result and remaining attack recovery. Restart an open counter window at full configured length. PLAYER_ATTACK keeps elapsed time and impact flag. Freeze decorative/effect clocks on pause. INTRO/INTERMISSION/results remain inert under lifecycle notifications and must not be accidentally turned into FIGHT; landscape overlay still prevents interaction.

Cosmetic dodge is a short backward displacement during ENEMY_ATTACK, reaching 20 logical pixels at impact and returning by attack end. The stance shows a crouch while the dodge is latched. It is not spatial collision detection. Retain the 24 logical pixel attack lunge and round final positions. No camera shake, flashing screen, hit-stop, or independently timed damage callbacks.

## Portrait UI and readability

Use the existing safe-area web container, `canvas_items` stretch and `keep` aspect. At 390×844: content x=20..370, header y=32..148, cue y=174..224, warning bar y=234..242, arena y=252..508, feedback y=524..558, technique/rule text y=574..618, action row y=656..752, footer y=780..808. Keep fighter roots `(131,450)` and `(259,450)` with 4× scale. The 195×128 environment is shown at 2×, origin `(0,252)`, so the floor line is local y=99 / global y=450. Keep scenery subdued behind fighters and leave sky/room breathing room above them.

Header contains title, `Seal 1 / 3` route progress, labeled player/enemy health and enemy name. Pause target is **60×60 logical px** at x=310..370, y=32..92. The route uses three seal icons; never use color alone to communicate completion. Health uses text plus icons, not icons alone. Cue uses a 24–26 px font, body 18–20, small secondary labels at least 16 at baseline. Keep action labels at 18–20, centered and unambiguous.

Action row: three equal **110×96 logical px** buttons, gaps 10 px, total 350 px. Left Block, center Dodge, right Strike; never reorder or replace labels. Inactive controls visibly dim but remain legible. Cue text names the required action; pattern dots and `1 / 2` communicate combo count. Progress bar represents remaining warning/opening time, with text carrying its meaning. Decorative nodes ignore mouse events.

Reuse a full-screen scrim and panel modal; panel occupies x=20..370, y=482..808, with heading, up to three short lines, and either one ≥64 px action or two ≥72 px stacked technique cards. Use Container layouts inside these bounds; verify text minimum sizes fit rather than relying on clipping. Title uses the visible arena behind its lower panel. Health choices include numeric effects. Pause modal uses Resume and a secondary Return to title button; Return to title discards the run immediately, as its label and subtext explain. Every modal action uses the same touch component and clear-pointer transition path.

At shorter portrait sizes, preserve aspect fit and measure final CSS target sizes; 60 px pause remains ≥48 CSS px down to scale 0.8. Required QA includes 360×740 and 390×700 available canvas areas; if safe-area deduction would reduce targets below 48 CSS px, use a compact layout moving the action row/footer upward and reducing arena empty space, not shrinking controls. Keep the 390×844 coordinate model for tests and apply compact layout explicitly through a layout helper. No scroll, keyboard, hover, fullscreen, sound, or installation requirement.

## Exact additional Aseprite asset specification

**All new pixel art must be authored inside Aseprite using its Sprite/Image APIs (Lua) or the Aseprite GUI only.** Default to reproducible Lua using `Sprite`, `Image`, `drawPixel`, `drawSprite`, layers, cels, frames and tags, matching the repository's existing approach. Export through Aseprite only. No Python/Pillow, ImageMagick, SVG rasterization, diffusion/image-generation tools, browser/canvas art, external rasterizers, or Godot-generated raster art. Godot Controls, text, progress bars and panel styles remain ordinary interface rendering; do not use them to synthesize replacement pixel scenery, character sprites, or effects. Read-only Python metadata/hash validation remains allowed.

Put every new editable source and canonical export under **`art_sources/moonlit_dojo/`**. Preserve originals untouched. Use RGBA mode, crisp one-pixel clusters, no antialiasing, gradients, blur, rotation resampling, or fractional scaling. New pixels use alpha 0 or 255. Support poses match original character proportions and right-facing direction, feet ending at y=29, weapon fully inside the 32×32 canvas. Draw actual distinct motion frames, not duplicated frames to meet counts. The first idle pose should visually match the old attack's ready stance.

Palette: ninja support uses the original ninja RGB colors `#090C17 #111727 #1D283C #2E3F53 #445667 #B72036 #EF3E47 #68162B #D5A47D #F8CE9B #9DB8C6 #E4F7F7 #567A94`. Samurai support uses original colors `#151625 #23253E #353B60 #505C80 #7485A0 #572C40 #914758 #BE6B70 #766044 #B89A61 #E0C887 #C29880 #EBC6A0 #6D8397 #B7CBD3 #EDF2DF #7FABB8 #C5DED9`. Scenery/UI/effects use a shared subset `#151625 #23253E #353B60 #505C80 #7485A0 #572C40 #914758 #766044 #B89A61 #E0C887 #B7CBD3 #EDF2DF #7FABB8`, plus wood `#493B45` and mist `#9AAEB2`. Transparent palette entry is separate. Lit floor uses muted midtones so original dark fighter silhouettes remain visible; moon/paper highlights stay away from blades. Do not recolor original PNGs to force palette uniformity.

Each row defines a source basename; create `<basename>.aseprite`, `<basename>_sheet.png`, and `<basename>.json` in the new archive directory. Export one horizontal untrimmed strip, frame order as listed, no padding, extrusion, packing rotation or resizing. JSON is Aseprite JSON-array metadata with frame rectangles, millisecond durations, size and named forward frame tags; its frame/tag indices are zero-based. Ranges below are **Aseprite one-based inclusive**. Runtime loop policy is explicitly defined below; one-frame tags hold their pose.

| Basename | Cell / frames / sheet size | Tags and per-frame durations | Layers / visual purpose |
| --- | --- | --- | --- |
| `ninja_support` | 32×32 / 12 / 384×32 | `idle` 1–2: 400,400 ms loop; `guard` 3–4: 100,100 once, hold 4; `dodge` 5–7: 100,100,100 once, hold 7; `hurt` 8–9: 100,100 once; `defeat` 10–12: 100,100,200 once, hold 12 | `Scarf`, `Body`, `Blade`; idle scarf shift, raised guard, low backward lean, recoil, kneeling exhausted defeat without gore |
| `samurai_support` | 32×32 / 9 / 288×32 | `idle` 1–2: 400,400 loop; `warn_cut` 3: 100 hold; `warn_heavy` 4: 100 hold; `hurt` 5–6: 100,100 once; `defeat` 7–9: 100,100,200 once, hold 9 | `Armor`, `Arms and blade`, `Cloth`; warning silhouettes distinguish shoulder-ready cut from overhead heavy, recoil and kneeling defeat |
| `dojo_backdrops` | 195×128 / 3 / 585×128 | `gate` 1, `courtyard` 2, `dojo` 3: each 100 hold | `Sky or wall`, `Architecture`, `Floor`; moon behind gate, stone courtyard/bamboo edge, interior paper panels/moon window; all fully opaque, floor begins at y=99; uncluttered actor regions |
| `dojo_props` | 16×32 / 5 / 80×32 | `lantern` 1–2: 300,300 loop; `banner_gate` 3, `banner_retainer` 4, `banner_master` 5: each 100 hold | `Fixture`, `Light or emblem`; lantern flickers by replacing two highlight clusters, banners show one/two/three horizontal seal marks, transparent canvas |
| `combat_fx` | 32×32 / 12 / 384×32 | `block` 1–3: 60,60,100 once; `dodge` 4–6: 80,80,80 once; `hit` 7–9: 60,60,100 once; `seal` 10–12: 100,100,200 once | `Core`, `Accents`; steel contact spark, ground dust, non-gory contact ticks, earned seal glint; transparent, effect centered at (16,16) |
| `dojo_icons` | 16×16 / 10 / 160×16 | Single-frame 100 ms hold tags in order: `heart_full`, `heart_empty`, `seal_empty`, `seal_full`, `cut`, `heavy`, `double_cut`, `mend`, `long_breath`, `iron_resolve` | `Outline`, `Fill`; readable at 2×, silhouette differs by meaning; no baked text |

Create **exactly these six sources**, 51 total frames. No extra portrait, splash, app icon, font, GIF or preview set is required. Place lanterns at arena-local `(24,12)` and `(334,12)` at 2×; place the encounter banner at `(294,50)` at 2×, behind the enemy. These are top-left coordinates for 16×32 prop cells. Use effect scale 2×; block/hit center near `(195,390)`, dodge dust at player feet `(111,444)`, and seal glint at the just-earned route icon. One effect instance per category is enough; restart intentionally on a new matching impact, never queue unbounded particles.

Support playback priority: defeat > hurt > active attack > selected defense > warning > idle. Hurt begins at received impact and lasts 200 ms; the attacking actor continues its original attack unaffected. Defeat begins only after lethal attack recovery completes. During guard/dodge selection play the support tag once, then hold its final frame through impact; clear it after recovery. Idle and lantern loop by a paused presentation clock. Attack frames always come from original attack resources. Derive all frame selection from elapsed milliseconds and metadata, keeping AnimatedSprite2D stopped; no animation-finished signal resolves combat.

### Reproducible generation and import

Add `art_sources/moonlit_dojo/ASSET_SPEC.md`, `generate_moonlit_dojo.lua`, `verify_moonlit_dojo.lua`, and `verification.txt`. Generator accepts an output-directory script parameter, creates only these six new sources/exports through Aseprite APIs, and exports complete PNG+JSON data for all tags. Never invoke the old generators. Run from the new archive directory with `~/.local/bin/aseprite --batch --script generate_moonlit_dojo.lua` after checking the installed executable/version during implementation. If unavailable, report the asset stage blocked; do not substitute a prohibited tool.

The independent new verifier reopens the saved sources and exports in Aseprite, checks layers, dimensions, tag ranges, exact durations, palette and alpha rules, distinct animation poses, feet/canvas clipping, and flattened source-to-sheet RGBA equality. Fully transparent RGB differences may be normalized for comparison only, without modifying files. It also checks JSON rectangles/durations against saved Aseprite frames. It writes only the new archive verification report. Record Aseprite version and command there. GUI adjustments must be reflected in the generator before declaring reproducibility; generating into ignored `build/art-repro/` must reproduce decoded pixels, tags and timing, though editable file bytes can carry metadata differences.

Copy the six native PNG exports unchanged into `game/assets/sprites/moonlit_dojo/` using the same filenames. Add `game/tools/import_moonlit_assets.gd`, an editor/headless maintenance script, to read archived JSON and produce these six resources in `game/assets/frames/moonlit_dojo/`: `ninja_support_frames.tres`, `samurai_support_frames.tres`, `dojo_backdrops_frames.tres`, `dojo_props_frames.tres`, `combat_fx_frames.tres`, `dojo_icons_frames.tres`. It creates AtlasTextures, not pixels. JSON/source paths are maintenance-only and excluded from runtime. Commit generated resources during an authorized implementation commit so CI never needs Aseprite or archive-relative runtime loads.

Keep lossless import, no mipmaps, no alpha-border fix, no premultiply, no resizing, nearest filtering and repeat disabled. Atlas region is `(frame_index * cell_width, 0, cell_width, cell_height)`, `filter_clip=true`. Use 10 fps metadata base with SpriteFrames duration multiplier `duration_ms / 100.0`; derive stopped playback from cumulative durations. Static tags have one frame; loops only for idle/lantern. Preserve original `ninja_frames.tres` and `samurai_frames.tres` attacks unchanged.

Add `game/tests/moonlit_asset_manifest.json` and `moonlit_assets.sha256` for the new sources, exports, metadata, generator/verifier and runtime copies. Do not merge generated-art expectations into the immutable original manifest. Tests compare decoded imported RGBA against native runtime PNGs for all six new sheets, verify rectangles and duration mapping, and ensure only PNGs/resources enter the pack. Python may check file headers/checksums/JSON as data; it must not draw, export, rescale, or rewrite art.

## Architecture and data ownership

Retain `duel.tscn` as the main scene and reusable battle presentation. Refactor `duel.gd` into a thin coordinator owning one `RunModel` and one `CombatModel`, forwarding taps and projecting snapshots. No autoloads or global service framework. Only the coordinator advances combat time, including input-time synchronization to the current monotonic timestamp; never apply the same time interval in both input and `_process`. Unit tests can inject a deterministic clock. SceneTree is not globally paused: the coordinator gates model and presentation advancement.

Proposed scene tree (separate scenes are instantiated at the indicated nodes):

```text
Duel (Control; duel.gd; existing theme)
  Backdrop (ColorRect; neutral letterbox/background)
  Arena (instance scenes/arena.tscn; scripts/arena_view.gd)
    Environment (Sprite2D; backdrop atlas, 2x)
    Props (Node2D; two lantern sprites and one banner sprite)
    Ninja (instance scenes/fighter.tscn; fighter_view.gd)
      Visual (Node2D; 4x)
        Sprite (AnimatedSprite2D; stopped)
    Samurai (instance scenes/fighter.tscn; flipped sprite only)
    Effects (Node2D; scripts/effects_view.gd; pooled stopped sprites)
  HUD (instance scenes/hud.tscn; scripts/hud.gd)
    Header (title, encounter name, HP labels/icons, PauseButton)
    SealRoute (three icons plus progress label)
    Cue (icon, text, combo count)
    PhaseProgress (ProgressBar)
    Feedback (Label)
    TechniqueHint (Label)
    Actions (HBoxContainer; BlockButton, DodgeButton, StrikeButton)
    Footer (Label)
  Modal (instance scenes/run_modal.tscn; scripts/run_modal.gd)
    Scrim
    Panel/Content (Heading, Instructions, Stats, PrimaryButton,
                   ChoiceAButton, ChoiceBButton, SecondaryButton)
  BrowserLifecycle (existing browser_lifecycle.gd)
```

Add `game/scripts/layout_helper.gd` for baseline/compact layout selection from available viewport dimensions; no art creation. New view scripts update only changed text/resources, not every label's text every frame. Reuse fighters and resources across encounters; do not recreate the root scene on retry. All exposed buttons use existing `touch_action.gd`. Central cancellation covers every button, including hidden modal choices. Connect each signal once. Hide/disable underlying action buttons while modal visible because `_input` handlers bypass ordinary Control mouse filtering.

Data resources:

- `game/scripts/data/strike_spec.gd`: Resource with `defense_required` enum BLOCK/DODGE and positive `warning_ms:int`. Attack duration/impact remain fixed model constants 600/300.
- `game/scripts/data/pattern_spec.gd`: Resource with `id:StringName`, `strikes:Array[StrikeSpec]` (one or two).
- `game/scripts/data/encounter_spec.gd`: Resource with `id`, `display_name`, `enemy_max_hp:int`, `rest_ms:int`, `counter_ms:int`, `backdrop_tag`, `banner_tag`, `intro_text`, `patterns:Array[PatternSpec]` in cycle order.
- `game/data/encounters/gate_guard.tres`, `courtyard_retainer.tres`, `dojo_master.tres`: exact values from encounter table; embed pattern/strike subresources so no extra pattern files are necessary. Reference these explicitly with preload, never directory discovery.
- `game/scripts/run_model.gd`: RefCounted with run-state enum, encounter index 0..2, max/current HP, seals 0..3, `counter_bonus_ms`, chosen upgrade IDs, counters, `reward_claimed`, terminal-handoff latch. Methods `begin_run`, `begin_encounter`, `resolve_encounter`, `choose_reward`, `return_to_title`; invalid-state calls return false without mutation. Select offered rewards by completed encounter index; no randomized tables.
- `combat_model.gd`: configure from EncounterSpec, starting HP/max HP and counter bonus. Own combat HP during FIGHT, phase elapsed, pattern/strike index, `selected_defense` NONE/BLOCK/DODGE, `all_defended`, `impact_resolved`, `attack_blocked` replacement/compatibility field, plus an append-only-until-drained typed event queue. Keep RefCounted and deterministic boundary-consuming `step`.
- `game/scripts/combat_event.gd`: RefCounted event with enum kind, pattern/strike indices, defense requirement/selection, and resulting HP. Events describe accepted defense, defended impact, damage, counter impact, WON and LOST. Views consume them once; they never infer hits from string prefixes or apply HP changes.

RunModel stores HP between fights; CombatModel is authoritative while fighting. At terminal handoff copy its final HP and stats into RunModel exactly once. During FIGHT the HUD reads CombatModel HP; elsewhere it reads RunModel. Upgrade selection cannot mutate an active combat resource. Treat EncounterSpec instances as immutable; never store runtime indices or HP on shared Resources. `begin_encounter` always configures a fresh combat state even when reusing the object. Snapshot contains every value required by views, including active strike count, timings, available inputs, and current support pose; use typed fields or a small explicit Dictionary, not scene node references.

## File change inventory

Existing files to modify during implementation:

| Path | Planned change |
| --- | --- |
| `game/project.godot` | Game name only unless compact layout needs a documented display setting; retain all engine/render/input constraints |
| `game/scenes/duel.tscn` | Instantiate arena/HUD/modal components, preserve main scene path |
| `game/scripts/duel.gd` | Run orchestration, input-time synchronization, pause, terminal handoff, snapshots |
| `game/scripts/combat_model.gd` | Configurable encounters, multiple strikes, defense choice, typed events |
| `game/scripts/fighter_view.gd` | Existing scene-backed visual nodes, support poses, metadata timing, dodge; remove drawn guard arc in favor of authored feedback |
| `game/assets/ui/duel_theme.tres` | Night palette, readable disabled states, three-action and reward-card styles |
| `game/web/shell.html` | New accessible canvas label, retain relative loader and lifecycle callbacks/safe areas |
| `game/export_presets.cfg` | Explicit new scenes/model/data/resources in resource selection; exclude tools/tests/archive data |
| `game/tests/run_tests.gd` | Migrate hardcoded 3-HP/one-duel/node-path expectations and execute new suites |
| `game/tests/verify.sh` | New read-only asset checker, strict exact engine pin, new tests and retained exported-pack smoke |
| `game/tests/check_web_export.py` | Assert run model, data resources and all atlas dependencies present; tools/tests absent; report size budget |
| `.github/workflows/deploy-pages.yml` | Retain Godot 4.5.1 and Pages chain; add failed-test log artifact, keep deployment dependent on successful verification |
| `README.md`, `game/README.md` | New game/rules/architecture, authorship and exact commands |
| `CREDITS.md` | Add new Aseprite source provenance and tool version, preserve existing attribution/license wording |
| `qa/mobile/validation.md`, `qa/mobile/verification.txt` | Clearly dated expansion results and retained historical record; no invented coverage |

Existing `touch_action.gd` and `browser_lifecycle.gd` should remain unchanged unless integration tests expose a concrete cancellation defect; if changed, record the reason and rerun all their regressions. Existing UID sidecars retain identity; new GDScript files receive normal Godot-generated `.gd.uid` sidecars during implementation. Preserve original attack resources, archives, manifests, notices, ignore files and prior plan. Build outputs and `.godot` stay ignored.

New non-art files, in addition to paths specified above: `game/tests/test_run_model.gd`, `test_encounter_patterns.gd`, `test_run_scene.gd`, `test_moonlit_assets.gd`, and `check_moonlit_assets.py`. Each GDScript suite exposes an awaited runner called by `run_tests.gd`, using its shared assertion sink; no external test plugin. Add QA screenshots/traces under `qa/mobile/moonlit-dojo/`, with filenames specified below. Do not introduce alternate game entry points or unused legacy duel mode.

## Implementation order and test gates

1. **Baseline and preservation.** Read this plan and current status; record original hashes and exact engine/template/Aseprite versions. Run existing verification before changes during implementation. Preserve any intervening user changes. Reconfirm installed browser/device availability early. Do not install or upgrade engine/toolchain opportunistically.
2. **Pure mechanics.** Add typed spec/event/run models and three data resources; generalize combat. Implement tests for exact rules before connecting the view. Retain boundary traversal and immutable configuration. Gate: model suites pass, including every pattern, upgrade branch, and terminal edge.
3. **Aseprite asset pipeline.** Author six sources and generator, export native sheets/JSON, independently reopen/verify, create manifests, import SpriteFrames through maintenance script. Gate: original hashes unchanged, new source/export equality and metadata checks pass; inspect all new poses next to old attacks for transition continuity.
4. **Reusable presentation.** Extract fighter/arena/HUD/modal scenes, add support/effect views and three-button layout; wire RunModel to existing controller. Gate: full three-encounter run and both rewards work through headless scene touch events, wrong defenses lose HP, reset leaves no old effects or ownership.
5. **Lifecycle and layout.** Apply compact layout and pause to combo warnings, openings, terminal delay and all modals. Gate: old touch/stall/scale guarantees and new multi-button/modal tests pass; no duplicate signal connection across 20 complete run resets.
6. **Web proof.** Update export selection/checker and run full verification/export; load exported PCK, then serve and open actual web build under a nested path. Gate: all new dependencies present and executable without archives; no missing files/script loads, correct single-thread setting.
7. **Browser/device polish.** Perform QA matrix, capture evidence and performance numbers; tune only within stated timing/size defaults unless tests reveal a correctness failure. Record any balancing adjustment explicitly in data, docs and tests. Complete three clears and three losses per real device.
8. **Release preparation.** Update README/credits/QA, run relevant final gates and diff checks, prepare complete `build/web/` Pages artifact. The workflow remains build-then-deploy on authorized main pushes or dispatch. After authorized deployment, verify the actual HTTPS Pages URL including refresh and asset requests; report actual URL and workflow result. Never equate local export with live deployment.

Future commands from repository root (not executed in this planning turn):

```bash
~/.local/bin/godot --version
~/.local/bin/aseprite --version
python3 game/tests/check_source_assets.py
sha256sum -c game/tests/source_assets.sha256
# Author/export and verify from art_sources/moonlit_dojo/ using the new Lua scripts.
# The verification wrapper establishes repository-local XDG directories/templates.
game/tests/verify.sh
# After the wrapper has established build/local/, use these XDG values for maintenance:
XDG_DATA_HOME="$PWD/build/local/data" XDG_CACHE_HOME="$PWD/build/local/cache" XDG_CONFIG_HOME="$PWD/build/local/config" ~/.local/bin/godot --headless --path game --script res://tools/import_moonlit_assets.gd
python3 game/tests/check_moonlit_assets.py
sha256sum -c game/tests/moonlit_assets.sha256
game/tests/verify.sh
python3 -m http.server 8060 --bind 127.0.0.1 --directory build
# In another terminal: open http://127.0.0.1:8060/web/index.html
curl -fI http://127.0.0.1:8060/web/index.html
curl -fI http://127.0.0.1:8060/web/index.wasm
curl -fI http://127.0.0.1:8060/web/index.pck
git diff --check
git status --short
```

Order the first verification as a baseline, then import maintenance after sources exist, then final verification; do not repeatedly run exports while only editing model tests. The wrapper must keep read-only source checks, headless editor import, test runner, 120-frame scene smoke, release export to `build/web/index.html`, 120-frame exported-pack smoke, notices copy and bundle check. It must exit nonzero for failed assertions or script-load errors even when Godot exits zero. Keep Aseprite generation outside CI; CI validates checked-in runtime artifacts and metadata without authoring art.

### Required automated coverage

- Preserve meaningful current timing tests at 30/60/120 Hz, 299/300 ms impact, 599/600 ms recovery, invalid/NaN/nonpositive deltas, large steps and coarse/fine event equality. Update obsolete counts/health constants instead of deleting coverage or retaining a parallel legacy mode. Large deltas test model correctness; runtime stalls still pause.
- Test normal Block success, normal Dodge failure, heavy Dodge success, heavy Block failure, no defense, late defense, one irreversible choice per warning, and exactly one damage event. Last-millisecond accepted versus exact-deadline rejected for every warning/opening duration.
- Double-cut tests: both defended yields one opening; any miss denies it; fresh second defense required; first-hit lethal cancels second strike only after full first attack; second-hit lethal completes recovery; counter cannot interrupt or occur between hits.
- Master starts heavy and cycles heavy/single/double on every resolved pattern, including misses and expired openings; pause and repeated input cannot skip/repeat pattern advancement. All original attacks always select six frames at 100 ms boundaries.
- Run tests: 3/4/5 enemy HP, 5 initial player HP, health carry, exactly one seal per victory, no fourth encounter, all reward combinations, healing clamp, full-health disabled Mend, +300 ms only on counter windows, Iron Resolve max/current increase, repeat reward rejection and reset to initial values.
- Pause every new phase immediately before/after each impact; retain first-cut result when resuming cut two; clear selected defense only when replaying its unresolved warning; preserve counter entitlement after resolved defense. Freeze terminal delay, effects and intro/reward state; no automatic resume on visibility return.
- Scene touch tests at 1×/2×/3× transforms complete title, introductions, all three battles, both reward variants, clear/fail/retry and Return to title. Cover release outside, cancelled touch, disabled-to-enabled hold, second finger, rapid taps during reward/modal transitions, mouse activation without emulated duplicates, and 20 retries without orphan nodes/connections/effects.
- Asset tests cover exact six source specifications, palettes/alpha exceptions, metadata-to-SpriteFrames mapping, imported PNG RGBA equality, atlas clipping, enemy flip, common floor and stopped animations. Scene smoke cannot establish aesthetic quality.
- Export checks assert all three encounters and run/strike/pattern/event scripts survive compiled-script remapping, six new atlases and original attacks load, and `tests/`, `tools/`, JSON archives, `.aseprite`, GIF/previews and source code generators are absent. Preserve pack version/engine pin checks and HTML/Wasm/file-size checks.

## Browser/mobile QA and performance

Test the exported release over HTTP and HTTPS, not `file://` or the editor. Required matrix: Chromium responsive at 390×844 CSS/DPR 3 with touch; 360×800, 430×932, 360×740 and 390×700 available portrait areas; desktop mouse; physical iOS Safari and Android Chrome. Record exact device, OS, browser version, available CSS viewport and DPR. Test safe-area phones, expanded/collapsed browser bars, resize during press, page switch during both combo strikes, lock/unlock, landscape/portrait return, and storage disabled. Every focus return requires explicit Resume if combat was active.

Capture in `qa/mobile/moonlit-dojo/`: `390x844-title.png`, `390x844-gate-cut.png`, `390x844-double-cut-2.png`, `390x844-heavy-dodge.png`, `390x844-opening.png`, `390x844-technique.png`, `390x844-cleared.png`, `390x844-failed.png`, plus `ios-safari-portrait.png`, `android-chrome-portrait.png`, `compact-360x740.png` and console/network/performance observations in `validation.md` within that directory. Screenshots are QA capture only, never sources for new art. Report unavailable evidence as pending and the concrete environment error; do not call headless event tests browser/device acceptance.

Visual gates: no scrolling/clipped labels or sword cells; all actions ≥48×48 CSS px at required sizes; fighters and cues visible above thumbs; idle-to-attack continuity; stable soles and weapon contact; readable moonlit silhouettes; distinct CUT/HEAVY/double labels without color/audio; pose changes at expected impact; sealed route and current encounter unambiguous. Confirm no stale last-enemy art or reward text on retry.

Hosting gates: relative URLs under `/<repository>/`, cold load and refresh on actual Pages index, correct HTML/JS/Wasm/PCK MIME responses, no failed requests/console errors, ordinary operation with `crossOriginIsolated === false`, no SharedArrayBuffer requirement, no service worker/PWA, and readable WebGL-unavailable startup error. Upload complete export directory including template-generated worklets and notices. Do not promise host compression from local gzip numbers; measure transfer headers and bytes.

Performance budgets are proposed release gates, not measured claims: game PCK ≤1 MiB raw; added PNGs ≤256 KiB combined; sum of resident uncompressed atlas RGBA ≤1 MiB; no lights, shader postprocessing, particles, physics bodies or per-frame resource loads; ≤120 draw calls and ≤200 scene nodes during combat. Target median frame interval ≤17.5 ms and p95 ≤33.4 ms over a 60-second run on each named physical device, excluding initial load/backgrounding. At a stable 30 fps the rules and input still work. Any >250 ms active-frame stall pauses without unseen damage.

Record 20 restart cycles: node counts return to baseline and memory shows no monotonic growth (allow ≤10 MiB warmup-to-final fluctuation in the chosen browser measurement). Measure cold navigation to enabled Begin run on a named 10 Mbps/100 ms RTT network profile, target ≤15 seconds over three runs, and warm reload target ≤3 seconds. Record raw pack/total export size, actual network transfer, profiler draw calls and frame timing separately. Engine overhead may dominate; do not undertake custom engine stripping for this slice. If a target fails, identify whether gameplay, export, host or device is responsible and fix that layer or mark release coverage incomplete.

## Risks and resolution defaults

| Risk | Concrete response |
| --- | --- |
| New poses clash with old art | Match existing palettes, feet and silhouette; compare idle/attack transitions in Aseprite and exported browser; never alter original sheets |
| Three buttons encourage guessing or thumb crowding | Fixed 110×96 layout, named action cues, one choice per warning, generous ≥650 ms windows; no extra resource meter |
| Combo state/pause can grant duplicate openings or damage | Strike-local impact flag, pattern-wide defense flag, explicit pattern advancement and boundary tests |
| Simultaneous input and frame time desynchronize deadlines | One monotonic simulation authority; input-time synchronization shares last-tick state with process and has injectable-clock tests |
| Export selection misses new preload/data dependencies | Explicit resources, package inclusion assertions and load actual exported PCK before browser tests |
| Night palette hides navy fighter | Lighter muted floor/paper band behind actors, restrained props, device screenshots required |
| Reward tap leaks into next screen | Immediate state latch, cancel pointers, no automatic Fight, disabled held input never activates on enable |
| Aseprite unavailable or tool version differs | Check installed executable before asset stage; use local working API examples; stop that dependency with a clear report, never switch raster tools |
| Restricted environment blocks HTTP/browser or no phone exists | Continue independent model/art/export work; document pending QA honestly; do not mark release accepted until required device checks occur |
| Supplied art attribution lacks a license grant | Preserve credits' accurate provenance; do not invent a license or change ownership claims |

## Acceptance criteria

- A complete run contains exactly three configured encounters and two technique selections, with health carry, correct seals, a clear win, contextual loss, pause/resume and full retry; all completion paths require only touch.
- CUT, double CUT and HEAVY have genuinely distinct defense requirements/timing; the third encounter exercises all patterns. Every damage/terminal event resolves once, and all attacks retain six original 100 ms frames and 300 ms impact.
- Exactly six new layered Aseprite sources and their native PNG/JSON exports match this specification and have independent verification. All new pixel art was authored via Aseprite Sprite/Image APIs or GUI only; original 18 manifest entries remain byte-identical.
- One cohesive 390×844 portrait presentation uses new scenery/support poses/effects/icons, readable cues, a three-seal route and ≥48 CSS px controls across required viewports, with no scrolling or covered combat information.
- Automated model, run, asset, touch, lifecycle, import, scene and exported-pack checks pass without script errors. Original regression guarantees remain covered; do not use a historical count as the new success criterion.
- Godot remains pinned to 4.5.1 Standard/GDScript/Compatibility with single-threaded Web export. The complete artifact runs at a nested URL without cross-origin isolation and is ready for the existing GitHub Pages pipeline.
- Required responsive and real-device QA and performance gates have recorded evidence; pending/blocked checks remain explicitly incomplete. Public deployment is claimed only after an authorized workflow succeeds and its actual Pages URL is verified.
- READMEs, provenance and QA describe the shipped behavior and actual results. No additional design questions, extra content systems or alternative art pipelines are needed to execute this plan.
