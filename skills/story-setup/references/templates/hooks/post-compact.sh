#!/bin/bash
# post-compact.sh — remind to restore context after compact
set -euo pipefail

# Load shared libraries
source "$(dirname "$0")/lib/common.sh"

# Byte-stable zone: book paths flow through discover_active_book (issue #164 class).
export LC_ALL=C

ROOT=$(project_root)
BOOK_DIR=$(discover_active_book)

if [ -n "$BOOK_DIR" ] && [ -f "$BOOK_DIR/tracking/context.md" ]; then
  LINE_COUNT=$(wc -l < "$BOOK_DIR/tracking/context.md" | tr -d ' ')
  echo "Context was compacted. Read ${BOOK_DIR#$ROOT/}/tracking/context.md ($LINE_COUNT lines) to restore writing context."
else
  echo "Context was compacted. Check tracking/context.md to restore context."
fi
