Migration Checklist — Retarget to PS-Insider Hardened

Summary of changes applied:
- Renamed plan title and created new file: `PLAN FOR OASM - PS-INSIDER HARDENED + RUST + PY03.txt` (reworded goals and phases).
- Updated `PLAN FOR OASM  WPSHELL PS2026  RUST  PY03 COMBO.txt` content and added the new plan file.
- Replaced references to WPShell/PS2026 in docs with PS-Insider/ps_insider where appropriate.
  - Files updated: `deepresearchresults.txt`, `===================================.txt`, `OASM CORE  WPSHELL PS2026  RUST  PY03 IN HDF5.txt`, `PLAN FOR OASM  WPSHELL PS2026  RUST  PY03 COMBO.txt`, `DOCKER_BLUEPRINT.md`, `LINEAGE REVERT MODEL FOR ENHANCEMENTS.txt`, `PY03 PATTERN-TESTING ENGINE (SHORT)expand.txt`.
- Updated OASM description to be an inner-core compiler module that emits immutable, signed templates/OPBs and enforces ODLS rules.
- Replaced template paths `/core/wpshell` and `/core/ps2026` with `/core/ps_insider` and updated related examples and profiles.

Remaining tasks / recommended follow-ups:
1. Add a dedicated "Threat Model & Compliance" section to the new plan with measurable acceptance criteria (examples below). (RECOMMENDED)
2. Add CI checks and gating:
   - WDAC policy validation job (Windows runner)
   - Signature verification job for OPBs/templates
   - Py03 fuzz/coverage threshold job
   - Acceptance test job verifying no direct WinAPI calls from scripts
3. Update HDF5 schemas and tests to reflect `/core/ps_insider` group and validate existing templates' metadata and signatures.
4. Update any code that references `/core/wpshell` or `/core/ps2026` (search repository for dataset/group usage in code or tests). (ACTIONABLE)
5. Add documentation on OASM compiler outputs, signing process, and how Rust verifies templates before execution.
6. Consider automated migration script to rename HDF5 groups and update staged compositions if necessary.
7. Create a PR with these doc changes and include test updates, migration notes, and a short summary for reviewers.

Suggested Acceptance Criteria (examples):
- WDAC policy applied and validated by CI (policy test passes on Windows runner).
- All OPBs/templates are signed and pass signature verification checks in CI.
- Py03 fuzzing achieves minimum coverage threshold and no critical crashes.
- No direct WinAPI calls allowed from script-level code as verified by static analysis and runtime tests.
- Revert/rollback flow successfully restores known-good staging in an automated test.

Next actions I can take for you:
- Prepare the PR and include the migration checklist, diffs, and test updates.
- Add the Threat Model & Compliance section to the new plan file and propose CI job specs.
- Search for code references to `/core/wpshell` or `/core/ps2026` and propose code changes.

Which of the 'Next actions' would you like me to do now? (PR / Add Threat Model & CI / Search code refs)