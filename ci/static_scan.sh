#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
PATTERNS=(
  "CreateProcess"
  "LoadLibrary"
  "GetProcAddress"
  "ctypes\.windll"
  "Add-Type -TypeDefinition"
  "\[DllImport"
  "PInvoke"
  "GetModuleHandle"
)

echo "Scanning for direct WinAPI or unsafe patterns..."
FOUND=0
for p in "${PATTERNS[@]}"; do
  echo "Searching for pattern: $p"
  matches=$(grep -RIn --exclude-dir=.git --exclude='*.md' --exclude='*.lock' -e "$p" . || true)
  if [ -n "$matches" ]; then
    echo "--- Matches for [$p] ---"
    echo "$matches"
    FOUND=1
  fi
done

if [ "$FOUND" -eq 1 ]; then
  echo "Potential direct WinAPI/unsafe usage found. Fail the job to require review."
  exit 1
fi

echo "Static scan completed: no direct WinAPI/unsafe patterns found"
exit 0