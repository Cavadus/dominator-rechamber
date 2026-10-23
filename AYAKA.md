# Ayaka listing copy

Page: https://ayakamods.com/mods/jar-5-dominator-rechambered.4317/
Short description: Rechamber the JAR-5 Dominator to the bolt pistol warhead. Manual install. No loader.
Version label: 2026.10.23

The current build is a post-EAC manual file swap. No Arsenal, no mod manager, no loader. The game must be closed. The installer downloads its own files. You do not need to clone anything.

Source and the same instructions: https://github.com/Cavadus/dominator-rechamber

WHAT IT DOES
Rechambers the JAR-5 Dominator to the P/40-K Bolt Pistol's explosive warhead. Two ballistic profiles. Optional firing sound. The impact graphic is the pistol's, confirmed in mission on 23 Oct 2026. The magazine in the gun stays 15 rounds.

REGULAR
Speed: 380 m/s, up from 180.
Range: 532 m. The rocket motor burns out and the round despawns.
Arming distance: 12 m.
Recoil: about 1.2x stock.
Spare magazines: 6.
Blast: the bolt pistol's. Full damage inside 1 m, falls off through 6 m, nothing at 7 m.

REALISTIC
Speed: 450 m/s. The game stores one speed, so this is the speed after the motor finishes, not the crawl at the muzzle.
Range: 360 m.
Arming distance: 15 m.
Recoil: 0.60x stock. Most of the push happens after the round has left.
Spare magazines: 4. Fifteen rounds are still in the gun.
Spread: +1 on both cones.
Blast: a private copy. Full damage inside 1 m, nothing past 2 m. The bolt pistol keeps its own wider blast.

FIRING SOUND
Pick one, or leave it stock. Darktide, Space Marine II, Boltgun, or Necromunda. The stat swap and the sound are independent. Install a profile, then a sound, or use the sound alone.

INSTALL, LINUX / MACOS
Interactive menu:
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash

Skip the menu:
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- install regular
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- install realistic
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- audio darktide
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- audio sm2
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- audio boltgun
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- audio necromunda
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- audio off
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- restore
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- status

If Steam is not in the default folder, set the game data dir first:
GAMEDIR="$HOME/.local/share/Steam/steamapps/common/Helldivers 2/data/game" curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash

INSTALL, WINDOWS POWERSHELL
irm does not pass arguments cleanly, so save the script and run it:
irm https://47th.info/hd2-mods/dominator-rechamber/rechamber.ps1 -OutFile "$env:TEMP\rechamber.ps1"
& "$env:TEMP\rechamber.ps1"

Skip the menu:
& "$env:TEMP\rechamber.ps1" install regular
& "$env:TEMP\rechamber.ps1" install realistic
& "$env:TEMP\rechamber.ps1" audio darktide
& "$env:TEMP\rechamber.ps1" audio sm2
& "$env:TEMP\rechamber.ps1" audio boltgun
& "$env:TEMP\rechamber.ps1" audio necromunda
& "$env:TEMP\rechamber.ps1" audio off
& "$env:TEMP\rechamber.ps1" restore
& "$env:TEMP\rechamber.ps1" status

If Steam is not in the default folder:
$env:GAMEDIR = "D:\Steam\steamapps\common\Helldivers 2\data\game"

RESTORE AND STATE
restore puts the original game files back.
status shows whether the files are stock or modified, and which firing sound is installed.
Linux/macOS state: ~/.local/share/dominator-rechamber/
Windows state: %LOCALAPPDATA%\dominator-rechamber\

SAFETY
The installer refuses to write a game file unless it is the stock file for build 26088801.
It backs stock up once and does not overwrite a good backup.
Every downloaded file is md5-checked before it is used.
If a game update changes the files, run Steam, Properties, Installed Files, Verify, then retry.

KNOWN ISSUES
The armory still shows the stock Medium text. The Heavy / Explosive tags are not on the card.
There is no full-auto, and no SAFE/UNSAFE wheel. Those belonged to the old loader build. They are not in this one.
