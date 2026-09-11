# Expansion update — 2026-09-11

Moonlit Dojo: Three Seals is implemented and locally verified: 3,179 automated checks, six independently audited Aseprite sets, HTML5 export and exported-pack three-encounter clear pass. Browser/device acceptance remains blocked. See the [expansion record](moonlit-dojo/validation.md), [exact file inventory](moonlit-dojo/files-changed.txt), and [actual output](moonlit-dojo/verification.txt). The historical record below is retained unchanged.

---

# Implementation validation — 2026-09-10

Implemented locally in `/home/cmuxao/repos/ninja-samurai-godot-game` using Godot **4.5.1 Standard**, `4.5.1.stable.official.f62fdbde1`, with matching `4.5.1.stable/web_nothreads_release.zip` templates. Renderer: Compatibility. Export: single-threaded GDScript, no extensions/PWA/virtual keyboard.

## Executed results

| Check | Result |
| --- | --- |
| `~/.local/bin/godot --version` | Exact pinned version above; exit 0 |
| `python3 game/tests/check_source_assets.py --originals` | 18 manifest entries match; archive and runtime copies byte-identical to original paths |
| `sha256sum -c game/tests/source_assets.sha256` | All 18 entries OK |
| `godot --headless --path game --editor --import` | Completed; exit 0; environment-only editor socket-listener errors described below |
| `godot --headless --path game --script res://tests/run_tests.gd` | **309 checks, 0 failures**; exit 0 |
| `godot --headless --path game --quit-after 120` | Clean scene/runtime smoke; exit 0 |
| `godot --headless --path game --export-release Web ../build/web/index.html` | Release generated; exit 0; same editor socket-listener limitation |
| `godot --headless --path build/web --main-pack index.pck --quit-after 120` | Clean exported-pack smoke; exit 0 |
| `python3 game/tests/check_web_export.py` | Correct settings, Wasm signature, configured file sizes, 25 PCK entries, model included, tests/archives excluded |
| `git diff --check` | Passed; files are uncommitted/untracked |
| Approved plan checksum | Still `22a18badb26b0c59a9db0916f6155af9a256d9e6800f0df99d25fb1852fbb412` |

Exact executable commands, repository-local XDG settings, and serving instructions are in [game/README.md](../../game/README.md). `game/tests/verify.sh` reproduces the required engine checks plus exported-pack verification. [verification.txt](verification.txt) preserves the final command output; ignored intermediate logs remain in `build/`.

The tests cover 30/60/120 Hz equivalent timing, 299/300 ms impacts, early/late/repeated inputs, coarse/fine deterministic event order, lethal attack completion, missed counters, pause before/after each impact, 20 retries, native touch/mouse ownership and cancellation, RGBA import equality, atlas regions, scene wiring, a real 260 ms stall, and native touch events sent through the actual scene at 1×, 2×, and 3× viewport scales. The scaled scene tests complete Start/Block/Strike/win/retry/Pause/Resume/loss. These are headless event/scene checks, not browser or pixel-layout screenshots.

An initial scene-only export omitted a preload-only script dependency. Loading the exported PCK detected the missing `combat_model.gd`; the final preset explicitly selects the scene and combat model as resources. The final PCK loads cleanly, and the bundle checker guards this dependency.

## Environment limitations and browser coverage

Godot initially tried to write editor/user caches under the home directory. The final wrapper redirects XDG data/cache/config paths into ignored `build/local/`, resolving those filesystem errors. Import/export still attempt an editor TCP listener and report `ERR_CANT_CREATE` at `net_socket_unix.cpp` / `tcp_server.cpp` because this workspace prohibits socket creation. The model runner and project/pack runtime smoke checks have no such errors.

The HTTP command was actually run:

```bash
python3 -m http.server 8060 --bind 127.0.0.1 --directory build/web
```

It failed at socket creation with `PermissionError: [Errno 1] Operation not permitted`. Therefore there was no server from which to obtain `index.html`, `.wasm`, or `.pck` HTTP responses; `curl` responses and MIME serving are **not verified**.

Installed Playwright and Chromium headless shell were also tried. Chromium exited at `content/browser/sandbox_host_linux.cc:41` with `Operation not permitted` before creating a page. No browser version, WebGL rendering, console/network trace, timing trace, responsive screenshot, or real device result was obtained. These failures were not treated as successful browser checks.

| Browser/device check | Coverage |
| --- | --- |
| 390×844, touch, DPR 3 responsive Chromium | Pending: browser launch blocked |
| 360×800, 430×932, shorter browser-toolbar viewport | Pending |
| iPhone / iOS Safari | Pending: no physical device available |
| Android / Chrome | Pending: no physical device available |
| Three wins and three losses per real device | Pending |
| Safe areas, sword overlap, stable floor, all six poses, readability | Implemented; visual confirmation pending |
| Visibility/focus/rotation and touch cancellation in real browser | Implemented; browser confirmation pending |
| Nested-path hosting, missing-file 404s, nonisolated browser load | Relative shell paths/preset checked; HTTP/browser confirmation pending |
| Storage disabled, WebGL-unavailable startup error UI | Implemented stock startup/failure path; browser confirmation pending |
| Cold start, console errors, network errors, CPU throttle, FPS | Pending |

No requested screenshots are present because rendering was not available. Do not interpret the headless results as physical-device or visual acceptance. On a permitted machine, serve the unchanged export, complete the browser/device matrix in the preserved plan, and save the six 390×844 screenshots here.

## Artifact sizes

Final export includes seven engine/game files plus `CREDITS.md` and `THIRD_PARTY_NOTICES.txt`:

| Artifact | Raw bytes | gzip level 9 bytes |
| --- | ---: | ---: |
| `index.html` | 7,264 | 2,778 |
| `index.js` | 305,185 | 77,052 |
| `index.wasm` | 38,034,280 | 9,237,412 |
| `index.pck` | 28,748 | 18,036 |
| `index.png` | 21,443 | 19,328 |
| `index.audio.worklet.js` | 7,298 | 2,194 |
| `index.audio.position.worklet.js` | 2,973 | 1,161 |
| `CREDITS.md` | 1,815 | 915 |
| `THIRD_PARTY_NOTICES.txt` | 107,348 | 28,655 |
| **Total** | **38,516,354** | **9,387,531** |

Compression was measured locally in memory; compressed files are not generated. This is not a measured HTTP transfer or time-to-Start. The supplied templates emit unused worklets; the game has no audio content. The PCK contains runtime dependencies only.

## Exact file inventory

New implementation/documentation files (paths relative to repository root):

```text
.gitignore
README.md
CREDITS.md
THIRD_PARTY_NOTICES.txt
art_sources/.gdignore
game/.gitignore
game/README.md
game/project.godot
game/export_presets.cfg
game/scenes/duel.tscn
game/scripts/duel.gd
game/scripts/duel.gd.uid
game/scripts/combat_model.gd
game/scripts/combat_model.gd.uid
game/scripts/fighter_view.gd
game/scripts/fighter_view.gd.uid
game/scripts/touch_action.gd
game/scripts/touch_action.gd.uid
game/scripts/browser_lifecycle.gd
game/scripts/browser_lifecycle.gd.uid
game/assets/sprites/ninja_attack_sheet.png
game/assets/sprites/samurai_attack_sheet.png
game/assets/frames/ninja_frames.tres
game/assets/frames/samurai_frames.tres
game/assets/ui/duel_theme.tres
game/tests/run_tests.gd
game/tests/run_tests.gd.uid
game/tests/check_source_assets.py
game/tests/check_web_export.py
game/tests/asset_manifest.json
game/tests/source_assets.sha256
game/tests/verify.sh
game/web/shell.html
qa/mobile/validation.md
qa/mobile/verification.txt
```

Preserved pre-existing provenance files:

```text
art_sources/ninja/ASSET_SPEC.md
art_sources/ninja/generate_ninja.lua
art_sources/ninja/verify_ninja.lua
art_sources/ninja/verification.txt
art_sources/ninja/ninja_attack.aseprite
art_sources/ninja/ninja_attack_sheet.png
art_sources/ninja/ninja_attack_sheet_4x.png
art_sources/ninja/ninja_attack.gif
art_sources/samurai/ASSET_SPEC.md
art_sources/samurai/generate_samurai.lua
art_sources/samurai/verify_samurai.lua
art_sources/samurai/verification.txt
art_sources/samurai/samurai_attack.aseprite
art_sources/samurai/samurai_attack_sheet.png
art_sources/samurai/samurai_attack_sheet_4x.png
art_sources/samurai/samurai_attack.gif
.hermes/plans/2026-09-10_192352-ninja-samurai-godot-mobile-game.md
```

Generated release files are `build/web/` plus the nine filenames in the artifact table. Generated editor/import state is ignored; `.gd.uid` source identifiers remain trackable. No original repository file was written, no generator/verifier Lua script was run, and no commit, remote, or deployment was created.

Implementation agent: Codex, identified by the session instructions as GPT-6. An exact backend model ID and effective reasoning-effort value are not exposed in this session; no local configuration entry established them. No agent delegation or image generation was used.
