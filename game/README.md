# Ninja vs Samurai — Block & Counter

A complete one-screen duel at a logical 390×844 portrait viewport. Tap **Start duel**, tap **Block** during “Incoming”, then tap **Strike** during “Open”. Three counters win; three missed blocks lose. **Pause** (Ⅱ), **Resume**, and **Play again** all accept touch; real mouse clicks work on desktop. Holding does not repeat. No keyboard, audio, movement, installation, or external game dependencies.

## Setup and run

Pinned engine: **Godot 4.5.1 Standard**, `4.5.1.stable.official.f62fdbde1`, installed at `~/.local/bin/godot`. Matching templates are installed under `~/.local/share/godot/export_templates/4.5.1.stable/`, including `web_nothreads_release.zip`. Use the Standard build, not .NET. Python 3 is used only for read-only metadata/checksum/bundle validation and optionally the HTTP server. No Python or external image tool creates or edits art.

Run all commands from `/home/cmuxao/repos/ninja-samurai-godot-game`:

```bash
cd /home/cmuxao/repos/ninja-samurai-godot-game
~/.local/bin/godot --version
game/tests/verify.sh
~/.local/bin/godot --path game
# Optional visual editor:
~/.local/bin/godot --path game --editor
```

The executable `verify.sh` creates ignored, repository-local XDG directories and links to the already-installed templates so restricted runs do not need to write into the home directory. To keep subsequent editor/runtime state inside this repository too, use:

```bash
export XDG_DATA_HOME="$PWD/build/local/data"
export XDG_CACHE_HOME="$PWD/build/local/cache"
export XDG_CONFIG_HOME="$PWD/build/local/config"
~/.local/bin/godot --path game
```

On another machine, install that exact editor and matching standard export templates, then run `GODOT_BIN=/absolute/path/to/godot GODOT_TEMPLATE_DIR=/absolute/path/to/export_templates game/tests/verify.sh`. `GODOT_TEMPLATE_DIR` is the parent of `4.5.1.stable`, not the version directory itself. No plugin installation or asset regeneration is required.

## Exact individual verification/export commands

After the repository-local XDG setup above (the wrapper creates the directories and template link):

```bash
~/.local/bin/godot --version
python3 game/tests/check_source_assets.py
sha256sum -c game/tests/source_assets.sha256
~/.local/bin/godot --headless --path game --editor --import
~/.local/bin/godot --headless --path game --script res://tests/run_tests.gd
~/.local/bin/godot --headless --path game --quit-after 120
mkdir -p build/web
~/.local/bin/godot --headless --path game --export-release Web ../build/web/index.html
~/.local/bin/godot --headless --path build/web --main-pack index.pck --quit-after 120
cp CREDITS.md THIRD_PARTY_NOTICES.txt build/web/
python3 game/tests/check_web_export.py
# This optional check needs access to the two original local repositories:
python3 game/tests/check_source_assets.py --originals
git diff --check
git status --short
```

The model runner exits nonzero on failure. The wrapper also checks logs because Godot can return zero after a script load error. Logs live under `build/`. Editor import/export may print socket-listener errors inside this managed workspace, which prohibits socket creation; tests and both runtime smoke checks are clean. Export completion and pack loading are checked independently.

## Serve the release

On a machine that permits listening on localhost:

```bash
python3 -m http.server 8060 --bind 127.0.0.1 --directory build/web
```

In a second terminal:

```bash
curl -fI http://127.0.0.1:8060/index.html
curl -fI http://127.0.0.1:8060/index.wasm
curl -fI http://127.0.0.1:8060/index.pck
```

Open `http://127.0.0.1:8060/` in a WebGL 2/WebAssembly browser. Do not use `file://`. To test a nested URL without copying files, serve `build/` instead of `build/web/` and visit `/web/index.html`.

Publish all files in `build/web/` together on an HTTPS static host, with `.wasm` served as `application/wasm`, `.pck` as `application/octet-stream`, and correct HTML/JS types. Enable gzip/Brotli on the host, preserve relative paths, and return 404 for missing assets. The export has threads, GDExtensions, PWA/service worker, and virtual keyboard disabled; it does not require cross-origin isolation headers. Standard templates emit unused audio worklet JS files even though this game has no audio. The complete output directory is the release artifact.

## Rules and implementation

| Phase | Time | Input / outcome |
| --- | --- | --- |
| Rest | 700 ms | Wait |
| Warning | 900 ms | One fresh Block latches guard |
| Samurai attack | 600 ms | Impact at 300 ms; a miss costs one of 3 HP |
| Counter opening | 1,200 ms | One fresh Strike; expiration costs no HP |
| Ninja attack | 600 ms | Impact at 300 ms removes one of 3 enemy HP |
| Win/loss | Until retry | Final attack always finishes all 600 ms |

`combat_model.gd` is a pure RefCounted state machine with a boundary-consuming `step(delta)`. It accepts input only inside half-open phase intervals and resolves each impact once. Large deltas are deterministic in model tests. `duel.gd` owns the model and projects its state into the single scene. Live frame gaps over 250 ms, measured with both engine delta and a monotonic clock, pause instead of consuming reaction windows.

Pause cancels held pointers and clears the guard latch. A warning or enemy attack paused before impact returns to a fresh warning. An already-resolved impact keeps its result and remaining recovery; a successful block still earns its opening. Counter windows restart; player attacks retain their time. Resume always requires a tap. The web bridge retains its JavaScript callback and handles blur, visibility changes, and landscape; landscape also shows a readable shell overlay. Physical-device lifecycle behavior remains unverified.

`touch_action.gd` handles native touch events and real mouse down/up directly, without emulation or a second built-in Button activation connection. Pointer ownership is shared across controls; release/cancel outside clears it. Disabled presses cannot become enabled actions while held. Modal and reset transitions clear ownership.

## Art and presentation

Only the two supplied native 192×32 sheets ship. Each SpriteFrames resource has six clipped AtlasTextures at `(i*32, 0, 32, 32)`, 10 fps, nonlooping. AnimatedSprite2D stays stopped; the model selects consecutive frames at 100 ms boundaries. Fighter scale is 4×, the shared floor is y=450, the sprite offset is `(-16,-30)`, and the samurai alone faces left. A 24-pixel lunge reaches contact at 300 ms. Guard arcs, tints, background, and UI use Godot primitives.

Project importer defaults make regeneration of ignored `.import` files safe: lossless, no mipmaps, no resizing, no alpha-border modifications. Fighter CanvasItems explicitly use nearest filtering with texture repeat disabled. Tests compare imported RGBA bytes against both original runtime PNGs, preserving the ninja's partial alpha. First and final attack poses stand in for rest/recovery; there is no invented idle/block/death artwork.

The existing `art_sources/` archive is preserved outside the Godot root, with `.gdignore`. [CREDITS.md](../CREDITS.md) identifies the sources. [asset_manifest.json](tests/asset_manifest.json) records every archived file plus the two runtime copies, with original absolute path, byte size, and SHA-256. Validation parses editable Aseprite frame durations, dimensions, depth, layer names, and the forward attack tag. It does not claim pixel equality between flattened Aseprite layers and PNG sheets; it establishes byte identity with the supplied files and exact PNG/imported-texture equality.

## Verification record

On 2026-09-10, the pinned editor version, headless import, **309 automated checks**, 120-frame scene smoke check, release Web export, and 120-frame exported-pack smoke check passed. Bundle checks confirm single-threaded settings, valid Wasm, configured sizes, presence of the combat model, and absence of tests/source archives in the 25-entry game pack.

A local HTTP server was actually attempted but failed with `PermissionError: [Errno 1] Operation not permitted` at socket creation. Installed Chromium was also attempted through Playwright and failed during launch with `sandbox_host_linux.cc:41 … Operation not permitted`. No HTTP responses, browser screenshots, WebGL behavior, or physical iOS/Android results are claimed. Detailed coverage, sizes, remaining checks, and exact file inventory are in [qa/mobile/validation.md](../qa/mobile/validation.md).

The approved plan is preserved unchanged. There were no commits, remote creation, or deployment in this implementation run. `.gitignore` excludes editor/import state, local dependencies, and generated builds; source scripts, UID sidecars, PNGs, resources, provenance, and documentation remain trackable.
