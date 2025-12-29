#!/usr/bin/env bash
set -euo pipefail
python3 tests/helpers/generate_and_sign_fixture.py
echo "Generated fixtures in tests/fixtures/"