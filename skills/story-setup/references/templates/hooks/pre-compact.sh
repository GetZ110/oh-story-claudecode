#!/bin/bash
# pre-compact.sh — record a writing-state summary before compact (no content dump)
set -euo pipefail

# Load shared libraries
source "$(dirname "$0")/lib/common.sh"

# Byte-stable zone: book paths flow through discover_active_book (issue #164 class).
export LC_ALL=C

ROOT=$(project_root)

echo "=== Pre-Compact Summary ==="

BOOK_DIR=$(discover_active_book)

# context.md status summary (path + line count, no content)
if [ -n "$BOOK_DIR" ] && [ -f "$BOOK_DIR/tracking/context.md" ]; then
  LINE_COUNT=$(wc -l < "$BOOK_DIR/tracking/context.md" | tr -d ' ')
  echo "Writing context: ${BOOK_DIR#$ROOT/}/tracking/context.md ($LINE_COUNT lines)"
else
  echo "Active state: not found"
fi

# Git uncommitted-change counts
CHANGED=$(git -C "$ROOT" diff --name-only 2>/dev/null | wc -l | tr -d ' ') || CHANGED=0
STAGED=$(git -C "$ROOT" diff --name-only --cached 2>/dev/null | wc -l | tr -d ' ') || STAGED=0
echo "Git: ${CHANGED} unstaged, ${STAGED} staged"

echo "=== Pre-Compact Complete ==="
