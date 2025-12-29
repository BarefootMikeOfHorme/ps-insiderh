import os
import subprocess
import tempfile
from pathlib import Path


def create_hdf5_fixture(h5_path: str):
    import h5py
    Path(h5_path).parent.mkdir(parents=True, exist_ok=True)
    with h5py.File(h5_path, "w") as f:
        f.create_dataset('/core/ps_insider', data=[42])
        ds = f['/core/ps_insider']
        ds.attrs['template_id'] = 'canon-v1'


def _run_gpg(gpg_home: str, args, input_data=None):
    env = os.environ.copy()
    env['GNUPGHOME'] = gpg_home
    cmd = ['gpg', '--batch', '--yes'] + args
    proc = subprocess.run(cmd, input=input_data, capture_output=True)
    return proc


def generate_key_and_sign(file_path: str, sig_out: str, pubkey_out: str, name_email: str = 'test@example.com'):
    """Generate a temporary GPG keypair in a new GNUPGHOME, sign the file (detached), export public key, and write both outputs."""
    gpg_home = tempfile.mkdtemp(prefix='gpghome_')
    # Write key params
    key_params = f"""Key-Type: RSA
Key-Length: 2048
Name-Real: PS Insider Test
Name-Comment: testkey
Name-Email: {name_email}
Expire-Date: 0
%commit
"""
    # generate key
    proc = _run_gpg(gpg_home, ['--gen-key'], input_data=key_params.encode())
    if proc.returncode != 0:
        raise RuntimeError(f"gpg gen-key failed: {proc.stderr.decode()}")

    # Detached sign
    proc = _run_gpg(gpg_home, ['--output', sig_out, '--detach-sign', file_path])
    if proc.returncode != 0:
        raise RuntimeError(f"gpg sign failed: {proc.stderr.decode()}")

    # Export pubkey
    proc = _run_gpg(gpg_home, ['--armor', '--export', name_email])
    if proc.returncode != 0:
        raise RuntimeError(f"gpg export failed: {proc.stderr.decode()}")
    with open(pubkey_out, 'wb') as f:
        f.write(proc.stdout)

    return gpg_home
