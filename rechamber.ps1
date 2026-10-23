# JAR-5 Dominator Rechambered — manual swap (Windows / PowerShell). No loader, no Arsenal.
# Usage (run from this folder, game CLOSED):
#   .\rechamber.ps1 install realistic     # or regular
#   .\rechamber.ps1 audio darktide        # or sm2 | boltgun | necromunda | off
#   .\rechamber.ps1 restore
#   .\rechamber.ps1 status
#
# If Steam is installed elsewhere, override with: $env:GAMEDIR="...\data\game"
param(
    [Parameter(Position=0)][string]$Action,
    [Parameter(Position=1)][string]$Variant
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$GameDir = if ($env:GAMEDIR) { $env:GAMEDIR } else { "$env:ProgramFiles(x86)\Steam\steamapps\common\Helldivers 2\data\game" }
$DataDir = if ($env:DATADIR) { $env:DATADIR } else { Split-Path -Parent $GameDir }
$BackupDir = Join-Path $ScriptDir 'stock-backup'
$AudioState = Join-Path $ScriptDir '.audio-state'

# Stock MD5 fingerprints (game build 26088801). Refuse to touch anything else.
$StockMd5 = @{
    'generated_projectile_settings.dl_bin' = 'fa3492533784d2af45d7d8f81748a5a4'
    'generated_entities.dl_bin'              = 'fecf622cff80bea7456c797b9820028e'
    'generated_explosion_settings.dl_bin'    = '4b239877910a43a3e520cca8eb67354f'
    'generated_damage_settings.dl_bin'       = 'd274494df64e8476ed8f1b136c5e3750'
}

# Firing-sound banks (Wwise, type 0x535a7bd3e650d799). Deployed as a standalone
# resource patch in data/ (NOT a .dl_bin swap).
$AudioMd5 = @{
    'darktide'   = 'a99dd188ea578db9b16e9b4160bacc20'
    'sm2'        = 'b28b01d84cf3f453aaa6eb25dae902ad'
    'boltgun'    = '99e150d4dec70bf9923ec553239f2984'
    'necromunda' = 'ddc98df8d595b9ef0ea3aba8ce1149ef'
}
$AudioSlot = '9ba626afa44a3aa3'

function Get-Md5([string]$Path) {
    if (-not (Test-Path $Path)) { return $null }
    return (Get-FileHash -Path $Path -Algorithm MD5).Hash.ToLower()
}

function Get-Files([string]$V) {
    $f = @('generated_projectile_settings.dl_bin', 'generated_entities.dl_bin', 'generated_damage_settings.dl_bin')
    if ($V -eq 'realistic') { $f += 'generated_explosion_settings.dl_bin' }
    return $f
}

function Install-Rechamber([string]$Variant) {
    if (-not $Variant) { Write-Error 'usage: install <regular|realistic>'; return }
    if (-not (Test-Path $GameDir)) { Write-Error "game dir not found: $GameDir (set `$env:GAMEDIR)"; return }
    foreach ($f in (Get-Files $Variant)) {
        $mod = Join-Path (Join-Path $ScriptDir $Variant) $f
        if (-not (Test-Path $mod)) { Write-Error "missing modded file: $mod"; return }
    }
    foreach ($f in (Get-Files $Variant)) {
        $cur = Join-Path $GameDir $f
        if (-not (Test-Path $cur)) { Write-Error "game file missing: $cur (Steam Verify first)"; return }
        $curMd5 = Get-Md5 $cur
        $modMd5 = Get-Md5 (Join-Path (Join-Path $ScriptDir $Variant) $f)
        if ($curMd5 -eq $modMd5) { continue }
        if ($curMd5 -ne $StockMd5[$f]) {
            Write-Error "$f is neither stock nor ours (game update?). Run Steam Verify. md5=$curMd5"
            return
        }
    }
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    foreach ($f in (Get-Files $Variant)) {
        $cur = Join-Path $GameDir $f
        $mod = Join-Path (Join-Path $ScriptDir $Variant) $f
        $curMd5 = Get-Md5 $cur
        $modMd5 = Get-Md5 $mod
        if ($curMd5 -eq $modMd5) { continue }
        $bk = Join-Path $BackupDir $f
        if ((-not (Test-Path $bk)) -or ((Get-Md5 $bk) -ne $StockMd5[$f])) {
            Copy-Item $cur $bk -Force
        }
        Copy-Item $mod $cur -Force
        Write-Host "[rechamber] installed $f"
    }
    Write-Host '[rechamber] done — launch the game'
}

function Restore-Rechamber {
    if (-not (Test-Path $BackupDir)) { Write-Error 'no backup found'; return }
    foreach ($f in @('generated_projectile_settings.dl_bin','generated_entities.dl_bin','generated_explosion_settings.dl_bin','generated_damage_settings.dl_bin')) {
        $bk = Join-Path $BackupDir $f
        if (-not (Test-Path $bk)) { continue }
        $cur = Join-Path $GameDir $f
        if ((Get-Md5 $cur) -ne (Get-Md5 $bk)) {
            Copy-Item $bk $cur -Force
            Write-Host "[rechamber] restored $f"
        }
    }
    Write-Host '[rechamber] done — stock files restored'
}

function Show-Status {
    foreach ($f in @('generated_projectile_settings.dl_bin','generated_entities.dl_bin','generated_explosion_settings.dl_bin','generated_damage_settings.dl_bin')) {
        $md = Get-Md5 (Join-Path $GameDir $f)
        if ($null -eq $md) { Write-Host "$f: MISSING" }
        elseif ($md -eq $StockMd5[$f]) { Write-Host "$f: STOCK" }
        else { Write-Host "$f: MODIFIED ($md)" }
    }
    if (Test-Path $AudioState) { Write-Host "firing sound: $(Get-Content $AudioState)" }
    else { Write-Host 'firing sound: STOCK' }
}

function Get-NextFreeAudioSlot {
    $n = 0
    while (Test-Path (Join-Path $DataDir "$AudioSlot.patch_$n")) { $n++ }
    return $n
}

function Audio-Off {
    if (Test-Path $AudioState) {
        $slot = (Get-Content $AudioState).Trim()
        $f = Join-Path $DataDir $slot
        if (Test-Path $f) { Remove-Item $f -Force; Write-Host "[rechamber] removed $slot" }
        Remove-Item $AudioState -Force -ErrorAction SilentlyContinue
    }
    Write-Host '[rechamber] done — stock firing sound restored'
}

function Audio-Install([string]$Variant) {
    if (-not $Variant) { Write-Error 'usage: audio <darktide|sm2|boltgun|necromunda|off>'; return }
    if (-not $AudioMd5.ContainsKey($Variant)) { Write-Error "unknown sound: $Variant (darktide|sm2|boltgun|necromunda|off)"; return }
    if (-not (Test-Path $DataDir)) { Write-Error "data dir not found: $DataDir (set `$env:DATADIR)"; return }

    $src = Join-Path (Join-Path (Join-Path $ScriptDir 'audio') $Variant) "$AudioSlot.patch_0"
    if (-not (Test-Path $src)) { Write-Error "missing bank: $src"; return }

    $srcMd5 = Get-Md5 $src
    if ($srcMd5 -ne $AudioMd5[$Variant]) { Write-Error "bank $Variant is corrupt (md5=$srcMd5)"; return }

    Audio-Off

    $n = Get-NextFreeAudioSlot
    $dst = Join-Path $DataDir "$AudioSlot.patch_$n"
    Copy-Item $src $dst -Force
    "$AudioSlot.patch_$n" | Out-File -FilePath $AudioState -Encoding ascii
    Write-Host "[rechamber] firing sound set to $Variant (installed $AudioSlot.patch_$n)"
}

switch ($Action) {
    'install' { Install-Rechamber $Variant }
    'audio'   { if ($Variant -eq 'off') { Audio-Off } else { Audio-Install $Variant } }
    'restore' { Restore-Rechamber }
    'status'  { Show-Status }
    default   { Write-Host 'usage: .echamber.ps1 <install <regular|realistic>|audio <sound|off>|restore|status>' }
}
