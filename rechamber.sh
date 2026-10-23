#!/usr/bin/env bash
# JAR-5 Dominator Rechambered — manual swap (no loader, no Arsenal).
# Usage:
#   ./rechamber.sh install <regular|realistic>   swap modded files in (backup first)
#   ./rechamber.sh audio <darktide|sm2|boltgun|necromunda>   set the firing sound
#   ./rechamber.sh audio off                     restore the stock firing sound
#   ./rechamber.sh restore                        put stock files back
#   ./rechamber.sh status                         show current state
#
# The game must be CLOSED when you run this.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAMEDIR="${GAMEDIR:-$HOME/.local/share/Steam/steamapps/common/Helldivers 2/data/game}"
DATADIR="${DATADIR:-$(dirname "$GAMEDIR")}"   # .../Helldivers 2/data — resource patches live here
BACKUPDIR="$SCRIPT_DIR/stock-backup"
AUDIO_STATE="$SCRIPT_DIR/.audio-state"

# Stock md5 fingerprints (game build 26088801). Refuse to touch anything else.
declare -A STOCK_MD5=(
  [generated_projectile_settings.dl_bin]=fa3492533784d2af45d7d8f81748a5a4
  [generated_entities.dl_bin]=fecf622cff80bea7456c797b9820028e
  [generated_explosion_settings.dl_bin]=4b239877910a43a3e520cca8eb67354f
  [generated_damage_settings.dl_bin]=d274494df64e8476ed8f1b136c5e3750
)

# Firing-sound banks. Each is a full Wwise bank for content/audio/wep_jar5_dominator,
# resource type 0x535a7bd3e650d799 (bytes @0x50 = 99d750e6d37b5a53). They deploy as a
# standalone resource patch in data/ (NOT a .dl_bin swap) and the game prefers the
# newer slot for that bank name. md5 guards each bank so a wrong file never ships.
declare -A AUDIO_MD5=(
  [darktide]=a99dd188ea578db9b16e9b4160bacc20
  [sm2]=b28b01d84cf3f453aaa6eb25dae902ad
  [boltgun]=99e150d4dec70bf9923ec553239f2984
  [necromunda]=ddc98df8d595b9ef0ea3aba8ce1149ef
)
AUDIO_SLOT="9ba626afa44a3aa3"
AUDIO_TYPE="99d750e6d37b5a53"

log()  { echo "[rechamber] $*"; }
die()  { echo "[rechamber] ERROR: $*" >&2; exit 1; }
md5_of() { md5sum "$1" 2>/dev/null | cut -d' ' -f1; }

files_for_variant() {
  echo generated_projectile_settings.dl_bin
  echo generated_entities.dl_bin
  echo generated_damage_settings.dl_bin
  [ "$1" = realistic ] && echo generated_explosion_settings.dl_bin
}

install() {
  local variant="${1:-}"
  [ -n "$variant" ] || die "usage: install <regular|realistic>"
  [ -d "$GAMEDIR" ] || die "game dir not found: $GAMEDIR (set GAMEDIR=...)"

  local f
  for f in $(files_for_variant "$variant"); do
    [ -f "$SCRIPT_DIR/$variant/$f" ] || die "missing modded file: $SCRIPT_DIR/$variant/$f"
  done

  for f in $(files_for_variant "$variant"); do
    local cur="$GAMEDIR/$f"
    [ -f "$cur" ] || die "game file missing: $cur (Steam Verify first)"
    local curmd="$(md5_of "$cur")"
    local modmd="$(md5_of "$SCRIPT_DIR/$variant/$f")"
    if [ "$curmd" = "$modmd" ]; then log "$f already modded"; continue; fi
    if [ "$curmd" != "${STOCK_MD5[$f]}" ]; then
      die "$f is neither stock nor ours (game update? another mod?). Run Steam Verify. md5=$curmd"
    fi
  done

  mkdir -p "$BACKUPDIR"
  for f in $(files_for_variant "$variant"); do
    local cur="$GAMEDIR/$f"
    local curmd="$(md5_of "$cur")"
    local modmd="$(md5_of "$SCRIPT_DIR/$variant/$f")"
    [ "$curmd" = "$modmd" ] && continue
    if [ ! -f "$BACKUPDIR/$f" ] || [ "$(md5_of "$BACKUPDIR/$f")" != "${STOCK_MD5[$f]}" ]; then
      cp "$cur" "$BACKUPDIR/$f" || die "backup failed for $f"
    fi
    cp "$SCRIPT_DIR/$variant/$f" "$cur" || die "install failed for $f"
    log "installed $f"
  done
  log "done — launch the game"
}

restore() {
  [ -d "$BACKUPDIR" ] || die "no backup found (nothing to restore)"
  local f
  for f in generated_projectile_settings.dl_bin generated_entities.dl_bin generated_explosion_settings.dl_bin generated_damage_settings.dl_bin; do
    [ -f "$BACKUPDIR/$f" ] || continue
    local cur="$GAMEDIR/$f"
    if [ "$(md5_of "$cur")" != "$(md5_of "$BACKUPDIR/$f")" ]; then
      cp "$BACKUPDIR/$f" "$cur" || die "restore failed for $f"
      log "restored $f"
    fi
  done
  log "done — stock files restored"
}

status() {
  local f
  for f in generated_projectile_settings.dl_bin generated_entities.dl_bin generated_explosion_settings.dl_bin generated_damage_settings.dl_bin; do
    local curmd="$(md5_of "$GAMEDIR/$f")"
    case "$curmd" in
      "${STOCK_MD5[$f]}") echo "$f: STOCK" ;;
      "") echo "$f: MISSING" ;;
      *) echo "$f: MODIFIED ($curmd)" ;;
    esac
  done
  if [ -f "$AUDIO_STATE" ]; then
    echo "firing sound: $(cat "$AUDIO_STATE")"
  else
    echo "firing sound: STOCK"
  fi
}

# --- firing sound (Wwise resource patch) ---

# One past the highest existing patch_N (HD2 merges by type; later patch wins).
next_free_audio_slot() {
  local max=0 f base
  for f in "$DATADIR/${AUDIO_SLOT}.patch_"*; do
    [ -e "$f" ] || continue
    base="${f##*patch_}"
    case "$base" in *[!0-9]*) continue ;; esac   # skip .stream / .gpu_resources
    [ "$base" -gt "$max" ] && max="$base"
  done
  echo $((max + 1))
}

audio_off() {
  if [ -f "$AUDIO_STATE" ]; then
    local slot="$(cat "$AUDIO_STATE")"
    local f="$DATADIR/$slot"
    if [ -f "$f" ]; then rm -f "$f" && log "removed $slot"; fi
    rm -f "$AUDIO_STATE"
    return 0
  fi
  return 1
}

audio_install() {
  local variant="${1:-}"
  [ -n "$variant" ] || die "usage: audio <darktide|sm2|boltgun|necromunda|off>"
  [ "${AUDIO_MD5[$variant]:-}" ] || die "unknown sound: $variant (darktide|sm2|boltgun|necromunda|off)"
  [ -d "$DATADIR" ] || die "data dir not found: $DATADIR (set DATADIR=...)"

  local src="$SCRIPT_DIR/audio/$variant/${AUDIO_SLOT}.patch_0"
  [ -f "$src" ] || die "missing bank: $src"

  local srcmd="$(md5_of "$src")"
  [ "$srcmd" = "${AUDIO_MD5[$variant]}" ] || die "bank $variant is corrupt (md5=$srcmd)"
  local tb="$(xxd -s 0x50 -l 8 -p "$src" 2>/dev/null)"
  [ "$tb" = "$AUDIO_TYPE" ] || die "bank $variant has wrong type @0x50=$tb (not Wwise)"

  audio_off

  local n="$(next_free_audio_slot)"
  local dst="$DATADIR/${AUDIO_SLOT}.patch_$n"
  cp "$src" "$dst" || die "copy failed for $dst"
  echo "${AUDIO_SLOT}.patch_$n" > "$AUDIO_STATE"
  log "firing sound set to $variant (installed ${AUDIO_SLOT}.patch_$n)"
}

case "${1:-}" in
  install) install "${2:-}" ;;
  audio)   case "${2:-}" in
             off) if audio_off; then log "done — stock firing sound restored"; else log "done — no firing sound was installed"; fi ;;
             "")  die "usage: audio <darktide|sm2|boltgun|necromunda|off>" ;;
             *)   audio_install "${2:-}" ;;
           esac ;;
  restore) restore ;;
  status) status ;;
  *) echo "usage: $0 <install <regular|realistic>|audio <sound|off>|restore|status>"; exit 1 ;;
esac
