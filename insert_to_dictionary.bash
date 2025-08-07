#!/usr/bin/env bash
# copyright 2025 by moshix
# This is a BBS for 3270 terminals
# all rights reserved by moshix


# Check for one argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <word-to-insert>"
    exit 1
fi

# Convert word to lowercase
word=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Insert word into dictionary.txt and sort in place
if [ ! -f dictionary.txt ]; then
    echo "dictionary.txt not found."
    exit 2
fi

{ echo "$word"; cat dictionary.txt; } | sort -u > temp && mv temp dictionary.txt

