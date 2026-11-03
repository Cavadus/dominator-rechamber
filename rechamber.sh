#!/usr/bin/env bash
# JAR-5 Dominator Rechambered — manual swap (no loader, no Arsenal).
#
# One-line install (Linux/macOS), game CLOSED:
#   curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash
# With a specific choice:
#   curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- install realistic
#   curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- audio darktide
#   curl -fsSL https://47th.info/hd2-mods/dominator-rechamber/rechamber.sh | bash -s -- restore
#
# The script downloads its own payload from BASE_URL when it is not sitting next to
# it (i.e. when piped via curl). State (stock backup, active sound) lives in STATE_DIR.
set -u

BASE_URL="${BASE_URL:-https://47th.info/hd2-mods/dominator-rechamber}"
STATE_DIR="${STATE_DIR:-$HOME/.local/share/dominator-rechamber}"
CACHE_DIR="${CACHE_DIR:-$STATE_DIR/cache}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAMEDIR="${GAMEDIR:-$HOME/.local/share/Steam/steamapps/common/Helldivers 2/data/game}"
DATADIR="${DATADIR:-$(dirname "$GAMEDIR")}"   # .../Helldivers 2/data — resource patches live here
BACKUPDIR="$STATE_DIR/stock-backup"
AUDIO_STATE="$STATE_DIR/.audio-state"

# Stock md5 fingerprints (game build 26251122). Refuse to touch anything else.
declare -A STOCK_MD5=(
  [generated_projectile_settings.dl_bin]=65b3de2ac65424fd6769ccbde09865b3
  [generated_entities.dl_bin]=501cd6a9c7d7024fd8c42abe18e29ec7
  [generated_explosion_settings.dl_bin]=e218ea5d15451d63ccf1e607b1884d38
  [generated_damage_settings.dl_bin]=ccad374a99d3fb0ae85225d21d8d3ffa
)

# Expected md5 of every payload file, keyed by its path under BASE_URL. A downloaded
# file that does not match is refused, so a corrupt/partial download never installs.
declare -A MOD_MD5=(
  [regular/generated_projectile_settings.dl_bin]=f9ec2dddc25191754213f2b4f700986b
  [regular/generated_entities.dl_bin]=b2bcfd06abfdf9db34b249fb8a73aa4d
  [realistic/generated_projectile_settings.dl_bin]=1e9481824c59ad4ae74c99d9492d29d5
  [realistic/generated_entities.dl_bin]=bc00b862f973c57e3850b278a970def1
  [realistic/generated_explosion_settings.dl_bin]=b4f518ab1306c12af045975f1d03c6d9
  [audio/boltgun/9ba626afa44a3aa3.patch_0]=216b992676c3aae91d6ae2d92fe21974
  [audio/darktide/9ba626afa44a3aa3.patch_0]=d341fd2a589ca39c419a55c432134ad8
  [audio/necromunda/9ba626afa44a3aa3.patch_0]=9d4bcfc79ff763849cd720d4fa425360
  [audio/sm2/9ba626afa44a3aa3.patch_0]=134fb85f4e1cda4d2b1df6422e13a747
)

# Firing-sound banks (Wwise, type 0x535a7bd3e650d799) — deployed as a standalone
# resource patch in data/. Each bank's md5 is verified before it ships.
declare -A AUDIO_MD5=(
  [darktide]=d341fd2a589ca39c419a55c432134ad8
  [sm2]=134fb85f4e1cda4d2b1df6422e13a747
  [boltgun]=216b992676c3aae91d6ae2d92fe21974
  [necromunda]=9d4bcfc79ff763849cd720d4fa425360
)
AUDIO_SLOT="9ba626afa44a3aa3"
AUDIO_TYPE="99d750e6d37b5a53"

log()  { echo "[rechamber] $*"; }
die()  { echo "[rechamber] ERROR: $*" >&2; exit 1; }
md5_of() { md5sum "$1" 2>/dev/null | cut -d' ' -f1; }

# payload <relpath> — resolve a payload file to a local path, downloading it from
# BASE_URL if it is not next to the script (piped install). Verifies md5 on download.
payload() {
  local rel="$1"
  local local_f="$SCRIPT_DIR/$rel"
  [ -f "$local_f" ] && { echo "$local_f"; return; }

  command -v curl >/dev/null 2>&1 || die "curl is required (or set BASE_URL to a local dir and place files there)"

  local dst="$CACHE_DIR/$rel"
  local want="${MOD_MD5[$rel]:-}"
  [ -f "$dst" ] && [ -n "$want" ] && [ "$(md5_of "$dst")" = "$want" ] && { echo "$dst"; return; }

  mkdir -p "$(dirname "$dst")"
  echo "[rechamber] downloading $rel ..." >&2
  curl -fsSL --retry 3 "$BASE_URL/$rel" -o "$dst" || die "download failed: $BASE_URL/$rel"
  [ -n "$want" ] && [ "$(md5_of "$dst")" != "$want" ] && die "corrupt download: $rel (md5 mismatch)"
  echo "$dst"
}

files_for_variant() {
  echo generated_projectile_settings.dl_bin
  echo generated_entities.dl_bin
  [ "$1" = realistic ] && echo generated_explosion_settings.dl_bin
}

install() {
  local variant="${1:-}"
  [ -n "$variant" ] || die "usage: install <regular|realistic>"
  [ -d "$GAMEDIR" ] || die "game dir not found: $GAMEDIR (set GAMEDIR=...)"

  local f rel src
  for f in $(files_for_variant "$variant"); do
    rel="$variant/$f"
    src="$(payload "$rel")" || die "missing modded file: $rel"
    [ "$(md5_of "$src")" = "${MOD_MD5[$rel]}" ] || die "bad payload: $rel"
  done

  for f in $(files_for_variant "$variant"); do
    local cur="$GAMEDIR/$f"
    [ -f "$cur" ] || die "game file missing: $cur (Steam Verify first)"
    local curmd="$(md5_of "$cur")"
    local modmd="$(md5_of "$(payload "$variant/$f")")"
    if [ "$curmd" = "$modmd" ]; then log "$f already modded"; continue; fi
    if [ "$curmd" != "${STOCK_MD5[$f]}" ]; then
      die "$f is neither stock nor ours (game update? another mod?). Run Steam Verify. md5=$curmd"
    fi
  done

  mkdir -p "$BACKUPDIR"
  for f in $(files_for_variant "$variant"); do
    local cur="$GAMEDIR/$f"
    local curmd="$(md5_of "$cur")"
    local src="$(payload "$variant/$f")"
    local modmd="$(md5_of "$src")"
    [ "$curmd" = "$modmd" ] && continue
    if [ ! -f "$BACKUPDIR/$f" ] || [ "$(md5_of "$BACKUPDIR/$f")" != "${STOCK_MD5[$f]}" ]; then
      cp "$cur" "$BACKUPDIR/$f" || die "backup failed for $f"
    fi
    cp "$src" "$cur" || die "install failed for $f"
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

next_free_audio_slot() {
  local max=0 f base
  for f in "$DATADIR/${AUDIO_SLOT}.patch_"*; do
    [ -e "$f" ] || continue
    base="${f##*patch_}"
    case "$base" in *[!0-9]*) continue ;; esac
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

  local src="$(payload "audio/$variant/${AUDIO_SLOT}.patch_0")"
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

prompt_variant() {
  local n=""
  echo "  Ballistics variant:"
  echo "    1) regular   (380 m/s, 532 m, recoil x1.20, 6 mags)"
  echo "    2) realistic (450 m/s, 360 m, recoil x0.60, +1 spread, 4 mags)"
  while [ "$n" != "1" ] && [ "$n" != "2" ]; do
    printf "  choice [1/2]: "; read -r n < /dev/tty || true
  done
  [ "$n" = "1" ] && echo regular || echo realistic
}

prompt_sound() {
  local n=""
  echo "  Firing sound:"
  echo "    1) darktide (default)   2) sm2   3) boltgun   4) necromunda   5) off"
  while :; do
    printf "  choice [1-5]: "; read -r n < /dev/tty || true
    case "$n" in 1) echo darktide; return;; 2) echo sm2; return;; 3) echo boltgun; return;; 4) echo necromunda; return;; 5) echo off; return;; esac
  done
}

action="${1:-}"

if [ -z "$action" ]; then
  echo ""
  echo "  JAR-5 Dominator Rechambered — installer"
  echo "  --------------------------------------"
  echo "  1) install a ballistics variant"
  echo "  2) set firing sound"
  echo "  3) restore stock"
  echo "  4) status"
  n=""
  while :; do
    printf "  choice [1-4]: "; read -r n < /dev/tty || true
    case "$n" in 1) action=install; break;; 2) action=audio; break;; 3) action=restore; break;; 4) action=status; break;; esac
  done
fi

case "$action" in
  install)
    v="${2:-}"
    [ -n "$v" ] || v="$(prompt_variant)"
    install "$v" ;;
  audio)
    s="${2:-}"
    [ -n "$s" ] || s="$(prompt_sound)"
    case "$s" in off) audio_off && log "done — stock firing sound restored" || log "done — no firing sound was installed" ;; *) audio_install "$s" ;; esac ;;
  restore) restore ;;
  status) status ;;
  *) echo "usage: $0 <install <regular|realistic>|audio <sound|off>|restore|status>"; exit 1 ;;
esac
