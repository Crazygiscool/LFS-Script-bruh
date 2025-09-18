#!/bin/bash
set -e

# Get the directory where this script lives
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Recursively print folder structure
print_tree() {
  local dir="$1"
  local indent="$2"
  echo "${indent}$(basename "$dir")/"
  for entry in "$dir"/*; do
    [ -e "$entry" ] || continue
    if [ -d "$entry" ]; then
      print_tree "$entry" "    $indent"
    else
      echo "    $indent$(basename "$entry")"
    fi
  done
}

print_tree "$ROOT" ""
