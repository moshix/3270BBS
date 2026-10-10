#!/usr/bin/env bash
# copyright 2025, 2026 by moshix
# This is a BBS for 3270 terminals
# all rights reserved by moshix
#
# Supervisor loop for 3270BBS
#
# Drop the release binary you downloaded from
# https://github.com/moshix/3270BBS/releases next to this script, unrenamed
# (e.g. 3270BBS-4.2.9.2-linux-amd64), and run this script. It starts the
# NEWEST release binry in its own directory that matches this machine's OS
# and CPU, and keeps it running:
#
#   exit 0   the BBS was shut down on purpose: stop
#   exit 42  REIPL requested: restart at once (a newer binary that was
#            dropped in meanwhile is picked up)
#   other    crash or error: wait 2 seconds and restart
#
# On Linux all output is also appendeed to /var/log/tsu.log (via sudo tee).
#
# Options:
#   -verify, --verify   check the binary's SHA-256 against the digest GitHub
#                       publishes for that exact file name before starting it
#   -download, --download
#                       if no binary is found, download the newest release
#                       for this machine without asking (a run in a terminal
#                       asks first; a run without one never downloads)
#   -accept-license, --accept-license
#                       accept the license without being asked (first run)
#   -h, --help          show usage
#
# On the first run the license must be accepted (see check_license); the
# acceptance is recorded in .3270bbs_license_accepted next to the script.
#
# A binary named tsu or 3270BBS (built from source, or a renamed download)
# is started instaed when its -version output shows it is newer than every
# release file; see find_binary.
#


# Started as "sh <this script>"? Rerun undr bash, which this needs.
# (Alpine and other busybox systems may not have bash installed at all.)
if [ -z "$BASH_VERSION" ]; then
    command -v bash >/dev/null 2>&1 && exec bash "$0" "$@"
    echo "$0: this script needs bash, please install it" >&2
    exit 1
fi

PROG=$(basename "$0")
LOG_FILE="/var/log/tsu.log"          # unchanged name, existing operators rely on it
RELEASES_API="https://api.github.com/repos/moshix/3270BBS/releases?per_page=100"
RELEASES_PAGE="https://github.com/moshix/3270BBS/releases"
# The license is fetched from the API (raw media type), which is always
# current; raw.githubusercontent.com can serve a stale cached copy and is
# only the fallback for fetch(1)/ftp(1), which cannot send the header.
LICENSE_API="https://api.github.com/repos/moshix/3270BBS/contents/LICENSE"
LICENSE_RAW="https://raw.githubusercontent.com/moshix/3270BBS/main/LICENSE"
LICENSE_PAGE="https://github.com/moshix/3270BBS/blob/main/LICENSE"
LICENSE_RECORD=".3270bbs_license_accepted"   # next to the script
VERIFY=0
DOWNLOAD=0
ACCEPT_LICENSE=0


C_RESET=$'\033[0m'
C_RED=$'\033[31m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_CYAN=$'\033[36m'
C_BOLD=$'\033[1m'

# Decided once at startup: inside $(...) stdout is a pipe, so testing -t
# there would always say "no colour".
colour_ok() {
    [ -t "$1" ] && [ -z "${NO_COLOR:-}" ] && [ -n "${TERM:-}" ] && [ "$TERM" != dumb ]
}
COLOUR_1=0; colour_ok 1 && COLOUR_1=1
COLOUR_2=0; colour_ok 2 && COLOUR_2=1
use_colour() {      # use_colour FD (1 or 2)
    if [ "$1" = 2 ]; then [ $COLOUR_2 -eq 1 ]; else [ $COLOUR_1 -eq 1 ]; fi
}
# The effective character set is LC_ALL, else LC_CTYPE, else LANG.
# this is all chinese for me. Copied it from another script I foudn somwhere...
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *UTF-8*|*utf-8*|*UTF8*|*utf8*) UTF8=1 ;;
    *) UTF8=0 ;;
esac

# paint FD COLOUR TEXT: TEXT in COLOUR if FD gets colour, else plain.
paint() {
    if use_colour "$1"; then
        printf '%s%s%s' "$2" "$3" "$C_RESET"
    else
        printf '%s' "$3"
    fi
}

# prefix FD KIND: "✓ " / "⚠ " / "✗ " with colour and UTF-8, else the
# ASCII prefix "OK: " / "WARNING: " / "ERROR: ".
# not gonna lie: I don't like UTF-8....
prefix() {
    if use_colour "$1" && [ $UTF8 -eq 1 ]; then
        case "$2" in ok) printf '✓ ' ;; warn) printf '⚠ ' ;; err) printf '✗ ' ;; esac
    else
        case "$2" in ok) printf 'OK: ' ;; warn) printf 'WARNING: ' ;; err) printf 'ERROR: ' ;; esac
    fi
}

# details FD LINE...: the indented follow-up lines of a message, plain.
details() {
    local fd=$1 line
    shift
    for line in "$@"; do
        printf '  %s\n' "$line" >&"$fd"
    done
}

info() {            # info TEXT [DETAIL...]       plain, stdout
    printf '%s\n' "$1"
    shift
    details 1 "$@"
}
ok() {              # ok TEXT [DETAIL...]         green, stdout
    printf '%s\n' "$(paint 1 "$C_GREEN" "$(prefix 1 ok)$1")"
    shift
    details 1 "$@"
}
warn() {            # warn TEXT [DETAIL...]       yellow, stderr
    printf '%s\n' "$(paint 2 "$C_YELLOW" "$(prefix 2 warn)$1")" >&2
    shift
    details 2 "$@"
}
err() {             # err KEY TEXT [DETAIL...]    red, KEY bold, stderr
    local key=$1 text=$2
    shift 2
    [ -n "$text" ] && text=" $text"
    if use_colour 2; then
        printf '%s%s%s%s%s%s%s%s\n' "$C_RED" "$(prefix 2 err)" "$C_BOLD" \
            "$key" "$C_RESET" "$C_RED" "$text" "$C_RESET" >&2
    else
        printf '%s%s%s\n' "$(prefix 2 err)" "$key" "$text" >&2
    fi
    details 2 "$@"
}
banner() {          # banner TEXT                 cyan bold, stdout
    printf '%s\n' "$(paint 1 "$C_CYAN$C_BOLD" "$1")"
}
# ask QUESTION: print QUESTION in the prompt style (bold cyan, like the
# banner) and read the answer into ANSWER. Every question goes through here for consistensy
ask() {
    printf '%s ' "$(paint 1 "$C_CYAN$C_BOLD" "$1")"
    ANSWER=""
    read -r ANSWER
}

usage() {
    echo "Usage: $PROG [-verify] [-download] [-accept-license] [-h]"
    echo "Starts the newest 3270BBS release binary in this directory and"
    echo "restarts it after a REIPL or a crash."
    echo "  -verify          check its SHA-256 against GitHub before every start"
    echo "  -download        if there is no binary, download the latest without asking"
    echo "  -accept-license  accept the license without being asked"
    echo "  -h               show this help"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -verify|--verify) VERIFY=1 ;;
        -download|--download) DOWNLOAD=1 ;;
        -accept-license|--accept-license) ACCEPT_LICENSE=1 ;;
        -h|-help|--help) usage; exit 0 ;;
        *)
            err "Unknown option" "$1" "Try: $PROG -h"
            exit 2
            ;;
    esac
    shift
done

# The BBS reads tsu.cnf, tsu.db etc. from its working directory, and the
# release binary lives next to this script, so run from the script's own
# directory no matter where we were strted from...
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P) || {
    err "Cannot find" "the script's directory"
    exit 1
}
cd "$SCRIPT_DIR" || exit 1


# Release names use Go's GOOS/GOARCH spelling; map uname output onto it.
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    darwin|linux|freebsd|netbsd) ;;
    *)
        err "Unsupported system" "$(uname -s)" \
            "Releases exist for macOS, Linux, FreeBSD and NetBSD."
        exit 1
        ;;
esac
case "$(uname -m)" in
    x86_64|amd64)            ARCH=amd64 ;;
    aarch64|arm64)           ARCH=arm64 ;;
    i386|i486|i586|i686)     ARCH=i386 ;;
    s390x)                   ARCH=s390x ;;
    *)
        err "Unsupported CPU" "$(uname -m)" \
            "Releases exist for amd64, arm64, i386 and s390x."
        exit 1
        ;;
esac

#version comparison ---
# version_gt A B: succeeds when dotted version A is newer than B.
# Versions have any number of numeric components (4.3, 4.2.10, 4.2.9.2).
# They are compared component by component as integers, so 4.2.10 > 4.2.9.2
# (a plain string sort would get that wrong). A missing component counts as
# 0, so 4.2.9 == 4.2.9.0. The 10# prefix forces base 10, otherwise bash
# would read a component like "08" as an invalid octal number. Mkas no sense otherwise
version_gt() {
    local -a a b
    # Split at the dots; read -a works in bash 3.2 and does no globbing.
    IFS=. read -r -a a <<< "$1"
    IFS=. read -r -a b <<< "$2"
    local n=${#a[@]}
    [ ${#b[@]} -gt "$n" ] && n=${#b[@]}
    local i x y
    for ((i = 0; i < n; i++)); do
        x=${a[i]:-0}
        y=${b[i]:-0}
        if ((10#$x > 10#$y)); then return 0; fi
        if ((10#$x < 10#$y)); then return 1; fi
    done
    return 1    # equal is not greater
}

# binary selection 
VERSION_GUARD='print the 3270BBS version and exit'
VERSION_TIMEOUT=5     # seconds a -version run may take before it is killed

# has_version_option FILE: succeeds when FILE contains VERSION_GUARD.
GREP_A=""   # "yes"/"no": does this grep support -a? Probed once.
has_version_option() {
    # grep -a (binary as text) exists in GNU grep, BSD grep (macOS, FreeBSD)
    # and NetBSD's grep; a minimal busybox build may lack it and then exits
    # with 1 or 2, which must not be mistaken for "not found". So whether -a
    # works is probed once on a known input. LC_ALL=C stops a UTF-8 locale
    # from tripping over the binary's bytes.
    if [ -z "$GREP_A" ]; then
        if echo x | LC_ALL=C grep -a -q x 2>/dev/null; then GREP_A=yes; else GREP_A=no; fi
    fi
    if [ "$GREP_A" = yes ]; then
        LC_ALL=C grep -a -q "$VERSION_GUARD" "$1" 2>/dev/null
        return
    fi
    # Fallback with plain POSIX tools: every non-printable byte becomes a
    # newline, so the sentence ends up on a text line (glued to neighbouring
    # string literals), which plain grep can search.
    LC_ALL=C tr -c '[:print:]' '\n' < "$1" 2>/dev/null | LC_ALL=C grep -q "$VERSION_GUARD"
}

# probe_version NAME: print the version of ./NAME, or nothing if unknown
# (no -version option, no parseable output, or no answer in time).
probe_version() {
    local f="./$1" tmp pid i out
    has_version_option "$f" || return 0
    if [ ! -x "$f" ]; then
        ensure_executable "$f" || return 0
    fi
    tmp=$(mktemp "${TMPDIR:-/tmp}/3270bbs-version.XXXXXX") || return 0
    # Portable timeout (no GNU timeout(1) on macOS/BSD): run in the
    # background and poll every 0.1 s; kill it if it is still running after
    # VERSION_TIMEOUT seconds.
    "$f" -version </dev/null >"$tmp" 2>/dev/null &
    pid=$!
    i=0
    while kill -0 "$pid" 2>/dev/null && [ $i -lt $((VERSION_TIMEOUT * 10)) ]; do
        # Fractional sleep works with GNU, BSD and busybox sleep; a sleep
        # that rejects it fails at once, so then wait a whole second and
        # count it as ten ticks, keeping the limit at VERSION_TIMEOUT.
        if sleep 0.1 2>/dev/null; then
            i=$((i + 1))
        else
            sleep 1
            i=$((i + 10))
        fi
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        sleep 1
        kill -9 "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null
        rm -f "$tmp"
        warn "$f -version did not answer, its version is unknown"
        return 0
    fi
    wait "$pid" 2>/dev/null
    out=$(sed -n 's/^3270BBS-VERSION=//p' "$tmp" | head -n 1)
    rm -f "$tmp"
    # Accept only a well-formed dotted number (N, N.N, N.N.N, ...).
    local re='^[0-9]+(\.[0-9]+)*$'
    [[ "$out" =~ $re ]] && printf '%s\n' "$out"
    return 0
}

# add_note LEVEL TEXT: append "LEVEL|TEXT" (LEVEL info or warn) to
# SELECT_NOTE, which the loop prints through log_message.
add_note() {
    if [ -n "$SELECT_NOTE" ]; then
        SELECT_NOTE="$SELECT_NOTE
$1|$2"
    else
        SELECT_NOTE="$1|$2"
    fi
}

# Self-built or renamed binaries that are candidates besides the release
# files: "tsu" (older installs) and "3270BBS" (go build -o 3270BBS).
LOCAL_NAMES="tsu 3270BBS"

# find_binary: set BIN to the binary to start, from the current directory,

find_binary() {
    local re="^3270BBS-([0-9]+(\.[0-9]+)*)-${OS}-${ARCH}\$"
    local f ver best="" bestver=""
    local name lver lbest="" lbestver="" unknown="" others=""
    SELECT_NOTE=""
    BIN_IS_LOCAL=0
    BIN_VER=""
    for f in 3270BBS-*-"${OS}-${ARCH}"; do
        [ -f "$f" ] || continue          # also covers "no match" (literal glob)
        [[ "$f" =~ $re ]] || continue
        ver=${BASH_REMATCH[1]}
        if [ -z "$best" ] || version_gt "$ver" "$bestver"; then
            best=$f
            bestver=$ver
        fi
    done
    for name in $LOCAL_NAMES; do
        [ -f "$name" ] || continue
        lver=$(probe_version "$name")
        if [ -z "$lver" ]; then
            if [ -z "$unknown" ]; then unknown=$name; else others="$others $name"; fi
        elif [ -z "$lbest" ] || version_gt "$lver" "$lbestver"; then
            [ -n "$lbest" ] && others="$others $lbest"
            lbest=$name
            lbestver=$lver
        else
            others="$others $name"
        fi
    done

    if [ -n "$lbest" ] && { [ -z "$best" ] || version_gt "$lbestver" "$bestver"; }; then
        BIN="./$lbest"
        BIN_VER=$lbestver
        BIN_IS_LOCAL=1
        [ -n "$best" ] && add_note info "Using ./$lbest $lbestver, newer than $best"
    elif [ -n "$best" ]; then
        BIN="./$best"
        BIN_VER=$bestver
        [ -n "$lbest" ] && add_note info "Ignoring ./$lbest $lbestver, not newer than $best"
    elif [ -n "$unknown" ]; then
        BIN="./$unknown"
        BIN_IS_LOCAL=1
        add_note warn "./$unknown has no -version option, its version is unknown"
        unknown=""
    else
        return 1
    fi
    [ -n "$unknown" ] && add_note warn "Ignoring ./$unknown, its version is unknown"
    for name in $others; do
        add_note info "Ignoring ./$name"
    done
    return 0
}

# no_binary_error [HEADLINE]: the fatal "nothing to start" message.
no_binary_error() {
    err "No 3270BBS binary" "${1:-for ${OS}-${ARCH} in $SCRIPT_DIR}" \
        "Download it from $RELEASES_PAGE" \
        "or run: $PROG -download"
}

# Browser downloads lose the execute bit; restore it rather than fail.
ensure_executable() {
    if [ ! -x "$1" ]; then
        warn "$1 was not executable, ran chmod +x"
        if ! chmod +x "$1"; then
            err "Cannot run" "$1: chmod +x failed"
            return 1
        fi
    fi
    return 0
}

#  verification option
# sha256_of FILE: print FILE's hex SHA-256. Returns 2 when no hashing tool
# is installed, 1 when the tool failed.
sha256_of() {
    local sum
    if command -v sha256sum >/dev/null 2>&1; then
        sum=$(sha256sum "$1" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        sum=$(shasum -a 256 "$1" | awk '{print $1}')
    elif command -v openssl >/dev/null 2>&1; then
        # Output is "SHA2-256(file)= <hex>" or "SHA256(file)= <hex>": take the last field
        sum=$(openssl dgst -sha256 "$1" | awk '{print $NF}')
    else
        return 2
    fi
    [ -n "$sum" ] || return 1
    printf '%s\n' "$sum"
}

# http_get URL [ACCEPT]: print the document at URL, sending "Accept:
# ACCEPT" when given. curl or wget where installed; stock FreeBSD has
# fetch(1) and stock NetBSD ftp(1) instead, both of which speak https and
# follow redirects but send no extra header.
http_get() {
    local hdr=()
    if command -v curl >/dev/null 2>&1; then
        [ -n "${2:-}" ] && hdr=(-H "Accept: $2")
        curl -fsSL --max-time 30 "${hdr[@]}" "$1" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        [ -n "${2:-}" ] && hdr=("--header=Accept: $2")
        wget -q -T 30 -O - "${hdr[@]}" "$1" 2>/dev/null
    elif [ "$OS" = "freebsd" ] && command -v fetch >/dev/null 2>&1; then
        fetch -q -T 30 -o - "$1" 2>/dev/null
    elif [ "$OS" = "netbsd" ] && command -v ftp >/dev/null 2>&1; then
        ftp -V -o - "$1" 2>/dev/null
    else
        err "No download tool" "found: install curl or wget"
        return 1
    fi
}

# fetch_releases: print the GitHub release list (JSON).
fetch_releases() {
    http_get "$RELEASES_API" "application/vnd.github+json"
}

# published_digest NAME < releases.json: print the hex sha256 GitHub lists
# for the asset called exactly NAME, searching every release (the release
# tag, e.g. 4.2.9, is not the version in the file name, e.g. 4.2.9.2).
published_digest() {
    local name=$1 json
    json=$(cat)
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$json" | jq -r --arg n "$name" \
            '[.[].assets[]? | select(.name == $n) | .digest // empty][0] // empty' 2>/dev/null \
            | sed -n 's/^sha256://p'
        return 0
    fi
    # Fallback without jq (plain awk, no JSON parser needed).
    # thank goodness for AI....
    printf '%s' "$json" \
        | awk '{ gsub(/[{}]/, "\n&\n"); gsub(/,/, "\n"); print }' \
        | awk -v want="\"name\":\"$name\"" '
            { gsub(/[ \t\r]/, "") }
            $0 == "{" { depth++; next }
            $0 == "}" { depth--; if (found && depth < at) found = 0; next }
            $0 == want { found = 1; at = depth; next }
            found && depth == at && /^"digest":/ {
                if (sub(/^"digest":"sha256:/, "")) { sub(/".*$/, ""); print; exit }
                found = 0
            }
        '
}

# Digests already fetched from GitHub in this run, one "name hex" per line
# (bash 3.2 has no associative arrays). A file is re-hashed before EVERY
# start, but GitHub is asked only once per file name, so a file replaced in
# place under the same name is still caught, without another API call.
DIGESTS=""

cached_digest() {
    printf '%s\n' "$DIGESTS" | awk -v n="$1" '$1 == n { print $2; exit }'
}

# verify_binary ./3270BBS-...: 0 when the local SHA-256 equals GitHub's.
verify_binary() {
    local file=$1 name local_sum json remote_sum rc
    name=$(basename "$file")
    remote_sum=$(cached_digest "$name")
    local_sum=$(sha256_of "$file")
    rc=$?
    if [ $rc -eq 2 ]; then
        err "Cannot verify" "$name: no sha256sum, shasum or openssl"
        return 1
    elif [ $rc -ne 0 ]; then
        err "Cannot verify" "$name: computing its SHA-256 failed"
        return 1
    fi
    if [ -z "$remote_sum" ]; then
        if ! json=$(fetch_releases) || [ -z "$json" ]; then
            err "Cannot verify" "$name: GitHub not reachable" \
                "Try again later, or start without -verify"
            return 1
        fi
        remote_sum=$(printf '%s' "$json" | published_digest "$name" | tr '[:upper:]' '[:lower:]')
        if [ -z "$remote_sum" ]; then
            err "Cannot verify" "$name: not published on GitHub" \
                "Download the current release from $RELEASES_PAGE"
            return 1
        fi
        DIGESTS="$DIGESTS
$name $remote_sum"
    fi
    # Compare case-insensitively; both should be lowercase hex anyway.
    local_sum=$(printf '%s' "$local_sum" | tr '[:upper:]' '[:lower:]')
    if [ "$local_sum" != "$remote_sum" ]; then
        err "SHA-256 mismatch:" "$name differs from GitHub" \
            "The file is damaged or altered and was not started." \
            "Download it again from $RELEASES_PAGE"
        return 1
    fi
    ok "Verified $name against GitHub"
    return 0
}

# verify_choice: -verify check of BIN right before it is started.

LAST_GOOD=""
LAST_GOOD_VER=""
verify_choice() {
    local ok=0
    if [ "$BIN_IS_LOCAL" -eq 1 ]; then
        err "Cannot verify" "$BIN: not a release file, no digest on GitHub" \
            "Move it away to use the release file, or drop -verify"
    elif verify_binary "$BIN"; then
        ok=1
    fi
    if [ $ok -eq 1 ]; then
        LAST_GOOD=$BIN
        LAST_GOOD_VER=$BIN_VER
        return 0
    fi
    if [ -n "$LAST_GOOD" ] && [ "$LAST_GOOD" != "$BIN" ] && [ -f "$LAST_GOOD" ] \
            && verify_binary "$LAST_GOOD"; then
        log_message warn "$BIN failed verification" \
            "Starting the previously verified $LAST_GOOD instead"
        BIN=$LAST_GOOD
        BIN_VER=$LAST_GOOD_VER
        BIN_IS_LOCAL=0
        return 0
    fi
    return 1
}

# download 

# release_assets < releases.json: print one line per asset,
# "name<TAB>digest<TAB>size<TAB>browser_download_url", over ALL releases.
release_assets() {
    if command -v jq >/dev/null 2>&1; then
        jq -r '.[].assets[]? | [.name, (.digest // ""), ((.size // 0) | tostring), (.browser_download_url // "")] | @tsv' 2>/dev/null
        return 0
    fi
    # Fallback without jq, same line splitting as published_digest. Every
    # "key":value line is stored under the current brace depth; when an
    # object closes, an object that had both a "name" and a
    # "browser_download_url" at that depth was an asset and is printed.
    # Fields of the nested uploader object live one depth deeper and so
    # never mix with the asset's own fields.
    awk '{ gsub(/[{}]/, "\n&\n"); gsub(/,/, "\n"); print }' \
        | awk '
            { gsub(/[ \t\r]/, "") }
            $0 == "{" { depth++; nm[depth] = ""; dg[depth] = ""; sz[depth] = ""; ur[depth] = ""; next }
            $0 == "}" {
                if (nm[depth] != "" && ur[depth] != "")
                    printf "%s\t%s\t%s\t%s\n", nm[depth], dg[depth], sz[depth], ur[depth]
                depth--; next
            }
            match($0, /^"[a-z_]+":/) {
                key = substr($0, 2, RLENGTH - 3)
                val = substr($0, RLENGTH + 1)
                gsub(/^"|"$/, "", val)
                if (key == "name") nm[depth] = val
                else if (key == "digest") dg[depth] = val
                else if (key == "size") sz[depth] = val
                else if (key == "browser_download_url") ur[depth] = val
            }
        '
}

# download_to URL FILE: download, following redirects (GitHub's download
# URLs redirect to objects.githubusercontent.com). curl needs -L; wget,
# FreeBSD fetch and NetBSD ftp follow redirects by themselves.
download_to() {
    # In a terminal a one-line progress bar (-#), otherwise silent (-sS).
    local quiet=(-#)
    is_interactive || quiet=(-sS)
    if command -v curl >/dev/null 2>&1; then
        curl -fL "${quiet[@]}" --max-time 900 -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -T 60 -O "$2" "$1"
    elif [ "$OS" = "freebsd" ] && command -v fetch >/dev/null 2>&1; then
        fetch -q -T 60 -o "$2" "$1"
    elif [ "$OS" = "netbsd" ] && command -v ftp >/dev/null 2>&1; then
        ftp -V -o "$2" "$1"
    else
        err "No download tool" "found: install curl or wget"
        return 1
    fi
}

is_interactive() {
    [ -t 0 ] && [ -t 1 ]
}

# offer_download ask|force: find the newest release binary for this
# machine on GitHub and download it (asking first in "ask" mode). Returns 0
# when a checked binary is now in place, 1 when the user said no. Every
# real failure ends the script with exit 1.
PART=""
offer_download() {
    local mode=$1 json re name digest size url ver tab mb
    local best="" bestver="" bestdigest="" bestsize="" besturl="" sum
    if ! json=$(fetch_releases) || [ -z "$json" ]; then
        err "Cannot download:" "GitHub not reachable" "Try again later"
        exit 1
    fi
    # Same name rule as find_binary: exactly 3270BBS-<N(.N)*>-<os>-<arch>
    # (so no .exe), newest version across every release.
    re="^3270BBS-([0-9]+(\.[0-9]+)*)-${OS}-${ARCH}\$"
    tab=$(printf '\t')
    while IFS="$tab" read -r name digest size url; do
        [[ "$name" =~ $re ]] || continue
        ver=${BASH_REMATCH[1]}
        if [ -z "$best" ] || version_gt "$ver" "$bestver"; then
            best=$name; bestver=$ver; bestdigest=$digest; bestsize=$size; besturl=$url
        fi
    done <<ASSETS
$(printf '%s\n' "$json" | release_assets)
ASSETS
    if [ -z "$best" ]; then
        err "No release" "for ${OS}-${ARCH} on GitHub" "See $RELEASES_PAGE"
        exit 1
    fi
    bestdigest=$(printf '%s' "$bestdigest" | sed -n 's/^sha256://p' | tr '[:upper:]' '[:lower:]')
    if [ -z "$bestdigest" ] || [ -z "$besturl" ]; then
        err "Not downloading" "$best: GitHub lists no SHA-256 for it"
        exit 1
    fi
    mb=$(awk -v b="${bestsize:-0}" 'BEGIN { printf "%.1f MB", b / 1048576 }')
    if [ "$mode" = "ask" ]; then
        info "Latest release: $(paint 1 "$C_CYAN" "$best"), $mb"
        ask "Download it now? [y/N]"
        case "$ANSWER" in
            [yY]|[yY][eE][sS]) ;;
            *) return 1 ;;
        esac
    fi

    # Download under a temporary dot-name (never matched by find_binary,
    # whose names must start with "3270BBS-"), check it, and only then make
    # it executable and move it to its real name. The trap removes the part
    # file on Ctrl-C or kill.
    PART=".$best.part"
    trap 'rm -f "$PART"; echo; err "Download interrupted," "partial file removed"; exit 130' INT TERM
    info "Downloading $(paint 1 "$C_CYAN" "$best"), $mb"
    if ! download_to "$besturl" "$PART" || [ ! -s "$PART" ]; then
        rm -f "$PART"
        trap - INT TERM
        err "Download failed:" "$best" "Try again later"
        exit 1
    fi
    sum=$(sha256_of "$PART" | tr '[:upper:]' '[:lower:]')
    if [ -z "$sum" ] || [ "$sum" != "$bestdigest" ]; then
        rm -f "$PART"
        trap - INT TERM
        err "SHA-256 mismatch:" "the download differs from GitHub" \
            "It was deleted and nothing was started."
        exit 1
    fi
    if ! chmod +x "$PART" || ! mv -f "$PART" "$best"; then
        rm -f "$PART"
        trap - INT TERM
        err "Cannot install" "$best in $SCRIPT_DIR"
        exit 1
    fi
    trap - INT TERM
    PART=""
    # Remember the digest, so -verify re-hashes it without asking GitHub again.
    DIGESTS="$DIGESTS
$best $bestdigest"
    ok "Downloaded $best, SHA-256 matches GitHub"
    return 0
}

# --- license --------------------------------------------------------------
# 3270BBS may only be run once its license has been accepted. The first run
# asks in a terminal (v shows the license); -accept-license accepts without
# asking; a first run without a terminal (systemd, cron) stops with a hint.
# The acceptance is kept in LICENSE_RECORD and never asked for again.

render_license() {
    local h_on="" h_off="" bullet="-" rule="-"
    if use_colour 1; then
        h_on="$C_BOLD$C_CYAN"
        h_off=$C_RESET
        if [ $UTF8 -eq 1 ]; then bullet="•"; rule="─"; fi
    fi
    awk -v w="$1" -v h_on="$h_on" -v h_off="$h_off" -v bullet="$bullet" -v rule="$rule" '
        # wrap TEXT into lines of at most w columns: the first line starts
        # with FIRST, the others with REST (both PW columns wide).
        function wrap(text, first, rest, pw, on, off,    n, i, word, line, out, pre) {
            n = split(text, words, / +/)
            line = ""; pre = first
            for (i = 1; i <= n; i++) {
                word = words[i]
                if (word == "") continue
                if (line != "" && pw + length(line) + 1 + length(word) > w) {
                    print pre on line off
                    line = ""; pre = rest
                }
                line = (line == "") ? word : line " " word
            }
            if (line != "") print pre on line off
        }
        function spaces(k,    r) { r = ""; while (k-- > 0) r = r " "; return r }
        { sub(/\r$/, ""); gsub(/\*\*/, "") }
        /^[ \t]*$/ { print ""; next }
        /^#+[ \t]/ { t = $0; sub(/^#+[ \t]+/, "", t); wrap(t, "", "", 0, h_on, h_off); next }
        /^[ \t]*(-{3,}|\*{3,}|_{3,})[ \t]*$/ { r = ""; for (i = 0; i < w; i++) r = r rule; print r; next }
        /^ *[-*+] / {
            match($0, /^ */); ind = RLENGTH
            t = substr($0, ind + 3)
            wrap(t, spaces(ind) bullet " ", spaces(ind + 2), ind + 2, "", "")
            next
        }
        { match($0, /^ */); ind = RLENGTH; t = substr($0, ind + 1)
          wrap(t, spaces(ind), spaces(ind), ind, "", "") }
    '
}

# fetch_license: fetch the current license text into LICENSE_TEXT (memory
# only; nothing but its SHA-256 is ever stored) and set LICENSE_SHA and
# LICENSE_TITLE (its first "# " heading). Returns 1 if it cannot be fetched.
LICENSE_TEXT=""
LICENSE_SHA=""
LICENSE_TITLE=""
fetch_license() {
    local tmp
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        LICENSE_TEXT=$(http_get "$LICENSE_API" "application/vnd.github.raw") || LICENSE_TEXT=""
    else
        LICENSE_TEXT=$(http_get "$LICENSE_RAW") || LICENSE_TEXT=""
    fi
    [ -n "$LICENSE_TEXT" ] || return 1
    LICENSE_TITLE=$(printf '%s\n' "$LICENSE_TEXT" | sed -n 's/^#[ 	][ 	]*//p' | head -n 1 | tr -d '\r')
    # Hash the text exactly as fetched (a temporary file, removed at once).
    tmp=$(mktemp "${TMPDIR:-/tmp}/3270bbs-license.XXXXXX") || return 0
    printf '%s\n' "$LICENSE_TEXT" > "$tmp"
    LICENSE_SHA=$(sha256_of "$tmp")
    rm -f "$tmp"
    return 0
}

# show_license: page the fetched license, formatted for the terminal.
show_license() {
    local cols width
    # Width: the terminal's, but never more than 79 columns. "stty size"
    # asks the terminal itself (GNU, BSD and busybox stty all have it);
    # tput is optional and, inside $(...), only sees a pipe and answers its
    # default of 80, so it is the second choice; then $COLUMNS, then 79.
    cols=$(stty size 2>/dev/null </dev/tty | awk '{ print $2 }')
    [ -n "$cols" ] || cols=$(tput cols 2>/dev/null)
    [ -n "$cols" ] || cols=${COLUMNS:-79}
    case "$cols" in ''|*[!0-9]*) cols=79 ;; esac
    width=$cols
    [ "$width" -gt 79 ] && width=79
    [ "$width" -lt 20 ] && width=20
    # less -R passes the colours through, -F quits at once when the text
    # fits on one screen and -X leaves it on the screen afterwards.
    if command -v less >/dev/null 2>&1; then
        printf '%s\n' "$LICENSE_TEXT" | render_license "$width" | less -RFX
    elif command -v more >/dev/null 2>&1; then
        printf '%s\n' "$LICENSE_TEXT" | render_license "$width" | more
    else
        printf '%s\n' "$LICENSE_TEXT" | render_license "$width"
    fi
}

# record_license: write LICENSE_RECORD (UTC date, user, license digest if
# the text was fetched).
record_license() {
    if ! {
        echo "accepted=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo "user=${USER:-$(id -un 2>/dev/null)}"
        [ -n "$LICENSE_SHA" ] && echo "license_sha256=$LICENSE_SHA"
        echo "license=$LICENSE_PAGE"
    } > "$LICENSE_RECORD"; then
        err "Cannot write" "$SCRIPT_DIR/$LICENSE_RECORD"
        exit 1
    fi
    ok "License accepted"
}

# check_license: return when the license is (now) accepted, else exit 1.
check_license() {
    local choices
    [ -f "$LICENSE_RECORD" ] && return 0
    if [ $ACCEPT_LICENSE -eq 1 ]; then
        fetch_license || true      # only for the digest in the record
        record_license
        return 0
    fi
    if ! is_interactive; then
        err "License not accepted" "yet" \
            "Run $PROG once in a terminal, or start it with -accept-license"
        exit 1
    fi
    if fetch_license; then
        info "3270BBS is licensed under the ${LICENSE_TITLE:-3270BBS license}"
        choices="y/N/v=view"
    else
        warn "Could not fetch the 3270BBS license, see $LICENSE_PAGE"
        choices="y/N"
    fi
    while true; do
        ask "Accept the license? [$choices]"
        case "$ANSWER" in
            [yY]|[yY][eE][sS]) record_license; return 0 ;;
            [vV]|[vV][iI][eE][wW])
                [ -n "$LICENSE_TEXT" ] && show_license ;;
            *) err "License not accepted" ""; exit 1 ;;
        esac
    done
}

#  logging 
LOGGING=0


log_message() {
    local level=$1 text=$2 tag=""
    shift 2
    case "$level" in
        ok)   ok "$text" "$@";   tag="OK: " ;;
        warn) warn "$text" "$@"; tag="WARNING: " ;;
        err)  err "${text%% *}" "${text#* }" "$@"; tag="ERROR: " ;;
        *)    info "$text" "$@" ;;
    esac
    if [ $LOGGING -eq 1 ]; then
        if ! printf '%s - %s%s%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$tag" "$text" \
                "$([ $# -gt 0 ] && printf ' (%s)' "$*")" | sudo tee -a "$LOG_FILE" >/dev/null; then
            warn "Cannot write to $LOG_FILE"
        fi
    fi
}

# start_message: "Starting <binary>", green with the binary (and, for a
# local binary, its version) in cyan; plain "Starting ..." in the log file.
start_message() {
    local what=$BIN
    # A release file name already carries the version; a local one does not.
    [ "$BIN_IS_LOCAL" -eq 1 ] && [ -n "$BIN_VER" ] && what="$BIN $BIN_VER"
    printf '%s\n' "$(paint 1 "$C_GREEN" "$(prefix 1 ok)Starting ")$(paint 1 "$C_CYAN" "$what")"
    if [ $LOGGING -eq 1 ]; then
        printf '%s - Starting %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$what" \
            | sudo tee -a "$LOG_FILE" >/dev/null || warn "Cannot write to $LOG_FILE"
    fi
}

#  supervisor loop 
# The binary is chosen anew on every iteration, so a newer download dropped
# in while the BBS runs is started after the next REIPL (exit 42) or crash.
# With -verify, the chosen file is checked before every start (see
# verify_choice).
# Ctrl-C reaches the BBS and this script alike (same process group). The
# trap only records it, so after the BBS has ended the loop stops instead of
# restarting it. In logging mode tee ignores SIGINT: otherwise it would die
# first and the BBS, writing into the broken pipe, would end with SIGPIPE.
# this also closes the LOG of the BBS...
STOP=0
LAST_NOTE=""
run_loop() {
    local exit_code line
    trap 'STOP=1' INT
    while true; do
        # The first pass reuses the selection made before the banner, so a
        # -version probe (up to VERSION_TIMEOUT seconds) is not run twice.
        if [ $SELECTED -eq 1 ]; then
            SELECTED=0
        elif ! find_binary; then
            # The binary vanished while running. Only a run in a terminal
            # may download again (after asking); others never download
            # mid-loop, -download or not.
            if ! is_interactive || ! offer_download ask || ! find_binary; then
                no_binary_error
                [ $LOGGING -eq 1 ] && log_message err "No 3270BBS binary found, stopping"
                exit 1
            fi
        fi
        # Repeat selection notes only when they change, not on every restart.
        if [ -n "$SELECT_NOTE" ] && [ "$SELECT_NOTE" != "$LAST_NOTE" ]; then
            while IFS= read -r line; do
                log_message "${line%%|*}" "${line#*|}"
            done <<NOTES
$SELECT_NOTE
NOTES
        fi
        LAST_NOTE=$SELECT_NOTE
        ensure_executable "$BIN" || exit 1
        if [ $VERIFY -eq 1 ] && ! verify_choice; then
            [ $LOGGING -eq 1 ] && log_message err "Verification of $BIN failed, not started"
            exit 1
        fi

        start_message
        if [ $LOGGING -eq 1 ]; then
            "$BIN" 2>&1 | (trap '' INT; exec sudo tee -a "$LOG_FILE")
            exit_code=${PIPESTATUS[0]}   # exit code of the BBS, not of tee
        else
            "$BIN"
            exit_code=$?
        fi

        if [ $STOP -eq 1 ]; then
            log_message warn "Ctrl-C: stopping, 3270BBS ended with code $exit_code"
            break
        elif [ "$exit_code" -eq 0 ]; then
            log_message ok "3270BBS shut down"
            break
        elif [ "$exit_code" -eq 42 ]; then
            log_message info "REIPL requested, restarting"
            continue
        else
            log_message warn "3270BBS ended with code $exit_code, restarting in 2 seconds"
            sleep 2
            if [ $STOP -eq 1 ]; then
                log_message warn "Interrupted, stopping"
                break
            fi
        fi
    done
}

# The license comes first, before any download or start.
check_license

# Before any banner: if there is nothing to start, offer a download
# (-download: without asking; in a terminal: after asking; otherwise not).
if ! find_binary; then
    if [ $DOWNLOAD -eq 1 ]; then
        info "No 3270BBS binary for ${OS}-${ARCH} here, downloading the latest"
        offer_download force
    elif is_interactive; then
        info "No 3270BBS binary for ${OS}-${ARCH} in $SCRIPT_DIR"
        if ! offer_download ask; then
            err "No binary to start" "" "Download it from $RELEASES_PAGE" \
                "or run: $PROG -download"
            exit 1
        fi
    else
        no_binary_error
        exit 1
    fi
    if ! find_binary; then
        no_binary_error
        exit 1
    fi
fi
SELECTED=1

banner "=== 3270BBS ==="
if [ "$OS" = "linux" ]; then
    # Linux machine - try to enable logging to /var/log/tsu.log
    if ! command -v sudo >/dev/null 2>&1; then
        warn "sudo not found, not logging to $LOG_FILE"
    elif ! sudo touch "$LOG_FILE" 2>/dev/null; then
        warn "Cannot write $LOG_FILE, not logging" "Check sudo access"
    elif printf '%s - 3270BBS starting, logging to %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$LOG_FILE" \
            | sudo tee -a "$LOG_FILE" >/dev/null; then
        LOGGING=1
        info "Logging to $LOG_FILE"
    else
        warn "Cannot write $LOG_FILE, not logging"
    fi
fi

run_loop
exit 0
