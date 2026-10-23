# JAR-5 Dominator Rechambered v4.0.0 — manual install

Rechambers the JAR-5 Dominator to the P/40-K Bolt Pistol's explosive gyrojet warhead.
No loader, no Arsenal, no mod manager — just a file swap you run yourself. Post-EAC safe.

The installer downloads its own payload. You do not need to clone the repo.

## One-line install (game CLOSED)

Linux / macOS — interactive menu:

```bash
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash
```

Or skip the menu:

```bash
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- install realistic
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- audio darktide
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- restore
curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- status
```

Windows (PowerShell) — same thing. `irm | iex` does not pass arguments cleanly, so save the script and run it:

```powershell
irm https://47th.info/hd2-mods/dominator-rechamber/rechamber.ps1 -OutFile "$env:TEMP\rechamber.ps1"
& "$env:TEMP\rechamber.ps1"
```

Skip the menu:

```powershell
& "$env:TEMP\rechamber.ps1" install realistic
& "$env:TEMP\rechamber.ps1" audio darktide
& "$env:TEMP\rechamber.ps1" restore
& "$env:TEMP\rechamber.ps1" status
```

If Steam is not in the default folder, set the game data dir first:

```bash
GAMEDIR="$HOME/.local/share/Steam/steamapps/common/Helldivers 2/data/game" curl -fsSL ... | bash
```

```powershell
$env:GAMEDIR = "D:\Steam\steamapps\common\Helldivers 2\data\game"
```

## What's here

```
rechamber.sh        Linux/macOS installer (also the curl target)
rechamber.ps1       Windows installer
regular/            Regular variant (380 m/s, 532 m, 12 m arming, recoil x1.20, 6 mags)
realistic/          Realistic variant (450 m/s, 360 m, 15 m arming, recoil x0.60, +1 spread, 4 mags, tight blast)
audio/              Firing-sound banks (darktide, sm2, boltgun, necromunda)
```

State (the stock backup, and which firing sound is installed) lives in:

- Linux/macOS: `~/.local/share/dominator-rechamber/`
- Windows: `%LOCALAPPDATA%\dominator-rechamber\`

## Firing sound (optional, pick one)

| Sound | Command |
|---|---|
| Darktide (Arsenal default) | `audio darktide` |
| Space Marine II (hot first shot) | `audio sm2` |
| Boltgun | `audio boltgun` |
| Necromunda | `audio necromunda` |
| Stock report | `audio off` |

Each bank is a full Wwise bank for `content/audio/wep_jar5_dominator`. The installer md5-checks it, verifies the Wwise resource type, removes any previously installed sound first, and drops the new bank one past the highest existing `9ba626afa44a3aa3.patch_N` slot.

The stat swap and the firing sound are independent. Install a variant, then pick a sound, or use the sound alone.

## From a local checkout

```bash
./rechamber.sh install realistic
./rechamber.sh audio darktide
./rechamber.sh status
./rechamber.sh restore
```

If the payload folders (`regular/`, `realistic/`, `audio/`) are next to the script, nothing is downloaded. Otherwise the script fetches them from `https://47th.info/hd2-mods/dominator-rechamber/`.

## Safety

The script fingerprint-checks every game file (md5) before touching it:

- Refuses to write unless the current file is exactly the stock version for build 26088801.
- Backs stock up once, and never overwrites a good backup.
- `restore` puts stock back from that backup.
- Every downloaded payload file is md5-checked before it is used.

If a game update changes the files, the script refuses until you run Steam → Properties → Installed Files → Verify, then retry.
