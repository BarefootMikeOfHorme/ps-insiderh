from pathlib import Path
import shutil
import tempfile

from tests.helpers.verify_signature import verify_detached_signature

try:
    from tests.helpers.generate_and_sign_fixture import build_fixture
except Exception:
    build_fixture = None


def test_bad_signature_detection(tmp_path):
    fixtures_dir = Path('tests/fixtures')
    h5 = fixtures_dir / 'canonical_unsigned.h5'
    sig = fixtures_dir / 'canonical_unsigned.h5.sig'
    pub = fixtures_dir / 'signer_pubkey.asc'

    if not (h5.exists() and sig.exists() and pub.exists()):
        if build_fixture is None:
            # Can't proceed without gpg/python helper available
            return
        h5, sig, pub = build_fixture()

    # Valid case first
    assert verify_detached_signature(str(h5), str(sig), str(pub))

    # Tamper with the signature file
    with open(sig, 'rb') as f:
        data = bytearray(f.read())
    # Flip a byte
    data[10] = (data[10] + 1) % 256
    tampered = tmp_path / 'tampered.sig'
    with open(tampered, 'wb') as f:
        f.write(data)

    assert not verify_detached_signature(str(h5), str(tampered), str(pub))


def test_wrong_pubkey_detection(tmp_path):
    fixtures_dir = Path('tests/fixtures')
    h5 = fixtures_dir / 'canonical_unsigned.h5'
    sig = fixtures_dir / 'canonical_unsigned.h5.sig'
    pub = fixtures_dir / 'signer_pubkey.asc'

    if not (h5.exists() and sig.exists() and pub.exists()):
        if build_fixture is None:
            return
        h5, sig, pub = build_fixture()

    # Generate a different keypair and export pubkey
    import tempfile, subprocess, os
    gnupg = tempfile.mkdtemp(prefix='gpghome_other_')
    env = os.environ.copy()
    env['GNUPGHOME'] = gnupg
    batch = b"""Key-Type: RSA
Key-Length: 2048
Name-Real: Other Test
Name-Email: other@example.invalid
Expire-Date: 0
%no-protection
%commit
"""
    subprocess.check_call(['gpg', '--batch', '--generate-key'], input=batch, env=env)
    other_pub = tmp_path / 'other.asc'
    with open(other_pub, 'wb') as f:
        subprocess.check_call(['gpg', '--armor', '--export', 'other@example.invalid'], stdout=f, env=env)

    assert not verify_detached_signature(str(h5), str(sig), str(other_pub))
