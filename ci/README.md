CI: PS-Insider Security Checks — Notes

This folder contains CI job stubs for PS-Insider security checks. Implement the following scripts and wire them into the workflow `./.github/workflows/ps_insider_security_checks.yml`.

1) WDAC validation script (Windows runner)
   - Validate WDAC policy against known acceptance profiles
   - Run small workload/tests to ensure policy does not block required, signed OPBs
   - Should exit non-zero on policy failures

2) Signature verification for OPBs/templates
   - Script should locate OPB/HDF5 artifacts in `/core/staging` and verify signatures and reproducible hashes
   - Fail if artifacts are unsigned or hashes don't match published metadata

3) Py03 fuzz harness
   - Use hypothesis or a tailored fuzz harness to stress test templates and orchestrator interactions
   - Produce a coverage and crash report
   - Fail CI on high/critical crashes or if coverage is below threshold

4) Static analysis/scan for direct WinAPI use
   - Provide a script to scan Python/Rust/script artifacts for patterns suggesting direct unmanaged WinAPI calls
   - Fail or warn CI depending on severity

5) Integration with reporting
   - On CI failures, collect logs and append to HDF5 audit logs or store artifacts for triage


Implemented scripts (initial):
- `ci/wdac_validate.ps1` — WDAC policy structural validator (Windows runner)
- `ci/verify_signatures.sh` — signature verification for OPB/HDF5 artifacts (GPG/OpenSSL best-effort)
- `ci/static_scan.sh` — grep-based static scan for direct WinAPI/unsafe patterns (fails on matches)
- `tests/test_fuzz.py` — Hypothesis-based fuzz test for CBOR parsing
- `ci/requirements.txt` — Python dependencies for fuzzing/coverage

Workflow changes:
- `.github/workflows/ps_insider_security_checks.yml` now runs the above scripts.

Notes & Next improvements:
- WDAC validation is best-effort in CI: it verifies presence and XML structure and will attempt signature checks if certutil available. For full enforcement tests, we recommend an on-host validation step with a signed policy and a restricted test VM.
- Signature verification assumes GPG-signed artifacts or CMS signatures; add signer cert import and trust chain verification as needed.
- Py03 fuzzing uses Hypothesis to drive CBOR parsing; expand tests to use project-specific parsers and templates for deeper coverage.
- Static scan uses heuristic grep patterns; consider integrating a more expressive analyzer (semgrep or custom AST checks) for fewer false positives.
