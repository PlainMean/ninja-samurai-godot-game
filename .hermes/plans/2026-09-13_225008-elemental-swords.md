# Elemental swords — 2026-09-13
Start: clean 8316754bae815fa03390fcd6c206b2356714aceb. No push/deploy.

Audit: six WeaponSpec resources carry element only; RunModel owns inventory, validates equip in loadout/map/loot/training, seeds damage independently. Duel refresh projects all area actions; FighterView selects attack/support sheets; arena has separate Ninja, Samurai, Companion nodes. Kira owns a poleblade in her sheet. HUD already names equipped weapon in area combat; AreaPanel builds scrolling mobile buttons. Ninja sources have separable weapon layers. Export is an explicit resource allowlist. Legacy source manifests and campaign tests remain mandatory.

Bounded passes (each ends with targeted tests and game/tests/verify.sh):
1. Author four 48px swords in Aseprite Lua, native verification, independent pixel verification and preserved-art baseline; package resources and inspect graphics.
2. Map elements through data resources, attach player-only pose-following overlay and blade-free derived player sheets, project icons in loadout/loot/map/HUD; deterministic scene/equip tests and export selection checks.
3. Reproduce outputs, native 390x844 visual QA, final documentation and all verification; repair findings within this pass. Fourth pass reserved only for a discovered failure.

Do not modify combat math, inventory rules, old art or old assertions. Record actual results and limitations in dated QA and STOP_REASON.

## Completion

1. Asset audit/authorship gate passed: 20,576 legacy checks; four swords verified
   natively and independently, 163 prior-art hashes preserved.
2. Runtime/UI/export gate passed: 199 targeted, 20,775 full checks. Three map-fit
   failures in the first gate attempt were repaired by removing duplicate weapon
   text and compacting the icon row; existing assertions were retained.
3. Reproduction/body-preservation/mobile-layout gate passed: 225 targeted,
   20,801 full checks; Web export and both complete exported campaigns pass.
   Six sheets/JSON documents reproduce with Aseprite. Four sword graphics visually
   inspected; native and Xvfb display attempts failed, documented without claiming
   browser/device acceptance. No fourth implementation pass needed.

See dated QA for logs, exact files and limits. Local artifact build/web/index.html.
HEAD 8316754 unchanged; local uncommitted work, read-only .git; no push/deploy.
