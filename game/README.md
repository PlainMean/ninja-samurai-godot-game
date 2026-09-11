# Moonlit Dojo: Three Seals

Tap **Begin run**, read each introduction, and tap **Fight**. Start with 5 HP and face Gate Warden (3 HP), Twin-cut Retainer (4 HP), and Moonlit Master (5 HP). Health carries between encounters. Block normal CUT, Dodge HEAVY, and defend both hits of a double cut with separate taps. Each warning accepts one irreversible defense; wrong or missing defenses cost 1 HP. Strike only in the opening earned by defending the entire pattern. Every counter deals 1 damage.

After the first seal, choose Mend (restore 2 HP) or Long Breath (counter windows +300 ms). After the second, choose Mend or Iron Resolve (max HP 6, restore 1 HP). Mend is disabled at full health. Rewards apply once. Defeat finishes its animation before results. Retry and New run return to the first introduction with fresh HP and no upgrades. Pause requires an explicit Resume; Return to title discards the run. Touch and real mouse work without input emulation. Holding never repeats. No keyboard, audio, storage, plugins, or network service is required.

## Pinned setup

Use Godot **4.5.1 Standard**, exact build `4.5.1.stable.official.f62fdbde1`, Compatibility renderer, and matching `4.5.1.stable/web_nothreads_release.zip`. Default executables are `~/.local/bin/godot` and `~/.local/bin/aseprite`. Aseprite authorship used **1.3.18.3-dev**. CI validates checked-in art and resources without Aseprite.

From the repository root:

```bash
game/tests/verify.sh
export XDG_DATA_HOME="$PWD/build/local/data"
export XDG_CACHE_HOME="$PWD/build/local/cache"
export XDG_CONFIG_HOME="$PWD/build/local/config"
~/.local/bin/godot --path game
```

The wrapper creates ignored XDG directories and links installed export templates. Override `GODOT_BIN` and `GODOT_TEMPLATE_DIR` (the parent of `4.5.1.stable`) for another installation. It rejects any other engine build and detects script errors even when Godot exits zero.

## Verification and maintenance

After the XDG setup above:

```bash
~/.local/bin/godot --version
python3 game/tests/check_source_assets.py
sha256sum -c game/tests/source_assets.sha256
python3 game/tests/check_moonlit_assets.py
sha256sum -c game/tests/moonlit_assets.sha256
~/.local/bin/godot --headless --path game --editor --import
~/.local/bin/godot --headless --path game --script res://tests/run_tests.gd
~/.local/bin/godot --headless --path game --quit-after 120
~/.local/bin/godot --headless --path game --export-release Web ../build/web/index.html
~/.local/bin/godot --headless --path build/web --main-pack index.pck --quit-after 120
~/.local/bin/godot --headless --path build/web --main-pack index.pck --script "$PWD/game/tests/export_pack_smoke.gd"
cp CREDITS.md THIRD_PARTY_NOTICES.txt build/web/
python3 game/tests/check_web_export.py
git diff --check
```

The six layered sources, canonical PNGs, JSON, specification and independent verifier live in `art_sources/moonlit_dojo/`. To reproduce them in an ignored directory:

```bash
~/.local/bin/aseprite --version
~/.local/bin/aseprite --batch --script-param out="$PWD/build/art-repro" --script art_sources/moonlit_dojo/generate_moonlit_dojo.lua
~/.local/bin/aseprite --batch --script-param out="$PWD/build/art-repro" --script art_sources/moonlit_dojo/verify_moonlit_dojo.lua
python3 game/tests/check_moonlit_assets.py
# Rebuild metadata-driven AtlasTexture/SpriteFrames resources when maintaining assets:
~/.local/bin/godot --headless --path game --script res://tools/import_moonlit_assets.gd
```

The generator uses Aseprite Sprite/Image APIs exclusively. Python performs read-only hashes, PNG decoding and metadata checks; it does not author or export art. Original ninja/samurai assets, reports, attack resources and both original manifests remain unchanged, including the original ninja's partial alpha. New alpha is binary. Runtime PNG copies match the native exports exactly. Checked-in SpriteFrames derive frame regions and duration multipliers from JSON; JSON and source archives never enter the pack.

## Architecture and timing

`CombatModel` consumes deterministic time boundaries, owns combat HP, and emits typed `CombatEvent` impacts. Immutable `EncounterSpec`, `PatternSpec`, and `StrikeSpec` resources describe the three fixed encounters. `RunModel` owns progression, carried HP, rewards, and aggregate statistics. `duel.gd` coordinates both, consumes terminal handoff exactly once after 400 ms, and projects state into reusable arena/fighter/HUD/modal scenes. Pooled effects do not deal damage.

| Guardian | Pattern | Rest | Warnings | Counter window |
| --- | --- | --- | --- | --- |
| Gate Warden | Single CUT | 700 ms | 900 ms | 1,200 ms |
| Twin-cut Retainer | Double CUT | 650 ms | 850 / 700 ms | 1,100 ms |
| Moonlit Master | HEAVY, single CUT, double CUT | 600 ms | 1,050; 750; 750 / 650 ms | 1,000 ms |

All attacks retain six original 100 ms frames, impact at 300 ms, and full 600 ms recovery. Inputs use half-open intervals. The coordinator shares one injectable monotonic clock between input and frame processing, so an interval is never consumed twice. Engine delta or wall gaps greater than 250 ms pause without unseen damage. Pre-impact enemy pauses replay the current warning while preserving earlier combo outcomes. Resolved impacts retain recovery; openings restart; player attacks retain elapsed time. Lifecycle notifications leave introductions/rewards/results inert. Decorative/effect clocks freeze during pause.

Stopped AnimatedSprite2D playback uses metadata durations rounded to their authored millisecond precision. Support priority is defeat, hurt, attack, defense, warning, idle. Authored scenery is 2×; fighters are 4× with shared floor y=450 and offset (-16,-30). Only the enemy flips. Attack lunge peaks at 24 logical pixels; dodge retreats 20 pixels at impact. No runtime recolor, generated guard arcs, particles, or per-frame resource loads.

Baseline logical layout is 390×844. The explicit compact layout uses logical height 780 for short available areas, raises the action row/footer and reduces empty arena space. Web content-scale size changes with this layout while retaining `canvas_items` / `keep`. Actions remain 110×96, pause 60×60; calculated CSS targets remain at least 48 px across the required portrait sizes. Containers and touch transitions have automated bounds/ownership tests; these do not replace browser visual QA.

`touch_action.gd` consumes an accepted down before emitting its callback, preventing that same event from activating a newly revealed modal button after pointer cancellation. All prior release/cancel/second-finger/disabled-hold/mouse regressions remain tested. Browser lifecycle code is unchanged.

## Local release and QA

```bash
python3 -m http.server 8060 --bind 127.0.0.1 --directory build
curl -fI http://127.0.0.1:8060/web/index.html
curl -fI http://127.0.0.1:8060/web/index.wasm
curl -fI http://127.0.0.1:8060/web/index.pck
```

Open the nested URL `http://127.0.0.1:8060/web/index.html`, never `file://`. Publish the complete `build/web/` only in an authorized deployment. It includes engine worklets and notices; no service worker, threads, SharedArrayBuffer or cross-origin isolation is required. The existing Pages workflow deploys only after successful verification on an authorized main push or dispatch. Failure logs are uploaded separately.

The current environment blocks localhost sockets and browser launch. Physical iOS/Android QA, screenshots, WebGL/readability, safe areas, network/MIME/HTTPS, device frame times, draw calls, browser memory and cold/warm load measurements remain pending. See the [dated QA record](../qa/mobile/moonlit-dojo/validation.md) for actual commands/results and complete file inventory. No live deployment is claimed.
