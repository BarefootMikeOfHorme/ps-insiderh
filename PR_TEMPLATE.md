PR Title: Retarget plan to PS-Insider Hardened; make OASM an inner-core compiler module; update docs and paths

Summary:
- Retargeted the project plan and documentation from WPShell/PS2026 to PS-Insider Hardened runtime.
- Updated OASM wording to be an inner-core compiler module that emits immutable, signed templates/OPBs and enforces ODLS policies.
- Replaced template paths `/core/wpshell` and `/core/ps2026` with `/core/ps_insider` and updated examples, staging profiles, and doc references.
- Added a migration checklist and replacements summary for reviewers.

Files changed (high-level):
- `PLAN FOR OASM - PS-INSIDER HARDENED + RUST + PY03.txt` (new)
- `PLAN FOR OASM  WPSHELL PS2026  RUST  PY03 COMBO.txt` (updated)
- `deepresearchresults.txt` (updated)
- `===================================.txt` (updated)
- `OASM CORE  WPSHELL PS2026  RUST  PY03 IN HDF5.txt` (updated)
- `DOCKER_BLUEPRINT.md` (updated)
- `LINEAGE REVERT MODEL FOR ENHANCEMENTS.txt` (updated)
- `PY03 PATTERN-TESTING ENGINE (SHORT)expand.txt` (updated)
- `MIGRATION_CHECKLIST.md` (new)
- `REPLACEMENTS_APPLIED.txt` (new)

Testing & Verification Requirements:
- CI should run WDAC and signature verification checks on Windows runners
- Ensure all amended docs build (if using doc tooling)
- Validate no remaining references to WPShell/PS2026 in docs/code unless explicitly left as "legacy" notes

Suggested branch name: feat/ps-insider-hardened-retarget

PR Checklist:
- [ ] Add Threat Model & Compliance section to the new plan
- [ ] Add CI job definitions or stubs for WDAC/signature verification
- [ ] Update HDF5 tests to include `/core/ps_insider` group checks
- [ ] Run repo-wide search for any remaining WPShell/PS2026 references and assess code impact

How to apply locally (suggested):
1. Create branch: `git checkout -b feat/ps-insider-hardened-retarget`
2. Apply changes (manual or via patch created from this PR)
3. Run docs build/tests
4. Push to remote and open a PR with the description above

If you'd like, I can prepare a downloadable patch file (unified diff) containing all of these edits for easy application to a git repo—tell me if you want that and where to upload it (or I can attach it to this workspace).