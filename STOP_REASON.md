# Companion hero implemented — 2026-09-13

Implemented from clean HEAD `e71a0a2` in three bounded passes. Kira the Tideblade
joins exactly after the first boss victory with a required Continue modal. Her
WATER support, six HP, defeat/revival, shrine ability choice and level upgrades
are deterministic model rules. Separate ally sprite, portrait, HUD and events
project them. Pre-boss rules, map locks, sword damage and elemental cycle remain.

Final targeted suite: **96 checks, zero failures**. Full `game/tests/verify.sh`:
**20,576 checks, zero failures**, plus Web export, exported legacy and four-area
full clears, companion resource/import selection, native script checks and all
asset verifiers. Aseprite reproduction/native verifier and independent decoder
passed four frame hashes, six file hashes, 192 prior-enemy silhouette comparisons
and preservation of 110 previous art/frame files. `git diff --check` passed.

Local artifact: `build/web/index.html` and siblings. No push or deployment.
HEAD remains `e71a0a2`; changes are local and uncommitted. This workspace exposes
`.git` read-only; no commit is claimed.

Kira’s strip was inspected directly. Native 390×844 capture was attempted but
X11 and Wayland were unavailable; zero game captures. Browser WebGL/HTTP,
physical iOS/Android touch/lifecycle, visual readability and performance remain
unverified. Headless layout checks cover ally text and bounds at 390×844/390×780.

[Plan](.hermes/plans/2026-09-13_164500-companion-hero.md) ·
[QA and exact changed files](qa/2026-09-13-companion/validation.md) ·
[Art specification](art_sources/heroes/ASSET_SPEC.md)
