# JAR-5 Dominator Rechambered — manual swap (Windows / PowerShell). No loader, no Arsenal.
#
# One-line install (run in PowerShell, game CLOSED):
#   irm https://47th.info/hd2-mods/dominator-rechamber/rechamber.ps1 | iex
# then follow the prompts.
#
# Run as a saved file to pass args directly:
#   .\rechamber.ps1 install realistic     # or regular
#   .\rechamber.ps1 audio darktide        # or sm2 | boltgun | necromunda | off
#   .\rechamber.ps1 restore
#   .\rechamber.ps1 status
#
# The script downloads its own payload from BaseUrl when it is not sitting next to
# it (i.e. when piped via irm). State (stock backup, active sound) lives in StateDir.
param(
    [Parameter(Position=0)][string]$Action,
    [Parameter(Position=1)][string]$Variant
)

$ErrorActionPreference = 'Stop'
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$BaseUrl   = if ($env:BASE_URL)  { $env:BASE_URL }  else { 'https://47th.info/hd2-mods/dominator-rechamber' }
$StateDir  = if ($env:STATE_DIR) { $env:STATE_DIR } else { Join-Path $env:LOCALAPPDATA 'dominator-rechamber' }
$CacheDir  = Join-Path $StateDir 'cache'
$GameDir   = if ($env:GAMEDIR)  { $env:GAMEDIR }  else { Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\Helldivers 2\data\game' }
$DataDir   = if ($env:DATADIR)  { $env:DATADIR }  else { Split-Path -Parent $GameDir }
$BackupDir = Join-Path $StateDir 'stock-backup'
$AudioState = Join-Path $StateDir '.audio-state'

# Stock MD5 fingerprints (game build 26251122). Refuse to touch anything else.
$StockMd5 = @{
    'generated_projectile_settings.dl_bin' = '65b3de2ac65424fd6769ccbde09865b3'
    'generated_entities.dl_bin'              = '501cd6a9c7d7024fd8c42abe18e29ec7'
    'generated_explosion_settings.dl_bin'    = 'e218ea5d15451d63ccf1e607b1884d38'
    'generated_damage_settings.dl_bin'       = 'ccad374a99d3fb0ae85225d21d8d3ffa'
}

# Expected md5 of every payload file, keyed by its path under BaseUrl.
$ModMd5 = @{
    'regular/generated_projectile_settings.dl_bin'   = 'f9ec2dddc25191754213f2b4f700986b'
    'regular/generated_entities.dl_bin'              = 'b2bcfd06abfdf9db34b249fb8a73aa4d'
    'realistic/generated_projectile_settings.dl_bin' = '1e9481824c59ad4ae74c99d9492d29d5'
    'realistic/generated_entities.dl_bin'            = 'bc00b862f973c57e3850b278a970def1'
    'realistic/generated_explosion_settings.dl_bin'  = 'b4f518ab1306c12af045975f1d03c6d9'
    'audio/boltgun/9ba626afa44a3aa3.patch_0'         = 'c7534d3744fd56a76f7dd942fc74a643'
    'audio/darktide/9ba626afa44a3aa3.patch_0'        = '88f63d3a6688aa3b467cc62333cce88d'
    'audio/necromunda/9ba626afa44a3aa3.patch_0'      = '039612c157a2378eb2971caab43231de'
    'audio/sm2/9ba626afa44a3aa3.patch_0'             = '7d7036581222ff872203ae0d63d364e8'
}

# Firing-sound banks (Wwise, type 0x535a7bd3e650d799), keyed by variant.
$AudioMd5 = @{
    'darktide'   = '88f63d3a6688aa3b467cc62333cce88d'
    'sm2'        = '7d7036581222ff872203ae0d63d364e8'
    'boltgun'    = 'c7534d3744fd56a76f7dd942fc74a643'
    'necromunda' = '039612c157a2378eb2971caab43231de'
}
$AudioSlot = '9ba626afa44a3aa3'
$AudioType = '99d750e6d37b5a53'

function Get-Md5([string]$Path) {
    if (-not (Test-Path $Path)) { return $null }
    return (Get-FileHash -Path $Path -Algorithm MD5).Hash.ToLower()
}

# Get-Payload <relpath> — resolve a payload file to a local path, downloading from
# BaseUrl if it is not next to the script. Verifies md5 on download.
function Get-Payload([string]$Rel) {
    $local = Join-Path $ScriptDir $Rel
    if (Test-Path $local) { return $local }

    $dst = Join-Path $CacheDir $Rel
    $want = $ModMd5[$Rel]
    if ((Test-Path $dst) -and $want -and ((Get-Md5 $dst) -eq $want)) { return $dst }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Write-Host "[rechamber] downloading $Rel ..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "$BaseUrl/$Rel" -OutFile $dst -UseBasicParsing
    if ($want -and ((Get-Md5 $dst) -ne $want)) { throw "corrupt download: $Rel (md5 mismatch)" }
    return $dst
}

function Get-Files([string]$V) {
    $f = @('generated_projectile_settings.dl_bin', 'generated_entities.dl_bin')
    if ($V -eq 'realistic') { $f += 'generated_explosion_settings.dl_bin' }
    return $f
}

function Install-Rechamber([string]$Variant) {
    if (-not $Variant) { throw 'usage: install <regular|realistic>' }
    if (-not (Test-Path $GameDir)) { throw "game dir not found: $GameDir" }

    foreach ($f in (Get-Files $Variant)) {
        $rel = "$Variant/$f"
        $src = Get-Payload $rel
        if ((Get-Md5 $src) -ne $ModMd5[$rel]) { throw "bad payload: $rel" }
    }
    foreach ($f in (Get-Files $Variant)) {
        $cur = Join-Path $GameDir $f
        if (-not (Test-Path $cur)) { throw "game file missing: $cur (Steam Verify first)" }
        $curMd5 = Get-Md5 $cur
        $modMd5 = Get-Md5 (Get-Payload "$Variant/$f")
        if ($curMd5 -eq $modMd5) { continue }
        if ($curMd5 -ne $StockMd5[$f]) { throw "$f is neither stock nor ours (game update?). Run Steam Verify. md5=$curMd5" }
    }
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    foreach ($f in (Get-Files $Variant)) {
        $cur = Join-Path $GameDir $f
        $src = Get-Payload "$Variant/$f"
        $curMd5 = Get-Md5 $cur
        $modMd5 = Get-Md5 $src
        if ($curMd5 -eq $modMd5) { continue }
        $bk = Join-Path $BackupDir $f
        if ((-not (Test-Path $bk)) -or ((Get-Md5 $bk) -ne $StockMd5[$f])) { Copy-Item $cur $bk -Force }
        Copy-Item $src $cur -Force
        Write-Host "[rechamber] installed $f"
    }
    Write-Host '[rechamber] done — launch the game'
}

function Restore-Rechamber {
    if (-not (Test-Path $BackupDir)) { throw 'no backup found (nothing to restore)' }
    foreach ($f in @('generated_projectile_settings.dl_bin','generated_entities.dl_bin','generated_explosion_settings.dl_bin','generated_damage_settings.dl_bin')) {
        $bk = Join-Path $BackupDir $f
        if (-not (Test-Path $bk)) { continue }
        $cur = Join-Path $GameDir $f
        if ((Get-Md5 $cur) -ne (Get-Md5 $bk)) { Copy-Item $bk $cur -Force; Write-Host "[rechamber] restored $f" }
    }
    Write-Host '[rechamber] done — stock files restored'
}

function Show-Status {
    foreach ($f in @('generated_projectile_settings.dl_bin','generated_entities.dl_bin','generated_explosion_settings.dl_bin','generated_damage_settings.dl_bin')) {
        $md = Get-Md5 (Join-Path $GameDir $f)
        if ($null -eq $md) { Write-Host "${f}: MISSING" }
        elseif ($md -eq $StockMd5[$f]) { Write-Host "${f}: STOCK" }
        else { Write-Host "${f}: MODIFIED ($md)" }
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
}

function Audio-Install([string]$Variant) {
    if (-not $Variant) { throw 'usage: audio <darktide|sm2|boltgun|necromunda|off>' }
    if (-not $AudioMd5.ContainsKey($Variant)) { throw "unknown sound: $Variant (darktide|sm2|boltgun|necromunda|off)" }
    if (-not (Test-Path $DataDir)) { throw "data dir not found: $DataDir" }

    $src = Get-Payload "audio/$Variant/$AudioSlot.patch_0"
    if ((Get-Md5 $src) -ne $AudioMd5[$Variant]) { throw "bank $Variant is corrupt (md5 mismatch)" }

    Audio-Off

    $n = Get-NextFreeAudioSlot
    $dst = Join-Path $DataDir "$AudioSlot.patch_$n"
    Copy-Item $src $dst -Force
    "$AudioSlot.patch_$n" | Out-File -FilePath $AudioState -Encoding ascii
    Write-Host "[rechamber] firing sound set to $Variant (installed $AudioSlot.patch_$n)"
}

function Prompt-Variant {
    Write-Host '  Ballistics variant:'
    Write-Host '    1) regular   (380 m/s, 532 m, recoil x1.20, 6 mags)'
    Write-Host '    2) realistic (450 m/s, 360 m, recoil x0.60, +1 spread, 4 mags)'
    while ($true) {
        $n = Read-Host '  choice [1/2]'
        if ($n -eq '1') { return 'regular' }
        if ($n -eq '2') { return 'realistic' }
    }
}

function Prompt-Sound {
    Write-Host '  Firing sound:'
    Write-Host '    1) darktide (default)   2) sm2   3) boltgun   4) necromunda   5) off'
    while ($true) {
        $n = Read-Host '  choice [1-5]'
        if ($n -eq '1') { return 'darktide' }
        if ($n -eq '2') { return 'sm2' }
        if ($n -eq '3') { return 'boltgun' }
        if ($n -eq '4') { return 'necromunda' }
        if ($n -eq '5') { return 'off' }
    }
}

$act = $Action
if (-not $act) {
    Write-Host ''
    Write-Host '  JAR-5 Dominator Rechambered — installer'
    Write-Host '  --------------------------------------'
    Write-Host '  1) install a ballistics variant'
    Write-Host '  2) set firing sound'
    Write-Host '  3) restore stock'
    Write-Host '  4) status'
    while ($true) {
        $n = Read-Host '  choice [1-4]'
        if ($n -eq '1') { $act = 'install'; break }
        if ($n -eq '2') { $act = 'audio'; break }
        if ($n -eq '3') { $act = 'restore'; break }
        if ($n -eq '4') { $act = 'status'; break }
    }
}

switch ($act) {
    'install' {
        $v = $Variant
        if (-not $v) { $v = Prompt-Variant }
        Install-Rechamber $v
    }
    'audio' {
        $s = $Variant
        if (-not $s) { $s = Prompt-Sound }
        if ($s -eq 'off') { Audio-Off; Write-Host '[rechamber] done — stock firing sound restored' }
        else { Audio-Install $s }
    }
    'restore' { Restore-Rechamber }
    'status'  { Show-Status }
    default   { Write-Host 'usage: rechamber.ps1 <install <regular|realistic>|audio <sound|off>|restore|status>' }
}
