This folder contains test fixtures for HDF5 signature verification.

Files:
- canonical_unsigned.h5 — canonical HDF5 template (unsigned)
- canonical_signed.h5.sig — detached GPG signature of the canonical HDF5
- signer_pubkey.asc — the public key to verify the detached signature

These fixtures are intended for CI and local testing. The private key used to sign the canonical HDF5 is not included; instead, the detached signature and public key are provided so tests can verify the signed artifact's authenticity.

To generate (or re-generate) fixtures locally:
- Linux/macOS: `./scripts/generate-fixtures.sh`
- Windows PowerShell: `.\scripts\generate-fixtures.ps1`

Note: generation requires Python (3.8+) and GPG (`gpg` in PATH). The devcontainer includes these to facilitate reproducible local dev.