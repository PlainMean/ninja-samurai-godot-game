# Elemental swords QA — 2026-09-13

Started from clean `8316754bae815fa03390fcd6c206b2356714aceb`.
Three bounded implementation passes, no push or deployment. All prior assertions
remain. No skips, todos, only filters or parse-error suppression were introduced.

## Roster and implementation

| Element | Asset | Existing weapons |
|---|---|---|
| WATER | `water` — blue open tideglass crescent | `tide` / Tideglass, `moon` / Moonwake |
| FIRE | `fire` — orange branching cinder flame | `cinder` / Cinder Fang, `dawn` / Dawnbrand |
| EARTH | `earth` — brown broad faceted ore blade | `stone` / Stone Oath |
| WIND | `wind` — silver-white feather blade | `gale` / Gale Feather |

Each has a layered-editable Aseprite document (one raster layer), JSON metadata,
192×48 PNG strip, four 48×48 cells with distinct 100ms glints, Godot SpriteFrames
and a data-only WeaponVisualSpec. Palettes are in the source spec and manifest.
The player-only overlay swaps by equipped element, follows original attack and
support pose grips, and uses separate body-only Aseprite exports. Kira and enemies
keep their original presentation. Six weapon resources and combat/run model files
are unchanged. Exact changed/new files: [files.md](files.md).

## Gates and actual results

- Pass 1: native Aseprite and independent sword verifiers passed; full gate
  **20,576 checks / 0 failures**, Web export and both exported campaign clears.
- Pass 2: **199 targeted checks / 0 failures**. Initial full run found three
  existing map-fit failures. The duplicate label was removed and the icon row
  compacted; repaired full gate **20,775 checks / 0 failures**, including all
  original bounds assertions. Both attempts are retained in the logs.
- Pass 3: **225 targeted checks / 0 failures**; full `game/tests/verify.sh`
  **20,801 checks / 0 failures**. The gate separately reran **96 companion
  checks / 0 failures**; these suites are also part of the full count, not extra
  unique assertions. Native capture script parse check passed.
- Independent asset verifier: **4 swords, 16 distinct frame hashes, 20 file
  hashes, 6 pairwise silhouette comparisons, 163 preserved prior art hashes**.
  Compressed native cels equal PNG cells; native and JSON tag/timing, dimensions,
  alpha, palette and dominant element colors pass.
- Independent derived-body verifier: **6 attack + 12 support frame cel sets**
  retain original pixels, tags and durations; composited body pixels match source
  and runtime PNGs. **10 derived file hashes** pass.
- `bash art_sources/weapons/reproduce.sh`: Aseprite reproduced **6 PNG sheets and
  6 JSON documents byte-for-byte**, including all four swords. Native verifier
  reopened the regenerated swords and compared every source/export pixel.
- Web release export and exported-pack smoke passed: **279 pack entries**,
  four visual specs, six equip selections, imported sword/body sheets and HUD
  projection. Full legacy clear: **8 encounters, 19 attacks, 11 replies**.
  Full area clear: **12 nodes, 4 bosses**, recruitment, loot, shrines and map.
- `git diff --check` passed. No gameplay model changes; existing deterministic
  cycle, seeded base damage, same-element bonus, route and Kira tests pass.

Logs: `pass1-verify.txt`, `pass2-targeted.txt`, `pass2-verify.txt` (failed layout
attempt), `pass2-verify-repaired.txt`, `pass3-targeted.txt`, `pass3-verify.txt`,
`reproduction.txt`. Editor/export logs contain sandbox socket-listener errors;
no script/parse failures were ignored, and the release pack was loaded and tested.
An early standalone import also could not write the default editor cache; the
full verification uses repository-local XDG cache/config/data and completes.

## Visual inspection and limits

Inspected all four original strips and [four-swords.png](four-swords.png), an
Aseprite-produced 2× nearest contact sheet ordered WATER, FIRE, EARTH, WIND.
The four silhouettes and colors are distinct. This is asset review, not a game
screenshot. No runtime raster asset was generated with Python, SVG, ImageMagick,
diffusion, browser canvas or Godot. Python tooling only reads/verifies pixels,
copies exported files and writes text metadata.

Native 390×844 game capture attempted against DISPLAY=:1 and again with
`xvfb-run`; both failed to connect to X11/Wayland in the sandbox. **Zero native
game captures**. `native_swords_smoke.gd` remains ready for an available display.
Headless layout assertions passed at 390×844 and 390×780, but actual rendered
player alignment, browser WebGL/HTTP, physical iOS/Android touch/lifecycle and
performance still need device/display acceptance. No browser/device test is claimed.

Local artifact: `build/web/index.html`, `index.pck` and siblings. Bundle total
**38,725,190 raw bytes / 9,472,699 gzip bytes** as reported by the export checker.
HEAD remains `8316754`; work is local and uncommitted. The environment grants
read-only access to `.git`, so no commit was created. No push or deployment.
