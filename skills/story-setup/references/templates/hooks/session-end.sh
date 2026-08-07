#!/bin/bash
# session-end.sh — record the final state at session end when requested
# Design principle: silent and file-less by default; even when enabled, never create
# a tracking/ directory for a short-form project
set -euo pipefail

# Load shared libraries
source "$(dirname "$0")/lib/common.sh"

# Byte-stable zone: book paths flow through discover_active_book (issue #164 class).
export LC_ALL=C

# session-log.txt writing is disabled by default (avoids dirtying the work tree on
# every session end). Enable explicitly with STORY_SESSION_LOG=1; even then, only
# write into an existing long-form tracking directory.
if [ "${STORY_SESSION_LOG:-0}" != "1" ]; then
  exit 0
fi

BOOK_DIR=$(discover_active_book)

# Only write into an existing tracking directory; never mkdir, which would silently
# upgrade a short-form project to the long-form structure.
if [ -n "$BOOK_DIR" ] && [ -d "$BOOK_DIR/tracking" ]; then
  echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] session ended" >> "$BOOK_DIR/tracking/session-log.txt"
fi
