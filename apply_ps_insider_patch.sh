#!/usr/bin/env bash
# POSIX patch script to apply PS-Insider retargeting replacements (sed-based)
set -euo pipefail

apply_replacement() {
  local file="$1"
  local old="$2"
  local new="$3"
  if [ -f "$file" ]; then
    echo "Updating $file"
    sed -i.bak "s#${old}#${new}#g" "$file"
  else
    echo "Skipping missing file: $file"
  fi
}

apply_replacement "deepresearchresults.txt" "Feasibility Analysis of Integrating OASM, WPShell/PS2026, Rust, and PyO3" "Feasibility Analysis of Integrating OASM, PS-Insider Hardened, Rust, and PyO3"
apply_replacement "deepresearchresults.txt" "WPShell/PS2026: Minimal Windows Scripting Cores" "PS-Insider: Hardened PowerShell Insider Runtime"
apply_replacement "deepresearchresults.txt" "WPShell (WP-CLI shell) and PS2026 (a modern PowerShell variant) are powerful, scriptable shells for Windows and WordPress environments. Reducing these shells to minimal cores—retaining only essential command execution and scripting capabilities—can be achieved by stripping out non-essential modules and exposing only the necessary APIs. This approach is feasible, as both shells are designed for extensibility and can be wrapped or invoked programmatically, especially when orchestrated by a higher-level language like Rust." "PS-Insider (the hardened PowerShell Insider runtime) is the target runtime—reduced and hardened to retain only essential, signed execution capabilities. Reducing the runtime to a minimal, constrained core can be achieved by disabling non-essential modules, enforcing constrained language and code-signing policies, and exposing only the necessary, Rust-mediated interfaces."
apply_replacement "===================================.txt" "A — OASM CORE + CUSTOM WPSHELL/PS2026 + RUST + PY03 IN HDF5" "A — OASM CORE + PS-INSIDER HARDENED + RUST + PY03 IN HDF5"
apply_replacement "===================================.txt" "- custom WPShell integration" "- PS-Insider (hardened) integration"
apply_replacement "OASM CORE  WPSHELL PS2026  RUST  PY03 IN HDF5.txt" "OASM CORE + WPSHELL/PS2026 + RUST + PY03 IN HDF5" "OASM CORE + PS-INSIDER HARDENED + RUST + PY03 IN HDF5"
apply_replacement "OASM CORE  WPSHELL PS2026  RUST  PY03 IN HDF5.txt" "/core\n  /wpshell\n  /ps2026" "/core\n  /ps_insider"
apply_replacement "PY03 PATTERN-TESTING ENGINE (SHORT)expand.txt" "Interact with shell (WPShell/PS) to:" "Interact with shell (PS-Insider) to:"

echo "Patch script finished. Review .bak files for backups."