# Ninja vs Samurai: Block & Counter — implementation plan

## Goal and scope

Build a tiny, one-screen duel in Godot 4.x, playable from a static website in a mobile browser. At a 390×844 portrait viewport, the player taps **Block** during the samurai's warning, watches the attack, then taps **Strike** during the counter window. Three successful counters win; three missed blocks lose. Start and retry require only touch. A successful run should take roughly 10–15 seconds.

This document is the only deliverable of the planning turn. All project paths, implementation steps, tests, import operations, and export commands below are proposed future work. This turn does not create a Godot project, edit assets, run Aseprite scripts or Godot builds/exports, commit, deploy, or generate imagery.

Keep the implementation to one scene, two fighters, two buttons, three health points per fighter, and a retry overlay. No movement, physics collisions, levels, spawning, inventory, networking, persistence, sound, or additional character art. Build the background and interface with Godot primitives and its bundled font.

## Inspected evidence and assumptions

Inspected both repositories' `ASSET_SPEC.md`, `verification.txt`, generator and verifier Lua files, PNG headers, editable Aseprite binary headers/frame/layer/tag chunks, and the existing 4× sheet previews. The source files themselves confirm the metadata below. Existing verification reports were read; their verification scripts were **not rerun**.

| Property | Ninja player | Samurai enemy |
| --- | --- | --- |
| Source repository | `/home/cmuxao/projects/hermes_area/aseprite-ninja-attack` | `/home/cmuxao/projects/hermes_area/aseprite-samurai-attack` |
| Editable source | `ninja_attack.aseprite` (4,771 bytes) | `samurai_attack.aseprite` (3,880 bytes) |
| Runtime candidate | `ninja_attack_sheet.png` (2,154 bytes) | `samurai_attack_sheet.png` (2,204 bytes) |
| Native sheet | 192×32 transparent PNG; six horizontal cells | 192×32 transparent PNG; six horizontal cells |
| Source frames | Six 32×32 RGBA frames, each 100 ms | Six 32×32 RGBA frames, each 100 ms |
| Tag | `attack`, forward, Aseprite frames 1–6 | `attack`, forward, Aseprite frames 1–6 |
| Editable layers | `Scarf`, `Ninja`, `Steel blade`, `Slash accents` | `01 • Indigo armor & sash`, `02 • Arms & steel katana`, `03 • Cut accent` |
| Facing | Right; dark navy outfit and red scarf | Right; indigo armor, gold helmet crest, muted red sash |
| Other existing outputs | 32×32 animated GIF; 768×128 4× PNG preview | 32×32 animated GIF; 768×128 4× PNG preview |

Both drawings place their boot soles at native y=29. Use a shared ground anchor based on that pixel row, not the bounding box of each pose. Samurai attack frame 4 is the cutting strike; ninja frame 4 is full extension. Both animations last 600 ms. No separate idle, block, hurt, or death animation exists.

The ninja generator uses a partially transparent slash color (alpha 210); preserve intermediate alpha. Do not impose the samurai verifier's binary-alpha requirement on the ninja. The ninja verification report checks sheet dimensions but does not establish pixel-for-pixel sheet/source equality; the samurai report does. Future import validation should compare both sheets against flattened editable frames if that stronger guarantee is needed.

The samurai generator saves the editable source but does not itself export all the advertised PNG/GIF outputs; do not assume rerunning it is a complete rebuild pipeline. Both verifier scripts overwrite `verification.txt`, so they are not read-only checks in their original folders.

Assume the supplied art is authorized for this game; no license file was found among the inspected asset deliverables. Confirm redistribution rights before public release. Select a released Godot 4.5.x standard/GDScript editor as a concrete baseline and record its exact patch version with matching export templates during implementation. This is a version pinning proposal, not a claim that 4.5 is the newest release. Godot 4.3 introduced single-threaded web exports, so 4.0–4.2 are unsuitable for this configuration. [Godot web-export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html)

## Game rules and core loop

1. Show a start overlay: “Block the warning. Strike when the samurai opens up. Land 3 hits.” A large **Start duel** button initializes both health values to 3.
2. After 700 ms at rest, show **Incoming — tap Block** for 900 ms. Block registers once and remains latched through the next enemy attack; holding is unnecessary.
3. Play all six samurai attack frames for 600 ms. At 300 ms, on entry to zero-based frame 3, either display **Blocked!** or subtract one player health and display **Hit!**. The enemy cannot be interrupted.
4. After a successful block, show **Open — tap Strike** for up to 1,200 ms. One Strike begins the ninja's 600 ms attack. At its 300 ms point, remove exactly one samurai health. The enemy remains in its recovery pose during this action.
5. A missed block skips the counter window. A missed counter opportunity costs no health and returns to rest. Finish the current attack's six frames before showing a terminal overlay.
6. At enemy health 0, show **You win**; at player health 0, show **Try again**. **Play again** completely resets the duel without reloading the page.

Block and Strike are disabled outside their valid phases. Input is never buffered into a later phase, and holding a finger never repeats an action. A player can safely learn the pattern without penalties for tapping a disabled button. There is no score or hidden difficulty scaling. Waiting forever cannot win; ignoring Block causes defeat on the third enemy strike.

## Architecture and exact proposed paths

All following paths are relative to `/home/cmuxao/projects/hermes_area/aseprite-samurai-attack`. Put the Godot root at `game/`, so `res://` resolves there and the original asset workspace stays separate.

| Proposed path | Responsibility |
| --- | --- |
| `game/project.godot` | Main scene, Compatibility renderer, viewport, filtering, input settings |
| `game/export_presets.cfg` | One runnable preset named `Web`, single-threaded |
| `game/.gitignore` | Ignore `.godot/`; preserve Godot-generated source UID/import metadata as appropriate for the pinned version |
| `game/scenes/duel.tscn` | Only game scene; start, arena, controls, results, pause UI |
| `game/scripts/duel.gd` | Own model instance, advance time, project model state to UI/actors, route actions |
| `game/scripts/combat_model.gd` | Pure `RefCounted` state machine, health, phase time, impact events; no node or input dependencies |
| `game/scripts/fighter_view.gd` | Render a supplied pose/frame, facing, ground alignment, brief hit/block feedback |
| `game/scripts/touch_action.gd` | `Button` subclass with one fresh touch/mouse activation per press; robust pointer cancellation |
| `game/scripts/browser_lifecycle.gd` | Native focus and web visibility pause/resume integration; retain JavaScript callback references |
| `game/assets/sprites/ninja_attack_sheet.png` | Byte-identical copy of ninja native sheet |
| `game/assets/sprites/samurai_attack_sheet.png` | Byte-identical copy of samurai native sheet |
| `game/assets/frames/ninja_frames.tres` | SpriteFrames with six atlas regions and nonlooping `attack` |
| `game/assets/frames/samurai_frames.tres` | Equivalent samurai SpriteFrames |
| `game/assets/ui/duel_theme.tres` | Shared font sizes, button states, panels, colors |
| `game/web/shell.html` | Pinned-version HTML shell adapted for safe areas, resizing, loading/error states |
| `game/tests/run_tests.gd` | Dependency-free headless runner for combat, resources, reset, input, and scene wiring |
| `game/tests/check_source_assets.py` | Read-only standard-library PNG/Aseprite metadata and checksum checks |
| `game/tests/source_assets.sha256` | Expected checksums for the four original sheet/source files |
| `game/README.md` | Exact engine/template version, controls, development/export instructions, source provenance and QA record |
| `art_sources/.gdignore` | Exclude archived editable provenance if opened under a broader Godot root |
| `art_sources/ninja/ninja_attack.aseprite` | Unchanged editable source copy |
| `art_sources/ninja/ASSET_SPEC.md` | Source specification copy |
| `art_sources/ninja/generate_ninja.lua` | Generator copy |
| `art_sources/ninja/verify_ninja.lua` | Verifier copy |
| `art_sources/ninja/verification.txt` | Recorded report copy |
| `art_sources/samurai/samurai_attack.aseprite` | Unchanged editable source copy |
| `art_sources/samurai/ASSET_SPEC.md` | Source specification copy |
| `art_sources/samurai/generate_samurai.lua` | Generator copy |
| `art_sources/samurai/verify_samurai.lua` | Verifier copy |
| `art_sources/samurai/verification.txt` | Recorded report copy |
| `build/web/index.html` | Future generated browser entry point; sibling `.js`, `.wasm`, `.pck`, and any other exporter outputs travel together |
| `qa/mobile/` | Future screenshots and `validation.md` with browser/device versions and measured results |

Ignore `build/` in a future repository ignore update. No autoloads, plugins, custom engine compilation, C#, GDExtensions, or worker threads are needed. `duel.gd` is the sole state owner; the view never determines damage. The combat model exposes `reset()`, `start()`, `step(delta)`, `request_block()`, and `request_strike()`, with snapshots/events for rendering and tests.

## Asset import strategy

Copy the native sheets and archive the editable material once during implementation. Record original absolute paths and hashes in the README/manifest. Runtime loading must use only `res://` paths; never reference the sibling ninja repository. The archive lives outside the Godot root and is excluded from the shipped game. Do not import GIFs or the 4× previews.

Use lossless PNG import, mipmap generation off, no lossy or VRAM texture compression, texture repeat disabled, and nearest texture filtering on fighter CanvasItems. Preserve RGBA transparency and avoid trimming, padding, repacking, or resizing. Set each AtlasTexture region to `Rect2(i * 32, 0, 32, 32)` for `i=0..5`, with region filtering/clipping enabled to avoid neighboring-cell bleed. Create `attack` at 10 fps with all frame duration multipliers 1 and `loop=false`; source playback loops are intentionally overridden by the combat system.

Use `AnimatedSprite2D` with `centered=false`, local position `(-16,-30)`, and scale `(4,4)` on its parent visual pivot. Put both actor roots at the same floor y. Flip only the samurai sprite with `flip_h=true`; leave UI and effect labels unflipped. At rest/block, show frame 0 without playback; during the counter opening freeze the samurai at frame 5. Hurt feedback uses a short tint, and a drawn cyan guard outline indicates the block latch. Defeat uses a dimmed final pose behind the result panel. These are presentation substitutions, not newly authored animations.

The model's attack elapsed time controls the visible frame: `min(floor(elapsed / 0.1), 5)`. Keep sprite playback stopped so an independent animation clock cannot drift from hit timing. Normal visible playback still presents six consecutive frames for 100 ms each; under a rendering stall the display may skip frames, but damage must remain correct. Preserve the full 600 ms attack state even when its impact makes health reach zero.

Initial sheet SHA-256 values:

```text
e1e83137c2bf258988927a49d7228d499eb069409a5bd4687a23b474d1397820  ninja_attack_sheet.png
d7a458287e34a07c55eff0fb1ab88a7960e170f62b87343e0188fcf19ceba987  samurai_attack_sheet.png
81348aa9879e6ab99258f0600a6e9d3933c53f462102f481ec223cfc32c72b8f  ninja_attack.aseprite
c07cb27a6f49738328d6443643b818b159edfe0577cd34c91b7fd3b4de393414  samurai_attack.aseprite
```

No asset regeneration is needed for the first implementation. If edits are later explicitly requested, work on archive copies in a scratch directory, export a horizontal six-cell sheet with no trimming/scaling/padding through Aseprite, validate, and deliberately replace the runtime copy. Run existing verifier scripts only on scratch copies because they write reports. Preserve the original repositories' files.

## Scene and node layout

```text
Duel (Control, full rect; duel.gd)
├── Backdrop (ColorRect, full rect; mouse_filter=IGNORE)
├── Arena (Node2D)
│   ├── Ground (Line2D)
│   ├── Ninja (Node2D; fighter_view.gd)
│   │   ├── Visual (Node2D, scale 4)
│   │   │   └── Sprite (AnimatedSprite2D)
│   │   └── GuardOutline (Line2D)
│   └── Samurai (Node2D; fighter_view.gd)
│       └── Visual (Node2D, scale 4)
│           └── Sprite (AnimatedSprite2D, flip_h)
├── HUD (Control, full rect; noninteractive areas IGNORE)
│   ├── Header (HBoxContainer)
│   │   ├── PlayerHealth (Label)
│   │   ├── Title (Label)
│   │   └── EnemyHealth (Label)
│   ├── PauseButton (Button)
│   ├── Cue (Label)
│   ├── PhaseProgress (ProgressBar, no percentage text)
│   ├── Feedback (Label)
│   └── Actions (HBoxContainer)
│       ├── BlockButton (Button; touch_action.gd)
│       └── StrikeButton (Button; touch_action.gd)
├── Modal (Control, full rect; STOP when visible)
│   ├── Scrim (ColorRect)
│   └── Panel (PanelContainer)
│       └── Content (VBoxContainer)
│           ├── Heading (Label)
│           ├── Instructions (Label)
│           └── PrimaryButton (Button; Start / Resume / Play again)
└── BrowserLifecycle (Node; browser_lifecycle.gd)
```

Use a warm pale background around `#E5D4B2`, dark ink text around `#202438`, and a simple ground line. This gives the dark fighters readable silhouettes. No scrolling camera or scenery image is needed. At the nominal viewport, header spans x=20..370 and y=52..116; cue and timing bar sit around y=220..285. Fighter roots start at `(131,450)` and `(259,450)`, giving each a 128×128 canvas. During a strike, move the active fighter 24 logical pixels toward the opponent, reaching the offset at 300 ms and returning by 600 ms; round rendered positions to integers. This small lunge communicates contact without movement controls or collisions. Inspect sword/body overlap and tune the offset, retaining the common ground line.

Place feedback below the arena around y=495. Actions occupy x=20..370, y=656..752, with a 16 px gap and two 167×96 buttons. Pause is at least 48×48. Use 18–20 px body text and 24–28 px cue text; never encode phase or health only by color. Labels say `You 3/3` and `Samurai 3/3`. The bottom controls stay well above the home indicator.

## Input, sizing, and browser lifecycle

- Use logical viewport 390×844, `canvas_items` stretch, `keep` aspect, and fractional scaling. The entire encounter remains visible with letterboxing at other ratios. Nearest filtering and 4× logical art scale give crisp art at the target; fractional physical scaling on other devices can make pixel widths uneven. This is an accepted layout tradeoff. [Godot resolution and scaling reference](https://docs.godotengine.org/en/4.5/tutorials/rendering/multiple_resolutions.html)
- The shell uses `width=device-width, initial-scale=1, viewport-fit=cover`, a `100dvh` container with `100vh` fallback, and padding from `env(safe-area-inset-*)`. Base the canvas dimensions on the container's inner content rectangle via ResizeObserver, including browser toolbar changes. Set Canvas Resize Policy to None for this explicit shell sizing, preserving the engine's aspect handling. Do not independently multiply CSS dimensions by devicePixelRatio twice. Start from the exact pinned editor's default shell and retain its engine startup/config placeholders and resize conventions. [Web exporter settings](https://docs.godotengine.org/en/4.5/classes/class_editorexportplatformweb.html)
- Keep body margin zero, prevent document scrolling, and apply `touch-action:none` to the canvas. Do not disable zoom globally through the viewport meta tag. The game requires neither fullscreen nor orientation lock. In landscape, pause and show a shell-level “Turn your phone upright” message with readable CSS text; resume requires a tap after returning to portrait.
- Disable both `input_devices/pointing/emulate_mouse_from_touch` and `emulate_touch_from_mouse`. Handle native `InputEventScreenTouch`/drag on the action buttons explicitly; support real mouse clicks as the desktop alternative. Never also connect a second built-in button activation path for combat. Buttons render pressed/disabled feedback through the custom script.
- Accept an action only on a fresh down event inside its enabled rectangle. Track touch indices, ignore secondary pointers while a primary pointer is held, and release ownership on up/cancel even outside the button. Touches beginning on disabled controls must not activate when those controls later enable. Clear pointer ownership on modal transitions, reset, loss of focus, and orientation changes. Start/Retry/Resume can use the same touch adapter, with all underlying combat buttons blocked by the modal.
- No keyboard shortcuts, hover instructions, gestures, long presses, or simultaneous button holds are required. No text input means no virtual keyboard.
- Pause simulation on focus loss or `document.visibilitychange`, cancel held touches, and show a Resume overlay on return. Retain the prior phase and elapsed time but discard any latched block and restart an interrupted enemy warning/attack at a fresh 900 ms warning if impact has not occurred. If impact already occurred, resume its remaining recovery without dealing damage again. Counter windows restart with their full duration; player attacks resume unchanged. This gives the player time to reorient without undoing health changes.
- Use a separate paused flag and stop calling the model's `step`; keep the UI processing. For unexpected visible frame gaps over 250 ms, enter this same pause path instead of fast-forwarding through several reaction windows. Document that background/resume cannot inflict unseen damage. The browser bridge is conditional on the web feature tag and has a native focus fallback.

## Combat and state logic

| State | Duration and valid input | Exit |
| --- | --- | --- |
| `READY` | Indefinite; Start only | Reset all fields, then `REST` |
| `REST` | 0.700 s; neither combat action | Clear block latch, enter `TELEGRAPH` |
| `TELEGRAPH` | 0.900 s; one Block | Enter `ENEMY_ATTACK`, carrying latch |
| `ENEMY_ATTACK` | 0.600 s; no combat input | Resolve impact once at 0.300 s; at end choose `LOST`, `COUNTER_WINDOW` if blocked, otherwise `REST` |
| `COUNTER_WINDOW` | Up to 1.200 s; one Strike | Strike enters `PLAYER_ATTACK`; expiration enters `REST` |
| `PLAYER_ATTACK` | 0.600 s; no combat input | One damage at 0.300 s; at end choose `WON` or `REST` |
| `WON` / `LOST` | Indefinite; Play again only | Full reset, then `REST` |

Store `state`, `elapsed`, `player_hp`, `enemy_hp`, `block_latched`, and `impact_resolved`. On each new attack reset only its impact flag; on each new warning reset the block latch. Health is clamped to 0..3. Entry/exit helpers own state transitions and cue changes. Reset also clears pending events, view tints, lunge offsets, pointer state, and pause state.

Advance phase time with a boundary-aware loop consuming delta up to the next impact or state-end boundary. Resolve impacts when a step crosses 0.300 s, not by checking frame equality. Each impact flag is set before emitting its event. Tests can pass a large delta to the pure model to verify every boundary; the live controller separately pauses for large visible gaps. Define valid input intervals as half-open: warning accepts Block only while elapsed `<0.900`, counter accepts Strike only while elapsed `<1.200`. Once the model has advanced to the boundary, late input is ignored. Keep all model mutations on the main thread; event order decides input arriving in the same rendered tick, with no retroactive timing correction.

There can be no simultaneous lethal trade because attacks occupy separate states. Terminal state freezes the encounter after its attack completes, disables combat controls, and emits one result event. Presentation reads the last attack pose when health reaches zero, then shows the overlay at 600 ms. Avoid Timer callbacks, animation-finished damage handlers, or awaited coroutines that could survive a retry.

## Browser export and static hosting

Use GDScript and the Compatibility renderer (`rendering/renderer/rendering_method="gl_compatibility"`, also its mobile override). Godot's web target requires WebAssembly and WebGL 2; Forward+ and the renderer named Mobile are unsuitable. Single-threading improves compatibility but does not guarantee every Safari/device combination or native-app performance. [Godot web platform constraints](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html)

Proposed `Web` preset: `variant/thread_support=false`, `variant/extensions_support=false`, `progressive_web_app/enabled=false`, `html/canvas_resize_policy=0` (None), `html/custom_html_shell="res://web/shell.html"`, and virtual keyboard disabled. Use ordinary matching release templates; keep physics on the main thread, avoid Thread/WorkerThreadPool calls, and leave texture VRAM compression unused. Export selected main-scene dependencies and exclude tests, README, and shell source from the game pack; the exporter still reads the shell to produce HTML. [Web export property reference](https://docs.godotengine.org/en/4.5/classes/class_editorexportplatformweb.html)

Serve the whole export directory unchanged over HTTPS in production; localhost HTTP suffices for local checks. Do not open `index.html` via `file://`. Serve `.wasm` as `application/wasm`, `.pck` as `application/octet-stream`, and JS/HTML with their proper types. Enable gzip/Brotli with correct Content-Encoding and deploy the full bundle atomically. This configuration does not require SharedArrayBuffer or COOP/COEP isolation headers. [Godot serving guidance](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html#serving-the-files)

Use relative asset URLs so `/games/ninja-duel/` works. Never rewrite missing `.wasm`/`.pck` requests to HTML. Prefer short/revalidated caching for the entry page and same-named bundle files, or a versioned deployment directory. Do not add a service worker/PWA cache in this small release. Upload all exporter outputs rather than hard-coding an assumed file count. Host choice remains open; any HTTPS static host meeting these requirements is sufficient. Deployment needs separate authorization in the later implementation session.

Keep the stock loading progress and readable startup failure text in the custom shell. If WebGL 2 or WebAssembly is unavailable, report that the browser cannot run this game and suggest another supported browser/device. Do not promise a WebGL 1 or canvas fallback. Audio is out of scope, removing autoplay and web audio timing concerns. Engine download size will dominate the two tiny sheets; measure cold loading and record actual compressed size before setting a performance promise.

## Bite-sized implementation sequence

1. **Record the baseline.** Inspect current instructions and status; inventory original files and hashes without assuming untracked assets are disposable. Record an available released Godot 4.5.x patch and its matching templates. Establish the proposed directory layout.
2. **Bring in the supplied art.** Copy sheets and editable provenance into the specified destinations, validate hashes/dimensions/timing/layers, and configure the two SpriteFrames resources. Do not run the original generators.
3. **Prove the browser path early.** Create the minimal main scene, project settings, Web preset, and shell. Export/serve a scene with both sheets visible using the future commands below. Check an actual iPhone and Android browser can load it before adding combat.
4. **Implement the model.** Add the phase enum, exact timing, latch, impact, terminal and reset rules. Run the meaningful deterministic model tests before binding UI.
5. **Build the screen.** Add the two ground-aligned fighters, header, cue/bar, actions and modal. Apply the exact atlas regions, horizontal flip and nearest filtering; inspect all six poses.
6. **Connect touch and presentation.** Route fresh taps, synchronize model time and frames, add lunge/tint/guard feedback, and bind health/results. Validate hold, cancellation and rapid retry.
7. **Add lifecycle handling.** Wire visibility/focus/orientation pause behavior, safe-area sizing and toolbar resize. Test returning during each combat phase.
8. **Validate the complete export.** Run automated checks, export release, serve locally, then review an authorized HTTPS staging URL on the device matrix. Capture QA evidence and actual loading/performance results. Fix failures and rerun only affected checks.
9. **Handoff.** Update README with pinned versions, exact commands, proven browser/device coverage, known limitations and evidence paths. Confirm original assets remain byte-identical. Do not silently publish or commit as part of implementation.

## Tests and validation commands — future execution only

The planning turn has not run any of these commands. After implementation, run from the current repository root; use the actual pinned executable in place of `godot` if needed. Scripts listed below must first be implemented at their proposed paths. Python validation must read files without writing reports or importing local modules that create bytecode.

```bash
godot --version
python3 game/tests/check_source_assets.py
godot --headless --path game --editor --import
godot --headless --path game --script res://tests/run_tests.gd
godot --headless --path game --quit-after 120
mkdir -p build/web
godot --headless --path game --export-release Web ../build/web/index.html
python3 -m http.server 8060 --bind 127.0.0.1 --directory build/web
```

The server command is long-running; run the following from another terminal. Preview `http://127.0.0.1:8060/`. Real mobile HTTPS testing uses an authorized staging host; localhost on a phone is not the development machine.

```bash
curl -fI http://127.0.0.1:8060/index.html
curl -fI http://127.0.0.1:8060/index.wasm
curl -fI http://127.0.0.1:8060/index.pck
cmp ../aseprite-ninja-attack/ninja_attack_sheet.png game/assets/sprites/ninja_attack_sheet.png
cmp samurai_attack_sheet.png game/assets/sprites/samurai_attack_sheet.png
cmp ../aseprite-ninja-attack/ninja_attack.aseprite art_sources/ninja/ninja_attack.aseprite
cmp samurai_attack.aseprite art_sources/samurai/samurai_attack.aseprite
git diff --check
git status --short
```

`run_tests.gd` should exit nonzero on failure and cover these behaviors without external test plugins:

- Correct initial health, READY/REST flow, and phase durations at 30/60/120 Hz equivalent deltas.
- Block before the warning deadline prevents damage; no Block and a Block after the deadline each lose exactly one health.
- Impact is absent at 299 ms and present once at 300 ms; large steps crossing impact/end never repeat damage.
- Strike before opening, after expiration, or while already attacking is ignored; one valid Strike causes one enemy damage.
- Three valid block/counter cycles win after the final animation completes; three missed blocks lose after the enemy animation completes.
- Missing a counter simply starts another cycle. Holding or repeated input does not queue later actions. No health underflow.
- Retry restores every model/view/input field; run 20 retries to detect duplicate connections/events.
- Synthetic touch events: disabled-to-enabled while held, release outside, cancellation, second finger, and real mouse path do not duplicate activation.
- Pause/resume immediately before and after impact follows the stated rules without extra or unseen damage. Terminal states reject time/input.
- Atlas region boundaries, six frames, 10 fps metadata, nonlooping resources, sheet hashes and source metadata match the plan. Do not apply binary-alpha assertions to the ninja.
- Instantiate `duel.tscn` headlessly to verify referenced nodes/resources and modal/button state. A headless scene check cannot validate WebGL or visual fidelity.

Browser validation must additionally check a successful cold start, no console errors or missing requests, nonisolated single-threaded operation (`crossOriginIsolated` may be false), nested-path hosting, refresh/retry, disabled storage, and readable failure UI with WebGL unavailable. Test actual exported builds; a desktop editor run alone is insufficient.

## Mobile visual QA

Use responsive emulation at **390×844 CSS pixels** first, including touch and DPR 3, then real iOS Safari and Android Chrome. Record OS/browser/device versions and distinguish emulated results from device results. Also check 360×800 and 430×932 portrait, a shorter viewport with browser bars visible, and landscape pause/return. If a physical device is unavailable, record that coverage as pending rather than passed.

Capture `qa/mobile/390x844-start.png`, `390x844-warning.png`, `390x844-block.png`, `390x844-counter.png`, `390x844-win.png`, and `390x844-loss.png`, plus real-device screenshots and observations in `qa/mobile/validation.md`.

Verify the following visually and by touch:

- Full interface fits without scrolling; safe areas and browser chrome cover no text or controls. Buttons remain at least 48×48 CSS px on the tested portrait sizes.
- Fighter silhouettes contrast with the background; samurai faces the ninja; every pose has correct cropping and a stable floor anchor. The slash retains transparency with no sheet-neighbor pixels or filtering blur.
- Warning, blocked state, counter opportunity and disabled controls are readable without sound or color alone. Both health labels and the entire result overlay fit.
- Touch feedback is immediate; fingers on the lower buttons do not hide the fighters/cue. Pointer release, page switching, rotation and toolbar changes cause no stuck input.
- Sprite motion/impact feels aligned at normal frame rates. No damage repeats under CPU throttling. Large stalls pause rather than consume the reaction window invisibly.
- Complete three wins and three losses per real device, including retry, focus loss during attack, and multi-touch attempts. Aim for steady 60 fps on the recorded devices; record any dips and verify gameplay at 30 fps. Report cold transfer size and time-to-Start under a named network profile rather than inventing a download target.

## Risks and tradeoffs

| Risk/tradeoff | Response |
| --- | --- |
| Only attack artwork exists | Reuse first/recovery frames and simple drawn feedback; do not imply dedicated defensive or death art |
| Counter loop is easy and can be beaten by repeated fresh taps | Accept for this super-simple prototype; generous windows and disabled invalid actions prioritize touch usability over depth |
| Frame sheets contain no timing metadata | Keep 100 ms/frame explicitly in resources/model and test against editable sources |
| Sprite weapons may look short at contact | Start with the specified 24 px lunge and visually tune actor spacing; damage stays rule-based |
| Fractional viewport scaling produces uneven pixel widths | Prioritize fitting the mobile screen; preserve nearest filtering and validate the target viewport, without promising pixel-perfect scaling on every DPR |
| Single-threaded WebGL still has browser/driver limitations | Test real Safari/Chrome exports early; retain readable startup errors and avoid heavy rendering |
| Godot runtime outweighs the art payload | Use standard templates first and host compression; custom engine stripping is outside this scope |
| Background throttling and touch duplication | Central time authority, pause/resume rules, explicit pointer ownership and tests |
| Existing originals and reports are untracked in this repository | Preserve files and compare hashes; do not clean, regenerate, or commit them implicitly |
| Export keys/templates vary by release | Pin editor/templates together and verify options against that version's official documentation |
| Redistribution rights are not documented | Confirm before public release; keep provenance with editable sources |

## Acceptance criteria

- One playable portrait encounter uses the supplied ninja and samurai native sheets, with the enemy flipped to face the player; all six 100 ms attack frames are used in order.
- At 390×844, Start, Block, Strike, pause/resume, victory/defeat, and retry work with touch alone; nothing requires a keyboard, hover, fullscreen, sound, or installation.
- Health, timing, input windows, one-hit resolution, three-hit win/lose conditions and reset behavior match the specified model and pass automated checks.
- Controls are large and readable, the screen does not scroll, safe areas are respected, and both action animations remain visible above the controls.
- A single-threaded Compatibility/GDScript release export loads through an ordinary static server without cross-origin isolation requirements, including a nested URL path.
- Real-device iOS Safari and Android Chrome results are recorded; unsupported or untested devices are not represented as verified. Browser console/network checks and visual QA have no unresolved release-blocking errors.
- Runtime files do not depend on sibling repositories or editable Aseprite sources. Both original source repositories retain byte-identical assets, specs, scripts, and recorded verification reports.
- No scope expansion is needed: one scene, two actors, two combat actions, one result/retry flow, and no additional generated artwork.

For this planning turn specifically: only `.hermes/plans/2026-09-10_192352-ninja-samurai-godot-mobile-game.md` is created. Implementation and runtime validation remain future work.
