# Companion hero QA — 2026-09-13

Base was clean `e71a0a2`. Three bounded implementation passes; fourth unused.
No push or deployment. HEAD remains `e71a0a2`; all changes are local and
uncommitted (.git is read-only in this workspace). See [exact files](files.txt).

## Delivered behavior

Kira the Tideblade is a WATER tide warden with six HP, a copper braid, ivory
armor and a crescent poleblade. First victorious boss handoff commits its seal,
sets `first_boss_defeated`, joins Kira and stops in RECRUIT before any reward,
shrine, map or reveal. The 64px Continue button must be pressed. Detection is
area-independent; the existing Fire-first ring locks are retained. Tests isolate
each of the four areas as the first boss without changing the shipped map.
Legacy recruitment happens after its final Moonlit Master, preserving the exact
19 attacks and 11 enemy replies through all 128 legacy reward paths.

After a nonlethal main hit Kira automatically uses Support Strike (WATER damage
1–2, upgraded to 2–3 or 3–4) or Ward Pulse (blocks 1, 2 or 3 reply damage).
Support uses no RNG; either lethal hit suppresses the enemy reply. A surviving
enemy replies to the player first, then costs Kira one fatigue HP. At zero HP she
falls and stops supporting; shrine entry restores her. Choice/mastery persists;
retry/title fully resets. Shrine development is optional once per visit before
the unchanged player training choice. Separate arena ally, join portrait,
HP/element/ability/availability HUD and combat events/log project model state.

## Gates actually run

| Gate | Result |
| --- | --- |
| Pass 1 full verify.sh | 20,286 checks, zero failures; Web and exported clears pass |
| Pass 2 targeted / full | 80 / 20,560 checks, zero failures; Web and exported clears pass |
| Pass 3 targeted / full | 96 / 20,576 checks, zero failures; Web and exported clears pass |
| Aseprite generator | Four 48×48 poses, 100ms support tag; reproduction PNG byte-equal |
| Aseprite native verifier | Reopened editable source; four exact source/export frame matches |
| Independent read-only verifier | Compressed native cels = decoded PNG; dimensions, alpha, seven-color palette, tag/timing, six file hashes and four unique frame hashes pass |
| Old enemy silhouette comparisons | 192 comparisons pass, ignoring color |
| Prior art preservation | All 110 prior tracked art/frame hashes pass; all original manifests retained |
| Lossless imported hero pixels | Godot imported RGBA = original PNG; nearest/no mipmaps pass |
| Native/script/normal scene smoke | Parse and headless scene checks pass, including new native capture script |
| Exported pack smoke | Full legacy + twelve-node/four-boss clears; hero spec/frames/PNG/import/selection pass |
| Mobile model/scene bounds | Ally text and HUD/fighter/log separation pass at 390×844 and 390×780 |
| git diff --check | Pass |

Targeted checks cover absent-at-start, guard victory, all four first-boss
identities, loss, required/idempotent join acknowledgment, explicit modal and
portrait, stats, ordering, damage bounds at all levels/elements, seed/timestep
reproducibility, lethal suppression, ward-aware forecast, HP/fall/revival,
shrine choice/cap, persistence, retry/title and normal scene resource selection.
The full suite retains every previous assertion. Pass 2 caught and fixed a
mixed-indentation test driver and three map-fit failures caused by an extra ally
line. The map now uses its existing summary line for ally status after joining.

## Art and local release

The only new raster source is `art_sources/heroes/kira.aseprite`, authored and
exported with `~/.local/bin/aseprite` Lua Sprite/Image APIs. No Python/Pillow,
ImageMagick, SVG, canvas, diffusion or Godot raster authorship. Python is used
only for text/metadata work and independent read-only decoding/hash checks.
The source strip `art_sources/heroes/kira_sheet.png` was inspected visually.
Aseprite initially needed writable XDG_CONFIG_HOME; no HOME override was used.
The successful reproduction is retained at `build/hero-repro/`.

Release entry: `build/web/index.html` with all sibling files. PCK is **206,960
bytes / 245 entries**. Complete bundle: **38,699,547 raw bytes / 9,463,260 gzip
bytes** (per-file gzip level 9). Export roots and pack-directory assertions include
HeroSpec, Kira resource, SpriteFrames, PNG import and compressed runtime texture.
Serve the directory over HTTP for browser use; it has not been served/deployed here.

## Honest visual/device limits

Native 390×844 capture was attempted using `native_companion_smoke.gd`. Godot
reported X11 unavailable and could not connect to Wayland; no display server
could be created. **Zero native game screenshots captured**; see
[native attempt](native-capture.txt). This is an environment limit, not a passed
visual smoke. Headless editor/export logs also contain local TCP socket creation
errors from the restricted environment; parse/load errors are still fatal to
verify.sh and were never suppressed.

Browser WebGL/HTTP, physical iOS/Android touch and lifecycle, on-device visual
readability, safe areas and performance remain unverified. A native smoke driver
is included for solo, recruitment, shrine, companion combat/support and reset
captures when a display is available.

## Evidence

- [Pass 1](pass1-verify.txt), [pass 2](pass2-verify.txt), [pass 3](pass3-verify.txt)
- [Targeted pass 2](pass2-targeted.txt), [targeted pass 3](pass3-targeted.txt)
- [Aseprite generator](aseprite-generator.txt), [native verifier](aseprite-native.txt), [independent verifier](independent-assets.txt)
- [Plan](../../.hermes/plans/2026-09-13_164500-companion-hero.md)
- [Exact files](files.txt), [final status](status.txt), [diff check](diff-check.txt)
