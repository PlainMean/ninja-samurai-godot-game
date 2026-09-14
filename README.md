# Moonlit Dojo: Four Lands

A touch-first portrait combat journey for Godot 4.5.1 Standard. Choose a sword
and two elemental techniques, explore a branching four-area map, recruit Kira,
and defeat twelve distinct guardians and four bosses.

**Choose MAIN HERO or KIRA, then a living enemy target.** Main Hero keeps the
four normal elemental attacks and six equipped weapons. Kira joins after the
first boss and has her own WATER **Tide Arc**, independent of your sword. Her
poleblade, sprite, HP and development remain distinct. One chosen action spends
the turn; surviving enemies reply once each, in numbered slot order.

Tap **SKILLS** for Flame Dash, Stone Guard and Windstep. The panel shows exact
damage, defense, incoming damage and cooldowns. Its Kira auto switch enables or
disables Support Strike/Ward Pulse after Main Hero actions. Kira never takes
both a manual attack and an automatic support action in the same turn.

| Action | Formula/effect | Availability |
| --- | --- | --- |
| Main normal attack | Seeded 1–4 + sword bonus + technique bonus + advantage | Your unlocked techniques |
| Kira: Tide Arc · WATER | 3 + Kira development (0–2) + advantage | Kira alive; no sword/RNG dependency |
| Flame Dash · FIRE | 5 + skill development (0–2) + advantage | Two intervening actions before reuse |
| Stone Guard · EARTH | Block pool 3 + development across this reply phase | Same cooldown; no direct damage |
| Windstep · WIND | 3 + development + advantage; evade first surviving reply | Same cooldown |

Matching swords add **2 on odd rolls, 1 on even rolls**. Technique levels 1–3
add 0/1/2. Advantage adds exactly +1 for **WATER>FIRE, FIRE>EARTH, EARTH>WIND,
WIND>WATER**; every other pairing is neutral. Only normal sword impacts consume
the run seed. Enemy damage is 1 against neutral affinity, before defense.

| Area | Guard 1 | Guard 2 | Boss |
| --- | --- | --- | --- |
| Fire Land | Cinder Rival | Ash Monk + Gale Assassin | Ash Shogun |
| Water Shrine | Gate Guard | Twin-cut Retainer + Cinder Rival | Moonlit Master |
| Earth Marches | Earth Sentinel | Iron Vanguard + Gate Guard | Mountain Regent |
| Wind Coast | Gale Assassin | Coast Ronin + Ash Monk + Earth Sentinel | Tempest Sovereign + Iron Vanguard |

Leaders retain their original 8 HP (guards) or 16 HP (bosses); each minion has
3 HP and its own affinity, role, sprite and intent cycle. Target cards show
individual HP, roles, next intent element, selection and BOSS/fallen status.
A fallen enemy cannot be selected or reply. Every member must fall to earn the
node’s seal. All twelve original single-enemy resources and the eight-seal
legacy campaign remain executable regression cases.

Fire starts unlocked. Both guards unlock the area boss; bosses open neighboring
areas around Fire ↔ Water ↔ Earth ↔ Wind ↔ Fire. Loot, the six-sword inventory,
four distinct elemental sword visuals and archive reveal are preserved.
Shrines heal Main Hero to 12 and revive Kira to 6 HP. You can develop the skill
kit to +2 independently of the existing technique and Kira training choices.

Kira loses 1 HP after each actual enemy reply, even a blocked reply; evaded
replies cause no fatigue. At zero HP she falls, her action locks, and Main Hero
continues. Actor/auto preferences, HP and development persist through map,
loot and shrine transitions. Targets, cooldowns and defense reset per encounter.
Retry/title resets the entire run and starts solo.

```bash
bash game/tests/verify.sh
XDG_DATA_HOME="$PWD/build/local/data" XDG_CACHE_HOME="$PWD/build/local/cache" XDG_CONFIG_HOME="$PWD/build/local/config" ~/.local/bin/godot --path game
```

Local single-threaded Web artifact: **`build/web/index.html` and siblings**.
No push or deployment. Native display attempts failed before rendering in this
environment; headless bounds tests pass at 390×844 and 390×780, but native,
browser and physical-device visual acceptance remains unverified.

[Architecture and rules](game/README.md) · [Dated plan](.hermes/plans/2026-09-14_192244-multi-hero-combat.md)
· [QA and exact results](qa/2026-09-14-multi-hero-combat/validation.md)
· [Credits](CREDITS.md) · [Stop/status](STOP_REASON.md)

This expansion adds no raster art. All existing Aseprite sources, PNGs, frame
resources and sword/body assets remain byte-identical.
