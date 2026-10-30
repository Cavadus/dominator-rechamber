# JAR-5 Dominator Rechambered v4.1.0 — Ordnance stat-plan

Rechambers the JAR-5 Dominator to the P/40-K Bolt Pistol's explosive gyrojet warhead.

v4.1.0 moves off the manual file-swap onto Ordnance's **offline stat-plan** format:
the rechamber is a set of offset-based edits to the game's `.dl_bin` tables, applied
by [Ordnance](https://github.com/Cavadus/ordnance) at deploy time. No loader, no
Arsenal, no exit-and-relaunch dance — enable, deploy, launch.

## Install

1. Grab one of the v4.1.0 archives from the [latest release](https://github.com/Cavadus/dominator-rechamber/releases/latest), and add it to Ordnance.
2. Enable the variant you want, pick an optional firing sound, and Deploy.

## Variants

| Variant | Muzzle velocity | Range | Arming | Recoil | Mags | Blast |
|---|---|---|---|---|---|---|
| **Regular** | 380 m/s | 532 m | 7 m | x1.20 | 6 | bolt-pistol native (6 m) |
| **Realistic** | 450 m/s | 360 m | 3 m | x0.60 | 4 | tight clone (inner 1 m / outer 2 m) |

Both are **full-auto**. Arming is the outer blast radius + 1 m, so the round goes live
just past its own blast edge (7 m for Regular, 3 m for Realistic).

## Firing sound (optional, pick one)

Darktide, Space Marine 2, Boltgun, or Necromunda. Each is a full Wwise bank for
`content/audio/wep_jar5_dominator`, selected in Ordnance's option menu.

## Source

- Nexus Mods: <https://www.nexusmods.com/helldivers2/mods/18263>
- Ayaka: <https://ayakamods.com/mods/jar-5-dominator-rechambered.4317/>
- Repo: <https://github.com/Cavadus/dominator-rechamber>

## Known issues

The armory card still shows the stock Medium armour text; Heavy / Explosive is not
reflected there. There is no SAFE/UNSAFE ammo wheel — that was the old loader build.
