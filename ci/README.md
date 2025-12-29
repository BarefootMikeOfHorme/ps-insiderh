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
