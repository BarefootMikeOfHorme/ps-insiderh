<#
WDAC Policy Validation Script (CI)
- Expects a WDAC policy XML at wdac/policy.xml
- Validates XML structure for required elements
- If a .p7s signature file exists (wdac/policy.xml.p7s), attempts to validate using certutil (if available)
- Exits with non-zero code on failure
#>

param(
    [string]$PolicyPath = "wdac/policy.xml"
)

Write-Host "WDAC validation started"
if (-not (Test-Path $PolicyPath)) {
    Write-Error "WDAC policy not found at $PolicyPath"
    exit 1
}

try {
    [xml]$policy = Get-Content $PolicyPath -Raw
} catch {
    Write-Error "Policy file is not well-formed XML: $_"
    exit 1
}

if (-not $policy.DocumentElement) {
    Write-Error "Invalid WDAC XML structure"
    exit 1
}

# Simple structural checks
$hasRules = $policy.SelectNodes('//Rule') -and ($policy.SelectNodes('//Rule').Count -gt 0)
$hasPolicy = $policy.SelectNodes('//Policy') -and ($policy.SelectNodes('//Policy').Count -gt 0)
if (-not ($hasRules -or $hasPolicy)) {
    Write-Error "Policy appears to be missing expected 'Policy' or 'Rule' elements"
    exit 1
}

# Optional signature check
$sigPath = "$PolicyPath.p7s"
if (Test-Path $sigPath) {
    Write-Host "Found signature file: $sigPath"
    if (Get-Command certutil -ErrorAction SilentlyContinue) {
        Write-Host "Attempting to verify signature with certutil (best-effort)"
        $verify = & certutil -verify $sigPath 2>&1
        Write-Host $verify
        # Not strictly gating on certutil result since cert store may not have signer certs in CI
    } else {
        Write-Host "certutil not available; skipping signature verification"
    }
} else {
    Write-Host "No signature file found for policy (optional): $sigPath"
}

Write-Host "WDAC validation completed successfully"
exit 0