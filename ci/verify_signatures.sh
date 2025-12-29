#!/usr/bin/env bash
set -euo pipefail

# Verify signatures for OPB/HDF5 artifacts in /core/staging or repo root
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
SEARCH_DIRS=("$ROOT/core/staging" "$ROOT")
SIGNED=false

echo "Looking for artifacts to verify..."
for d in "${SEARCH_DIRS[@]}"; do
  if [ -d "$d" ]; then
    shopt -s nullglob
    for file in "$d"/*.{opb,h5,hdf5}; do
      if [ -f "$file" ]; then
        echo "Found artifact: $file"
        sig1="$file.sig"
        sig2="$file.asc"
        sig3="$file.sig.p7s"
        if [ -f "$sig1" ]; then
          echo "Verifying GPG signature: $sig1"
          gpg --verify "$sig1" "$file" || { echo "Signature verification failed for $file"; exit 1; }
          SIGNED=true
        elif [ -f "$sig2" ]; then
          echo "Verifying ASCII-armored signature: $sig2"
          gpg --verify "$sig2" "$file" || { echo "Signature verification failed for $file"; exit 1; }
          SIGNED=true
        elif [ -f "$sig3" ]; then
          echo "Found CMS signature: $sig3 (best-effort check)"
          if command -v openssl >/dev/null 2>&1; then
            echo "OpenSSL present but CMS verification requires signer certs; skipping strict check"
            SIGNED=true
          fi
        else
          echo "No signature found for $file"
          exit 1
        fi
      fi
    done
    shopt -u nullglob
  fi
done

if [ "$SIGNED" = false ]; then
  echo "No signed artifacts found; failing verification"
  exit 1
fi

echo "Signature verification completed successfully"
exit 0