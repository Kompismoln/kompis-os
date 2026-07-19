#!/usr/bin/env bash
# rg-replace: interactive search & replace with context + confirmation
# Usage: rg-replace <search> <replace> [directory]

SEARCH="$1"
REPLACE="$2"
DIR="${3:-.}"

if [[ -z "$SEARCH" || -z "$REPLACE" ]]; then
  echo "Usage: $0 <search> <replace> [directory]"
  exit 1
fi

# Use rg to find matches, pipe into fzf with bat preview showing context
# shellcheck disable=SC2016
SELECTED=$(
  rg --line-number --color=never "$SEARCH" "$DIR" |
    fzf --multi \
      --delimiter=':' \
      --preview 'FILE={1}; LINE={2}; START=$((LINE>4 ? LINE-4 : 1)); bat --color=always --highlight-line $LINE --line-range $START:$((LINE+5)) "$FILE"' \
      --preview-window 'right:60%:wrap' \
      --header "Select lines to replace '$SEARCH' → '$REPLACE' (TAB to multi-select, ENTER to confirm)"
)

if [[ -z "$SELECTED" ]]; then
  echo "No selections made. Aborting."
  exit 0
fi

# Process each selected line
echo "$SELECTED" | while IFS=':' read -r FILE LINE _REST; do
  echo ""
  echo "─── $FILE : line $LINE ───"
  # Show context with bat
  bat --color=always \
    --highlight-line "$LINE" \
    --line-range "$((LINE - 3)):$((LINE + 3))" \
    "$FILE"
  echo ""
  printf "Replace in this line? [y/N] "
  read -r CONFIRM </dev/tty

  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    # In-place replace only that specific line (macOS/BSD and Linux compatible)
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i "${LINE}s|${SEARCH}|${REPLACE}|g" "$FILE"
    else
      sed -i '' "${LINE}s|${SEARCH}|${REPLACE}|g" "$FILE"
    fi
    echo "✓ Replaced in $FILE:$LINE"
  else
    echo "✗ Skipped"
  fi
done

echo ""
echo "Done."
