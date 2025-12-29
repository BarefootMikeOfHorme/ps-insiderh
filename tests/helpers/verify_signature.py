import os
import subprocess
import tempfile
from pathlib import Path


def verify_detached_signature(file_path: str, sig_path: str, pubkey_path: str) -> bool:
    gpg_home = tempfile.mkdtemp(prefix='gpghome_verify_')
    env = os.environ.copy()
    env['GNUPGHOME'] = gpg_home

    # Import public key
    proc = subprocess.run(['gpg', '--batch', '--yes', '--import', pubkey_path], env=env, capture_output=True)
    if proc.returncode != 0:
        return False

    # Verify signature
    proc = subprocess.run(['gpg', '--verify', sig_path, file_path], env=env, capture_output=True)
    return proc.returncode == 0
