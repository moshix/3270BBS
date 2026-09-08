#!/bin/bash
# Copyright 2025,2026 by moshix
#
# reset_admin_password.bash
# Thin wrapper around `tsu --change-admin-password`.
#
# The reset itself now lives INSIDE the TSU binary (changeadminpw.go), so it
# uses models.HashPasswordBcrypt and the BBS's own password-length rules
# directly. That removes this script's two external dependencies -- an external
# bcrypt tool (htpasswd, or a throwaway Go program) and the sqlite3 CLI -- and
# removes any chance of the hash format or the length limits drifting away from
# what the running BBS accepts.
#
# The binary reads tsu.cnf and tsu.db from the CURRENT WORKING DIRECTORY, so
# run this from the TSU install directory.

set -u

RED='\033[0;31m'
NC='\033[0m'
print_error() { echo -e "${RED}[-]${NC} $1" >&2; }

# Resolve the binary: $TSU_BIN wins, else 'tsu' beside this script (derived
# from $0 so an absolute invocation from another directory still finds it),
# else ./tsu in the current directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

if [ -n "${TSU_BIN:-}" ]; then
    BIN="$TSU_BIN"
elif [ -x "$SCRIPT_DIR/tsu" ]; then
    BIN="$SCRIPT_DIR/tsu"
else
    BIN="./tsu"
fi

if [ ! -f "$BIN" ]; then
    print_error "TSU binary '$BIN' not found."
    print_error "Build it first with:  go build -o tsu ."
    print_error "Or point this script at it with:  TSU_BIN=/path/to/tsu $0"
    exit 1
fi
if [ ! -x "$BIN" ]; then
    print_error "TSU binary '$BIN' is not executable (chmod +x it)."
    exit 1
fi

# exec, not a subshell: the binary owns the terminal from here on, so its
# no-echo password prompt and its exit status are the operator's directly.
exec "$BIN" --change-admin-password "$@"
