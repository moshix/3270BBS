#!/usr/bin/env bash
# copyright 2025 by moshix
# This is a BBS for 3270 terminals
# all rights reserved by moshix

while true; do
  time ./tsu
  if [ $? -eq 0 ]; then
    echo "tsu exited successfully. Not restarting."
    break
  else
    echo "tsu exited with an error. Restarting in 2 seconds..."
    sleep 2
  fi
done
