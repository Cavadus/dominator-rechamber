# Ayaka listing copy

Page: https://ayakamods.com/mods/jar-5-dominator-rechambered.4317/
Version label: 2026.10.23
Icon: thumbnail.png

UPDATE 23 OCT 26:
Post-EAC rebuild. The loader is gone. This is a manual file swap. The impact graphic is fixed. The armory still shows the stock Medium text. There is no full-auto in this build.

JAR-5 Dominator: Rechambered

Ministry of Defense — Procurement Notice

The Ministry of Defense has authorized a field conversion for the JAR-5 Dominator, reconditioning the rifle's chamber to accept the explosive gyrojet cartridges developed for the P/40-K sidearm. The stock 15×100mm round hit hard and did not break the armor now in the field. This conversion fits the pistol's rocket-propelled high-explosive warhead behind a hotter gyrojet motor.

Managed Democracy demands overwhelming firepower. This conversion ensures it.

— Ministry of Defense, Office of Armaments

What this mod does

Rechambers the JAR-5 Dominator to the P/40-K Bolt Pistol's explosive warhead. Two ballistics profiles. Optional firing sound. No Arsenal, no mod manager, no loader. The game must be closed.

Install, Linux / macOS:

curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash

Install, Windows PowerShell:

irm https://47th.info/hd2-mods/dominator-rechamber/rechamber.ps1 -OutFile "$env:TEMP\rechamber.ps1"
& "$env:TEMP\rechamber.ps1"

Shared, either profile:

- Bolt pistol explosive warhead. Impact graphic confirmed in mission on 23 Oct 2026.
- Magazine in the gun stays 15 rounds.
- Firing sound, pick one: Darktide, Space Marine II, Boltgun, Necromunda, or leave it stock.
- Restore puts the original files back.

Regular:

- Speed: 380 m/s, up from 180.
- Range: 532 m. The rocket motor burns out and the round despawns.
- Arming distance: 12 m.
- Recoil: about 1.2× stock.
- Spare magazines: 6.
- Blast: the bolt pistol's. Full damage inside 1 m, falls off through 6 m, nothing at 7 m.

Realistic:

- Speed: 450 m/s. The game stores one speed, so this is the speed after the motor finishes, not the crawl at the muzzle.
- Range: 360 m.
- Arming distance: 15 m.
- Recoil: 0.60× stock. Most of the push happens after the round has left.
- Spare magazines: 4. Fifteen rounds are still in the gun.
- Spread: +1 on both cones.
- Blast: a private copy. Full damage inside 1 m, nothing past 2 m. The bolt pistol keeps its own wider blast. The impact graphic is the pistol's.

Known issues:

- The armory still shows the stock Medium text. The Heavy / Explosive tags are not on the card.
- There is no full-auto, and no SAFE/UNSAFE wheel. Those belonged to the old loader build. They are not in this one.
