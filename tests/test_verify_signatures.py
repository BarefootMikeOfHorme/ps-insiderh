import os
import shutil
import subprocess
import tempfile
import sys

import pytest

GPG = shutil.which('gpg')

pytestmark = pytest.mark.skipif(GPG is None, reason='gpg not available')


def generate_test_key(gpg_home):
    # Create a minimal GPG key for testing using batch mode
    batch = f"""
    Key-Type: RSA
    Key-Length: 2048
    Name-Real: Test Signer
    Name-Comment: CI Test Key
    Name-Email: test-signer@example.invalid
    Expire-Date: 0
    %no-protection
    %commit
    """
    cfg = os.path.join(gpg_home, 'batch')
    with open(cfg, 'w') as f:
        f.write(batch)
    env = os.environ.copy()
    env['GNUPGHOME'] = gpg_home
    subprocess.check_call(['gpg', '--batch', '--generate-key', cfg], env=env)


def export_pubkey(gpg_home, outpath):
    env = os.environ.copy()
    env['GNUPGHOME'] = gpg_home
    with open(outpath, 'wb') as f:
        subprocess.check_call(['gpg', '--armor', '--export', 'test-signer@example.invalid'], stdout=f, env=env)


def sign_file(gpg_home, filepath):
    env = os.environ.copy()
    env['GNUPGHOME'] = gpg_home
    subprocess.check_call(['gpg', '--detach-sign', '--armor', filepath], env=env)


def test_verify_signed_artifact(tmp_path):
    gpg_home = tmp_path / 'gpg'
    gpg_home.mkdir()

    generate_test_key(str(gpg_home))

    # create sample artifact
    artifact = tmp_path / 'sample.opb'
    artifact.write_bytes(b'test artifact')

    # sign artifact
    sign_file(str(gpg_home), str(artifact))

    # export public key to separate file
    pub = tmp_path / 'signer.pub'
    export_pubkey(str(gpg_home), str(pub))

    # Now run verification script with SIGNER_PUBKEY pointing to exported key
    env = os.environ.copy()
    env['SIGNER_PUBKEY'] = str(pub)
    env['GITHUB_WORKSPACE'] = str(tmp_path)

    script = os.path.join(os.getcwd(), 'ci', 'verify_signatures.sh')
    subprocess.check_call(['bash', script], env=env)
