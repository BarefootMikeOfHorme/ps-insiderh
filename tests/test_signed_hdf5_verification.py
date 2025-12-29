import os
import shutil
import subprocess
import tempfile
import sys

import pytest

try:
    import h5py
except Exception:
    h5py = None

GPG = shutil.which('gpg')

pytestmark = pytest.mark.skipif(h5py is None or GPG is None, reason='h5py or gpg not available')


def generate_signed_hdf5_and_verify(tmp_path):
    # create hdf5 file with /core/ps_insider/templates/template1 and signature attr
    path = tmp_path / 'signed_sample.hdf5'
    with h5py.File(path, 'w') as f:
        core = f.create_group('/core')
        ps = core.create_group('ps_insider')
        templates = ps.create_group('templates')
        t = templates.create_group('template1')
        t.attrs['signature'] = 'test-signature-metadata'

    # create gpg key
    gpg_home = tmp_path / 'gpg'
    gpg_home.mkdir()

    batch = """
Key-Type: RSA
Key-Length: 2048
Name-Real: HDF5 Signer
Name-Email: hdf5-signer@example.invalid
Expire-Date: 0
%no-protection
%commit
"""
    batch_file = tmp_path / 'batch'
    batch_file.write_text(batch)
    env = os.environ.copy()
    env['GNUPGHOME'] = str(gpg_home)
    subprocess.check_call(['gpg', '--batch', '--generate-key', str(batch_file)], env=env)

    # export public key
    pub = tmp_path / 'hdf5_signer.pub'
    with open(pub, 'wb') as f:
        subprocess.check_call(['gpg', '--armor', '--export', 'hdf5-signer@example.invalid'], stdout=f, env=env)

    # sign the file
    subprocess.check_call(['gpg', '--detach-sign', '--armor', str(path)], env=env)

    # Run verification script with signer public key and workspace set to tmp_path
    ver_env = os.environ.copy()
    ver_env['SIGNER_PUBKEY'] = str(pub)
    ver_env['GITHUB_WORKSPACE'] = str(tmp_path)
    script = os.path.join(os.getcwd(), 'ci', 'verify_signatures.sh')
    subprocess.check_call(['bash', script], env=ver_env)


def test_signed_hdf5_verification(tmp_path):
    generate_signed_hdf5_and_verify(tmp_path)
