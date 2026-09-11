# Moonlit Dojo: Three Seals

Tap **Begin run**, read the introduction, and tap **Fight**. Start with 5 HP and face Gate Warden (3 HP), Twin-cut Retainer (4 HP), and Moonlit Master (5 HP). All three samurai are **WATER**; their only weakness is **WIND**, explicitly shown on the HUD and introductions, including the final boss.

Choose **FIRE**, **WATER**, **EARTH**, or **WIND** on your player turn. There is no decision deadline. Your attack resolves, then a surviving samurai automatically takes one WATER turn. The next player turn waits for a fresh tap. There are no defense inputs, reaction warnings, or counter windows.

Rows are attackers; columns are defenders. **E2** means EFFECTIVE / 2 damage; **N1** means NEUTRAL / 1 damage.

| Attack \ Defense | FIRE | WATER | EARTH | WIND |
| --- | --- | --- | --- | --- |
| FIRE | N1 | N1 | E2 | N1 |
| WATER | E2 | N1 | N1 | N1 |
| EARTH | N1 | N1 | N1 | E2 |
| WIND | N1 | E2 | N1 | N1 |

The player has no affinity in this run, so WATER replies deal 1 damage. Choosing an attack does not assign an affinity. The typed model also supports an explicit affinity: WATER deals 2 against FIRE and 1 against every other affinity, including NONE. No inverse resistance is inferred.

Health carries between fights. After seal one, choose Mend (restore 2 HP) or Long Breath (+1 max HP and restore 1 HP). Long Breath's old timing bonus is replaced because turns have no deadline. After seal two, choose Mend or Iron Resolve (+1 max HP and restore 1 HP); the two upgrades stack to 7 max HP. Mend clamps to max HP and is disabled at full health. Rewards apply once. Retry and New run reset HP, seals, attacks, and upgrades. Pause freezes the exact phase and requires Resume; Return to title discards the run. Touch and real mouse work without input emulation; holding and multiple fingers cannot repeat an attack.

The HUD shows turn number, both health values, enemy element/weakness, selected attack, matchup, damage, and the three latest combat log entries. No new artwork was needed; all original asset bytes are preserved.

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

`Element` defines typed elements and one deterministic directed matchup resolver. `EncounterSpec` stores enemy affinity and the existing encounter identity, health, and scenery. `CombatModel` owns damage and emits typed impact events. `RunModel` owns progression, carried HP, rewards, and attack/damage statistics. `duel.gd` coordinates them and hands terminal state to the run once after 400 ms. Pooled visual effects never deal damage.

Flow: TITLE → INTRO → PLAYER_TURN → PLAYER_ATTACK → ENEMY_TURN → ENEMY_ATTACK → next PLAYER_TURN. A lethal player attack skips the enemy turn. A lethal enemy attack ends the run. Player choice is untimed; resolution retains the six original 100 ms attack frames with impact at 300 ms and completion at 600 ms. ENEMY_TURN is a 350 ms automatic announcement, with all four inputs disabled. It is not an input window.

Input and rendering share one injectable monotonic clock. Input eligibility is sampled before synchronization so a tap during resolution cannot queue an attack at the next turn boundary. Engine/wall gaps above 250 ms pause without unseen damage. Pause retains exact elapsed time and the impact latch in every phase. Decorative clocks freeze. Lifecycle events leave introductions/rewards/results inert.

Stopped sprite playback uses authored frame durations. Support priority is defeat, hurt, attack, idle. Authored scenery remains 2×; fighters remain 4× on the shared floor y=450. Only the enemy flips. Existing hit and seal effects are reused; no asset pixels, frame resources, or original manifests changed.

Baseline layout remains 390×844, with the existing 780-high compact layout. The four equal actions are 83×96 logical pixels, with 6 px gaps; pause remains 60×60. Tests cover scaled 1×/2×/3× touch flows and target/bounds checks across five portrait sizes, including compact layouts. These checks do not establish actual visual readability.

The current automated result is recorded in [elemental QA](../qa/mobile/elemental/validation.md). Native rendering capture can be run on a display-enabled host after the XDG setup:

```bash
~/.local/bin/godot --path game --script res://tests/native_visual_smoke.gd
```

It captures 390×844 viewport PNGs across title, intro, attacks, enemy turn, next turn, pause, rewards, boss and clear into `qa/mobile/elemental/`. These are rendering evidence, not game art. This environment's display connection failed; no screenshots are claimed.

## Local release and QA

```bash
python3 -m http.server 8060 --bind 127.0.0.1 --directory build
curl -fI http://127.0.0.1:8060/web/index.html
curl -fI http://127.0.0.1:8060/web/index.wasm
curl -fI http://127.0.0.1:8060/web/index.pck
```

Open the nested URL `http://127.0.0.1:8060/web/index.html`, never `file://`. Publish the complete `build/web/` only in an authorized deployment. It includes engine worklets and notices; no service worker, threads, SharedArrayBuffer or cross-origin isolation is required. The existing Pages workflow deploys only after successful verification on an authorized main push or dispatch. Failure logs are uploaded separately.

Native X11/Wayland rendering and an Xvfb fallback failed in this managed environment. Browser and physical iOS/Android visual/readability, safe areas, network/MIME/HTTPS, device frame times, draw calls, browser memory and load measurements remain pending. See [elemental QA](../qa/mobile/elemental/validation.md) for actual results. This pass does not push or deploy; historical deployment records refer to the previous combat version.
