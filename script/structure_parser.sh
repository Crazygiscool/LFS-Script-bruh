#!/bin/bash
set -e

STARTPATH="${1:-.}"
OUTPUT_FILE="${2:-folder_structure.txt}"

> "$OUTPUT_FILE"

list_dir() {
  local path="$1"
  local indent="$2"
  echo "${indent}$(basename "$path")/" >> "$OUTPUT_FILE"

  for entry in "$path"/*; do
    [ -e "$entry" ] || continue
    if [ -d "$entry" ]; then
      list_dir "$entry" "    $indent"
    else
      echo "    $indent$(basename "$entry")" >> "$OUTPUT_FILE"
    fi
  done
}

list_dir "$STARTPATH" ""
echo "✅ Folder structure written to $OUTPUT_FILE"
