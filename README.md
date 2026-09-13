# Moonlit Dojo: Four Lands

A touch-first, portrait elemental sword journey for Godot 4.5.1 Standard.
Choose one of four starting swords and any two of FIRE, WATER, EARTH and WIND.
Tap the Area Map to choose your next guard, defeat each region’s boss, collect
opponent swords, and unlock or develop techniques at shrines.

**Kira the Tideblade joins after your first boss victory.** Confirm the join
with Continue, then this WATER tide warden supports your attacks automatically.
Her copper braid, ivory armor and crescent poleblade have a dedicated animated
silhouette. She has 6 HP; surviving enemy replies cost her 1 HP. At zero she
falls until the next shrine restores her. Choose Support Strike or Ward Pulse
and develop her to level 3 at shrines, alongside your existing training.
Retry removes Kira and starts solo again.

| Area | Guard 1 | Guard 2 | Boss |
| --- | --- | --- | --- |
| Fire Land | Cinder Rival | Ash Monk | Ash Shogun |
| Water Shrine | Gate Guard | Twin-cut Retainer | Moonlit Master |
| Earth Marches | Earth Sentinel | Iron Vanguard | Mountain Regent |
| Wind Coast | Gale Assassin | Coast Ronin | Tempest Sovereign |

Each area has two 8-HP guards, selectable in either order, then a 16-HP boss.
Fire starts unlocked. Bosses open neighbors on the ring Fire ↔ Water ↔ Earth ↔
Wind ↔ Fire. After Fire, choose Water or Wind; all twelve nodes can be cleared.
All enemies in a region use its affinity; bosses have longer four-strike cycles.

Inventory: **Cinder Fang, Tideglass, Stone Oath, Gale Feather, Dawnbrand,
Moonwake**. The first four are starting swords. Every victory collects the foe’s
sword and lets you equip it or another inventory sword. Shrines restore 12 HP
and grant one technique unlock/level increase. Levels cap at 3; once all four
are mastered, continue without further power growth.

Every player impact consumes one explicit seeded roll: **1–4 + matching sword
bonus + technique bonus + matchup bonus**. A matching sword adds **1 on even
rolls, 2 on odd rolls**; level adds **0/1/2**. Only WATER→FIRE, FIRE→EARTH,
EARTH→WIND and WIND→WATER add **+1**. All other pairings are neutral. The UI
shows total ranges and technique levels. Enemy replies retain 1/2 semantics;
with the neutral player affinity they deal 1 before Kira’s optional ward. Nothing rolls on a forecast or tap.

```bash
bash game/tests/verify.sh
XDG_DATA_HOME="$PWD/build/local/data" ~/.local/bin/godot --path game
```

The original eight encounters and full legacy regression campaign remain intact.
Twelve new Aseprite-authored unit sets give every node its own weapon, silhouette,
palette and four-frame attack. Bosses have distinct crowns/helms/mantles and larger
scale, with BOSS markers. Unit roles appear on the map, HUD, intro and loot.
Every previous art file is byte-preserved. Blue water, red fire, brown earth and white wind retain their
authored impacts. Pause/resume, full-run retry/reset and the archive reveal remain.

[Architecture](game/README.md) · [Plan](.hermes/plans/2026-09-13_164500-companion-hero.md)
· [QA](qa/2026-09-13-companion/validation.md) · [Roadmap](.hermes/plans/2026-09-12-area-roadmap.md)
· [Credits](CREDITS.md). Local Web bundle: `build/web/index.html` and siblings.
No push or deployment. Browser/device visual acceptance remains pending.
