# Moonlit Dojo expansion validation — 2026-09-11

Historical reactive-combat record. The current elemental revision and its local-only checks are documented in [elemental validation](../elemental/validation.md).

Local implementation and verification are complete. Browser/device release acceptance remains incomplete because this managed environment blocks socket creation and Chromium launch, and no physical iOS/Android device is available to this session. The deployment follow-up below records the later authorized commit, push, workflow, and live HTTPS validation.

## Actual tools and results

Godot: `4.5.1.stable.official.f62fdbde1` Standard, Compatibility, GDScript. Matching `web_nothreads_release.zip` SHA-256: `7f6c5efc9952f6f02509adfb92298161c0152a1f6a81c0bf9b9f4f913676e9c8`. Aseprite: `1.3.18.3-dev`. No toolchain was installed or upgraded. No subagents or image-generation tools were used. The runtime backend model/effort cannot be independently established from workspace files.

Commands ran from `/home/cmuxao/repos/ninja-samurai-godot-game`, with `XDG_DATA_HOME=$PWD/build/local/data`, `XDG_CACHE_HOME=$PWD/build/local/cache`, and `XDG_CONFIG_HOME=$PWD/build/local/config` where required. See [verification.txt](verification.txt) for final wrapper output and [environment-attempts.txt](environment-attempts.txt) for actual failed HTTP/browser attempts.

| Command | Actual result |
| --- | --- |
| `git status --short`, `git diff --stat`, source/plan reads | Resumed existing changes; retained deterministic models and the partial Aseprite generator |
| Initial `game/tests/verify.sh` | Original 18 hashes passed; old integration suite had 309 checks / 53 failures due to obsolete one-duel assumptions; no baseline success claimed |
| `~/.local/bin/godot --headless --path game --script res://tests/model_gate.gd` | 538 checks, 0 failures, retaining the previous mechanics gate |
| `~/.local/bin/aseprite --batch --script-param out="$PWD/art_sources/moonlit_dojo" --script art_sources/moonlit_dojo/generate_moonlit_dojo.lua` | Exit 0 after fixing version reporting; exactly six layered sources / PNG / JSON sets, 51 frames |
| Same Aseprite command with `verify_moonlit_dojo.lua` | Exit 0; 392,489 independent assertions; layers, canvas, tag ranges, durations, allowed pixels, alpha, distinct frames, soles, flattened source/sheet RGBA and JSON equality |
| Both Aseprite commands with `out="$PWD/build/art-repro"` | Exit 0; independent verification repeated; read-only checker confirms reproduced decoded PNGs and timing/tag metadata match canonical exports |
| `godot --headless --path game --script res://tools/import_moonlit_assets.gd` | Exit 0; six checked-in metadata-driven SpriteFrames resources |
| `python3 game/tests/check_source_assets.py`; `sha256sum -c game/tests/source_assets.sha256` | Exit 0; all 18 original entries unchanged |
| `python3 game/tests/check_moonlit_assets.py`; `sha256sum -c game/tests/moonlit_assets.sha256` | Exit 0; six exact specifications, native/runtime equality, 51 distinct frames, 34 new hashes and budgets |
| Final `game/tests/verify.sh` | Exit 0; exact engine pin, both asset checks, headless editor import, **3,179 checks / 0 failures**, 120-frame scene smoke, release Web export, 120-frame exported-pack smoke, complete exported-pack three-encounter clear, notices copy, pack/bundle checker |
| `git diff --check` | Exit 0; no whitespace errors |

## Deployment follow-up

The user-authorized release was committed as `6889955 feat: expand duel into moonlit dojo three seals` and pushed to `PlainMean/ninja-samurai-godot-game` on `main`. GitHub Actions run [34573481618](https://github.com/PlainMean/ninja-samurai-godot-game/actions/runs/34573481618) completed successfully: the `Test and export Web` job passed in 6m1s and `Deploy to GitHub Pages` passed in 9s. Pages is configured with `build_type=workflow` and HTTPS enforcement enabled.

Live URL: https://plainmean.github.io/ninja-samurai-godot-game/

Read-back checks on 2026-09-11 returned HTTP 200 for `index.html` (`text/html`, 7,264 bytes), `index.js` (`application/javascript`, 305,185 bytes), `index.wasm` (`application/wasm`, 38,034,280 bytes), and `index.pck` (`application/octet-stream`, 84,784 bytes). The served HTML contains the title `Moonlit Dojo: Three Seals`, the portrait viewport, and the accessible canvas label. These checks prove Pages is serving the new exported artifact; in-browser interaction/device acceptance remains pending as documented below.

The full runner retains original mechanics/asset/input coverage while replacing obsolete 3-player-HP and one-duel expectations with five HP, explicit run introductions and typed events. New suites cover all warning/opening boundaries, heavy and double-cut rules, all reward branches, pause on each side of impacts, coarse/fine determinism, complete clears at 1×/2×/3× with both reward choices, 20 loss/retry cycles per flow, stable node/connection counts, stopped attack/support frames, imported RGBA, compact target calculations, actual container layout bounds, and input-time synchronization. The exported-pack test completes the three encounters with packaged resources; its external test script is not included in the release.

The layout gate exposed and fixed modal growth beyond 350×326 and reward-down leakage into Fight. `touch_action.gd` now consumes accepted input before invoking transition callbacks. Existing pointer release/cancellation, disabled holds, second fingers and mouse checks still pass. `browser_lifecycle.gd` remains unchanged. No skip/todo/only test suppression was added.

Aseprite initially needed repository-local configuration to avoid read-only home paths. Godot editor import/export still log the existing `net_socket_unix.cpp` / `tcp_server.cpp` listener limitation (`ERR_CANT_CREATE`); these operations exit 0. Tests, scene smoke, exported-pack smoke and exported-run logs contain no script/runtime errors.

## Visual inspection and preservation

Viewed all six native new sheets and both original attack sheets. New idle poses retain the original ready silhouettes and palettes. Support poses distinguish guard, crouching dodge, recoil and lowered defeat; samurai cut/heavy warnings differ. Scenery has the shared floor at local row 99; icons/props/effects use the specified separate layers. This sheet inspection is not browser/device aesthetic acceptance.

The original 18-entry manifests, complete ninja/samurai archives, attack resources, notices and UID identities remain unchanged. Both plans are preserved:

- Previous plan SHA-256: `22a18badb26b0c59a9db0916f6155af9a256d9e6800f0df99d25fb1852fbb412`.
- Expansion plan SHA-256: `4f68ae6644c1b93f40b983a484e0f03c9144dd45844e04138b29552fe73a2cdf`.

## Artifact and measured budgets

Complete release directory: `build/web/`, entry `build/web/index.html`. Pack: **84,768 bytes**, **85 entries**, below the 1 MiB budget. New PNG total: **10,391 bytes**, below 256 KiB. All eight resident atlas RGBA total: **504,320 bytes**, below 1 MiB. Headless node-count and repeated-reset gates pass; browser memory is not measured.

| File | Raw bytes | Local gzip level 9 bytes |
| --- | ---: | ---: |
| CREDITS.md | 2,933 | 1,386 |
| THIRD_PARTY_NOTICES.txt | 107,348 | 28,655 |
| index.audio.position.worklet.js | 2,973 | 1,161 |
| index.audio.worklet.js | 7,298 | 2,194 |
| index.html | 7,264 | 2,773 |
| index.js | 305,185 | 77,052 |
| index.pck | 84,768 | 45,225 |
| index.png | 21,443 | 19,328 |
| index.wasm | 38,034,280 | 9,237,412 |
| Total | **38,573,492** | **9,415,186** |

Gzip figures are calculated locally; no HTTP compression or transfer timing is claimed. The stock engine dominates the bundle. Pack checks assert all three encounters, all runtime scripts after compiled remapping, six new atlases and both originals, and exclusion of tests, tools, JSON, Aseprite sources, generators and GIFs. HTML/Wasm/settings checks establish a single-threaded artifact, not a functioning hosted page.

## Blocked browser/device QA

`python3 -m http.server 8060 --bind 127.0.0.1 --directory build` exited 1 with `PermissionError: [Errno 1] Operation not permitted` during socket creation. Brave Chromium headless (`/opt/brave.com/brave/brave --headless --no-sandbox --disable-gpu --user-data-dir=/tmp/moonlit-brave-qa --dump-dom about:blank`) terminated with signal 5: crashpad `setsockopt: Operation not permitted`. No page or HTTP responses were obtained. No substitute `file://` acceptance was used.

| Required coverage | Status |
| --- | --- |
| Chromium 390×844 / DPR 3 touch; 360×800; 430×932 | Pending, browser launch blocked |
| 360×740 and 390×700 available canvas | Compact math and scene bounds tested; browser visual/safe-area confirmation pending |
| Desktop real mouse browser | Native input regression passed; browser pending |
| Physical iOS Safari / Android Chrome | Pending, no session-accessible physical devices |
| Three clears and three losses on each device | Pending |
| Browser bars, safe areas, resize during press, landscape return | Pending |
| Page switch during both combo strikes, lock/unlock, storage disabled | Model/lifecycle paths tested; device behavior pending |
| Nested HTTP/HTTPS cold load and refresh, MIME types, no failed requests | Pending, sockets blocked; no deployment authorized |
| `crossOriginIsolated === false`, WebGL-unavailable error display | Settings/startup path retained; browser confirmation pending |
| 60-second median ≤17.5 ms / p95 ≤33.4 ms, draw calls ≤120 | Pending, no physical-device profiler data |
| 20 browser resets, ≤10 MiB memory fluctuation | Node/connection stability tested; browser memory pending |
| Three cold loads on 10 Mbps / 100 ms RTT ≤15 sec; warm ≤3 sec | Pending, no network/browser measurement |

All requested screenshots remain pending: `390x844-title.png`, `390x844-gate-cut.png`, `390x844-double-cut-2.png`, `390x844-heavy-dodge.png`, `390x844-opening.png`, `390x844-technique.png`, `390x844-cleared.png`, `390x844-failed.png`, `ios-safari-portrait.png`, `android-chrome-portrait.png`, and `compact-360x740.png`. No fabricated screenshots, console/network traces or performance values are provided.

[files-changed.txt](files-changed.txt) records every modified/untracked path at completion, including changes inherited from the previous run. Generated `build/`, `.godot/` and texture import caches remain ignored. The implementation is committed and published; the working tree was clean after the deployment follow-up.
