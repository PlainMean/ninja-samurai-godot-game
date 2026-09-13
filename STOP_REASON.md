# Elemental swords implemented — 2026-09-13

Completed from clean HEAD `8316754` in three bounded implementation passes.
Four Aseprite-authored sword assets cover the six existing weapons: WATER
Tideglass/Moonwake, FIRE Cinder Fang/Dawnbrand, EARTH Stone Oath, WIND Gale Feather.
The main player has a pose-following equipped sword overlay and derived body-only
sheets; all previous art, Kira’s poleblade and gameplay rules are preserved.
Loadout, inventory, loot, map and combat project the correct icon/element.

Final targeted suite: **225 checks, zero failures**. Full `game/tests/verify.sh`:
**20,801 checks, zero failures**, Web export, exported legacy and four-area clears,
four visual specs/six equipped selections and all legacy asset checks. Aseprite
reproduction/native verification, independent sword/body pixel verification,
**163 prior art hashes**, and `git diff --check` pass. Pass 2’s three map-fit
failures were repaired with the original assertions retained.

Artifact: `build/web/index.html` and siblings. HEAD remains `8316754`; changes
are local and uncommitted because `.git` is read-only in this environment.
No push or deployment.

Four-sword Aseprite contact sheet inspected. Native 390×844 capture failed on
both supplied and virtual displays (X11/Wayland unavailable); zero game captures.
Browser/device rendering, touch/lifecycle and performance remain unverified.
Headless mobile bounds and compact HUD alignment pass; native script is provided.

[QA and real totals](qa/2026-09-13-elemental-swords/validation.md) ·
[Exact file roster](qa/2026-09-13-elemental-swords/files.md) ·
[Plan](.hermes/plans/2026-09-13_225008-elemental-swords.md) ·
[Four swords](qa/2026-09-13-elemental-swords/four-swords.png)
