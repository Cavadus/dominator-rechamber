# JAR-5 Dominator Rechambered — manual install

Rechambers the JAR-5 Dominator to the P/40-K Bolt Pistol's explosive gyrojet warhead.
No loader, no Arsenal, no mod manager — just a file swap you run yourself. Post-EAC safe.

## What's here

```
rechamber.sh        Linux/macOS install script
rechamber.ps1       Windows (PowerShell) install script
regular/            Regular variant (380 m/s, 532 m, 12 m arming, recoil x1.20, 6 mags)
realistic/          Realistic variant (450 m/s, 360 m, 15 m arming, recoil x0.60, +1 spread, 4 mags, tight blast)
audio/              Firing-sound banks (darktide, sm2, boltgun, necromunda)
stock-backup/       created on first install — holds your original files
```

## Install (game CLOSED)

Linux/macOS:
```bash
cd ~/clawd/hd2-mods/dominator-rechamber
./rechamber.sh install realistic     # or regular
```

Windows (PowerShell, run from the folder):
```powershell
.\rechamber.ps1 install realistic    # or regular
```

Launch the game. The Dominator now fires the bolt-pistol explosive gyrojet.

## Firing sound (optional, pick one)

Four bolter firing-sound banks are bundled. They install as a standalone Wwise resource
patch (type `0x535a7bd3e650d799`) in the game's `data/` dir — a different mechanism from the
stat swap, so the two coexist and can be used together or separately.

Linux/macOS:
```bash
./rechamber.sh audio darktide       # or sm2 | boltgun | necromunda
./rechamber.sh audio off            # back to the stock report
```

Windows (PowerShell):
```powershell
.\rechamber.ps1 audio darktide      # or sm2 | boltgun | necromunda
.\rechamber.ps1 audio off
```

| Sound | Folder |
|---|---|
| Darktide (default in the Arsenal mod) | `audio/darktide` |
| Space Marine II (hot first shot) | `audio/sm2` |
| Boltgun | `audio/boltgun` |
| Necromunda | `audio/necromunda` |

Each bank is a full Wwise bank for `content/audio/wep_jar5_dominator`. The script
md5-checks the bank and verifies its resource type before writing, removes any previously
installed sound first (so two banks never stack), and drops the new bank at one past the
highest existing `9ba626afa44a3aa3.patch_N` slot so the game prefers it over the vanilla bank.

## Restore stock

```bash
./rechamber.sh restore               # Linux (stat files)
./rechamber.sh audio off             # Linux (firing sound)
.\rechamber.ps1 restore              # Windows
.\rechamber.ps1 audio off            # Windows
```

## Check state

```bash
./rechamber.sh status                # Linux — shows both stat files and firing sound
.\rechamber.ps1 status               # Windows
```

## Safety

The script fingerprint-checks every file (md5) before touching it:
- Refuses to write unless the current file is exactly the stock version.
- Backs stock up to `stock-backup/` once, never overwrites a good backup.
- `restore` puts stock back from that backup.
- The firing-sound bank is md5-checked and its Wwise resource type is verified before deploy.

If a game update changes the files, the script refuses to install until you run
Steam > Properties > Installed Files > Verify, then retry.

## Notes

- The two variants (regular vs realistic) are mutually exclusive — install one.
- The firing sound is independent of the variant; pick it after (or without) the stat install.
- Steam cloud may re-verify files after a crash; re-run `install` if `status` shows STOCK.
