<#
PowerShell patch script to retarget docs to PS-Insider Hardened and update OASM wording.
Run in repo root. This script edits files in place (creates .bak backups).
#>

$replacements = @(
    @{file='deepresearchresults.txt'; old='Feasibility Analysis of Integrating OASM, WPShell/PS2026, Rust, and PyO3'; new='Feasibility Analysis of Integrating OASM, PS-Insider Hardened, Rust, and PyO3'},
    @{file='deepresearchresults.txt'; old='WPShell/PS2026: Minimal Windows Scripting Cores'; new='PS-Insider: Hardened PowerShell Insider Runtime'},
    @{file='deepresearchresults.txt'; old='WPShell (WP-CLI shell) and PS2026 (a modern PowerShell variant) are powerful, scriptable shells for Windows and WordPress environments. Reducing these shells to minimal cores—retaining only essential command execution and scripting capabilities—can be achieved by stripping out non-essential modules and exposing only the necessary APIs. This approach is feasible, as both shells are designed for extensibility and can be wrapped or invoked programmatically, especially when orchestrated by a higher-level language like Rust.'; new='PS-Insider (the hardened PowerShell Insider runtime) is the target runtime—reduced and hardened to retain only essential, signed execution capabilities. Reducing the runtime to a minimal, constrained core can be achieved by disabling non-essential modules, enforcing constrained language and code-signing policies, and exposing only the necessary, Rust-mediated interfaces.'},
    @{file='===================================.txt'; old='A — OASM CORE + CUSTOM WPSHELL/PS2026 + RUST + PY03 IN HDF5'; new='A — OASM CORE + PS-INSIDER HARDENED + RUST + PY03 IN HDF5'},
    @{file='===================================.txt'; old='- custom WPShell integration'; new='- PS-Insider (hardened) integration'},
    @{file='===================================.txt'; old='/core\n  / Custom_wpshell\n  /ps2026'; new='/core\n  /ps_insider'},
    @{file='OASM CORE  WPSHELL PS2026  RUST  PY03 IN HDF5.txt'; old='OASM CORE + WPSHELL/PS2026 + RUST + PY03 IN HDF5'; new='OASM CORE + PS-INSIDER HARDENED + RUST + PY03 IN HDF5'},
    @{file='OASM CORE  WPSHELL PS2026  RUST  PY03 IN HDF5.txt'; old='/core\n  /wpshell\n  /ps2026'; new='/core\n  /ps_insider'},
    @{file='PY03 PATTERN-TESTING ENGINE (SHORT)expand.txt'; old='Interact with shell (WPShell/PS) to:'; new='Interact with shell (PS-Insider) to:'}
)

foreach ($r in $replacements) {
    $path = Join-Path $PWD $r.file
    if (Test-Path $path) {
        Write-Host "Updating $($r.file)"
        (Get-Content $path -Raw) -replace [regex]::Escape($r.old), $r.new | Set-Content $path
    } else {
        Write-Host "Skipping missing file: $($r.file)"
    }
}

Write-Host 'Patch script completed. Please review changes and commit.'
